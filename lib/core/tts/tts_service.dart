import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_models.dart';

/// Thin singleton wrapping `flutter_tts` and a background `AudioHandler` so
/// the system media controls can drive playback while the screen is locked.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  TtsAudioHandler? _handler;
  bool _ready = false;
  List<TtsVoice>? _voices;

  TtsAudioHandler? get handler => _handler;
  FlutterTts get raw => _tts;
  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;

    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(false);

    _handler = await AudioService.init(
      builder: () => TtsAudioHandler(_tts),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.banxxx.dudo.audio',
        androidNotificationChannelName: 'dudo TTS',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

    _ready = true;
  }

  /// Applies the persisted read-aloud settings to the platform engine.
  Future<void> applyConfig(TtsConfig config) async {
    await _tts.setLanguage(config.language);
    await _tts.setSpeechRate(config.rate);
    await _tts.setPitch(config.pitch);
    await _tts.setVolume(config.volume);

    final voiceName = config.voiceName;
    if (voiceName == null) return;
    try {
      await _tts.setVoice({
        'name': voiceName,
        'locale': config.voiceLocale ?? config.language,
      });
    } catch (error, stackTrace) {
      // The stored voice may no longer be installed (ROM update, engine
      // switch); keeping the default voice is better than failing playback.
      debugPrint(
          '[tts] failed to select voice $voiceName: $error\n$stackTrace');
    }
  }

  /// All voices the system engine currently exposes, Chinese ones first.
  Future<List<TtsVoice>> voices({bool forceRefresh = false}) async {
    final cached = _voices;
    if (cached != null && !forceRefresh) return cached;

    final raw = await _tts.getVoices;
    final parsed = <TtsVoice>[];
    if (raw is List) {
      for (final item in raw) {
        final voice = TtsVoice.tryParse(item);
        if (voice != null) parsed.add(voice);
      }
    }
    parsed.sort((a, b) {
      if (a.isChinese != b.isChinese) return a.isChinese ? -1 : 1;
      return a.locale.compareTo(b.locale);
    });
    // An empty answer usually means the platform engine is not connected yet;
    // caching it would hide every voice for the rest of the session.
    if (parsed.isNotEmpty) _voices = parsed;
    return parsed;
  }

  /// Starts speaking [segments] from [startIndex] and reports progress through
  /// the handler's callbacks.
  Future<void> playSegments(
    List<String> segments, {
    int startIndex = 0,
    ValueChanged<int>? onSegmentStarted,
    VoidCallback? onCompleted,
  }) async {
    final handler = _handler;
    if (handler == null) return;
    // Keep callbacks installed with [TtsAudioHandler] when the caller does not
    // pass new ones; overwriting them with null silently disables progress
    // reporting for the reader and the preview player.
    if (onSegmentStarted != null) handler.onSegmentStarted = onSegmentStarted;
    if (onCompleted != null) handler.onCompleted = onCompleted;
    handler.loadQueue(segments, startIndex: startIndex);
    await handler.play();
  }

  Future<void> pause() async => _handler?.pause();

  Future<void> resume() async => _handler?.play();

  Future<void> stop() async => _handler?.stop();

  Future<void> restartCurrent() async => _handler?.restartCurrent();
}

/// Background-capable [BaseAudioHandler] that drives [FlutterTts] segment by
/// segment and reports the currently spoken segment to the reader.
class TtsAudioHandler extends BaseAudioHandler with SeekHandler {
  TtsAudioHandler(this._tts) {
    _tts.setCompletionHandler(_onSegmentDone);
    _tts.setCancelHandler(_onCancelled);
    _tts.setErrorHandler(_onSpeechError);
    _tts.setProgressHandler(_onSpeechProgress);
  }

  final FlutterTts _tts;
  final List<String> _queue = [];
  int _cursor = 0;
  bool _active = false;

  ValueChanged<int>? onSegmentStarted;
  VoidCallback? onCompleted;

  /// 0..1 progress inside the segment currently being spoken.
  ValueChanged<double>? onProgress;

  int get cursor => _cursor;

  void loadQueue(List<String> items, {int startIndex = 0}) {
    _queue
      ..clear()
      ..addAll(items);
    _cursor = startIndex.clamp(0, _queue.isEmpty ? 0 : _queue.length - 1);
  }

  @override
  Future<void> play() async {
    if (_queue.isEmpty || _cursor >= _queue.length) return;
    _active = true;
    await _speakCurrent();
  }

  @override
  Future<void> pause() async {
    _active = false;
    await _tts.stop();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        controls: [MediaControl.play, MediaControl.skipToNext],
      ),
    );
  }

  @override
  Future<void> stop() async {
    _active = false;
    _cursor = 0;
    _queue.clear();
    await _tts.stop();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  @override
  Future<void> skipToNext() async {
    if (_cursor + 1 < _queue.length) {
      _cursor++;
      await _speakCurrent();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_cursor > 0) {
      _cursor--;
      await _speakCurrent();
    }
  }

  /// Re-reads the current segment, used when the user changes the speed.
  Future<void> restartCurrent() async {
    if (!_active || _queue.isEmpty) return;
    await _tts.stop();
    await _speakCurrent();
  }

  Future<void> _speakCurrent() async {
    if (!_active) return;
    if (_cursor >= _queue.length) {
      _finish();
      return;
    }
    onSegmentStarted?.call(_cursor);
    playbackState.add(
      playbackState.value.copyWith(
        playing: true,
        controls: [MediaControl.pause, MediaControl.skipToNext],
        processingState: AudioProcessingState.ready,
      ),
    );
    await _tts.speak(_queue[_cursor]);
  }

  /// Word level offsets from the platform engine; the first callback marks the
  /// moment sound actually starts, so the UI can leave its loading state.
  void _onSpeechProgress(
    String text,
    int startOffset,
    int endOffset,
    String word,
  ) {
    if (!_active || text.isEmpty) return;
    onProgress?.call((endOffset / text.length).clamp(0.0, 1.0));
  }

  void _onSegmentDone() {
    if (!_active) return;
    _cursor++;
    if (_cursor < _queue.length) {
      unawaited(_speakCurrent());
    } else {
      _finish();
    }
  }

  void _onCancelled() {
    // `stop()`/`pause()` cancel the current utterance; completion callbacks
    // must not advance the queue in that case.
  }

  void _onSpeechError(dynamic error) {
    if (!_active) return;
    // A single unspeakable segment (missing language data, engine error)
    // should not abort the whole chapter.
    debugPrint('[tts] segment $_cursor failed: $error');
    _cursor++;
    if (_cursor < _queue.length) {
      unawaited(_speakCurrent());
    } else {
      _finish();
    }
  }

  void _finish() {
    _active = false;
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.completed,
      ),
    );
    onCompleted?.call();
  }
}
