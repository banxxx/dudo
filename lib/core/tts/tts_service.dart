import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import 'tts_models.dart';

/// Thin singleton wrapping `flutter_tts` and a background `AudioHandler` so
/// the system media controls can drive playback while the screen is locked.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  /// Created on first use: constructing it needs the Flutter binding, and the
  /// online engine only needs the handler.
  FlutterTts? _ttsInstance;
  TtsAudioHandler? _handler;
  bool _ready = false;
  List<TtsVoice>? _voices;

  FlutterTts get _tts => _ttsInstance ??= FlutterTts();

  static const _settingsChannel = MethodChannel('dudo.system/settings');
  bool _notificationPermissionAsked = false;

  /// Android 13+ hides the media notification until `POST_NOTIFICATIONS` is
  /// granted, and the lock-screen controls come with that notification. Asked
  /// lazily on first playback instead of at launch, so the prompt has context.
  Future<void> ensureNotificationPermission() async {
    if (_notificationPermissionAsked) return;
    _notificationPermissionAsked = true;
    try {
      await _settingsChannel.invokeMethod<bool>('requestNotificationPermission');
    } catch (_) {
      // No platform channel (unit tests, desktop) or a denied prompt: playback
      // still works, it just has no media notification.
    }
  }

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
    String? title,
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
    unawaited(ensureNotificationPermission());
    handler.loadQueue(segments, startIndex: startIndex, title: title);
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

  /// The HTTP engine plays files instead of speaking; sharing this handler is
  /// what keeps that playback in the foreground service, with the same
  /// notification and lock-screen controls as the system engine.
  AudioPlayer? _onlinePlayer;
  bool _onlineActive = false;

  /// Owned by the online player's queue loop rather than the raw player: the
  /// player reports `completed` between two paragraphs and a fresh `playing`
  /// only once the next file is decoded, which would make the notification
  /// flip to a play button on every paragraph.
  bool _onlinePlaying = false;

  /// Installed by the online player while it owns playback: the lock-screen
  /// buttons must go through its pause/resume logic, because pausing the raw
  /// player looks like "segment finished" to its queue loop.
  Future<void> Function()? onOnlinePause;
  Future<void> Function()? onOnlineResume;
  Future<void> Function()? onOnlineSkipToNext;
  Future<void> Function()? onOnlineSkipToPrevious;

  ValueChanged<int>? onSegmentStarted;
  VoidCallback? onCompleted;

  AudioPlayer get onlinePlayer => _onlinePlayer ??= _createOnlinePlayer();

  AudioPlayer _createOnlinePlayer() {
    final player = AudioPlayer();
    player.playerStateStream.listen(_publishOnlineState);
    player.positionStream.listen(_publishOnlinePosition);
    return player;
  }

  /// Marks online playback as the current source of this handler.
  void beginOnlinePlayback() {
    _onlineActive = true;
    _onlinePlaying = true;
    _publishOnline();
  }

  /// Stops online playback and clears the notification state.
  Future<void> stopOnlinePlayback() async {
    _onlineActive = false;
    _onlinePlaying = false;
    onOnlinePause = null;
    onOnlineResume = null;
    onOnlineSkipToNext = null;
    onOnlineSkipToPrevious = null;
    await _onlinePlayer?.stop();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  /// Lets the online player report its own pause/resume (the panel button does
  /// not go through [play]/[pause] here), so the notification stays in sync.
  void setOnlinePlaying(bool playing) {
    if (!_onlineActive || _onlinePlaying == playing) return;
    _onlinePlaying = playing;
    _publishOnline();
  }

  void _publishOnlineState(PlayerState state) {
    if (!_onlineActive) return;
    _publishOnline(processingState: _onlineProcessingState(state.processingState));
  }

  /// Mirrors the online queue into the notification/lock screen. `idle` is
  /// never published here: audio_service treats it as "playback finished" and
  /// would tear the session down while the next paragraph is being fetched.
  void _publishOnline({AudioProcessingState? processingState}) {
    if (!_onlineActive) return;
    final state = processingState ??
        _onlineProcessingState(_onlinePlayer?.processingState);
    playbackState.add(
      playbackState.value.copyWith(
        playing: _onlinePlaying,
        processingState: state,
        controls: [
          _onlinePlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
      ),
    );
  }

  AudioProcessingState _onlineProcessingState(ProcessingState? state) =>
      switch (state) {
        null || ProcessingState.idle => AudioProcessingState.loading,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        // A finished file is immediately followed by the next paragraph, so
        // the queue as a whole is still "ready".
        ProcessingState.ready || ProcessingState.completed =>
          AudioProcessingState.ready,
      };

  void _publishOnlinePosition(Duration position) {
    if (!_onlineActive) return;
    final duration = _onlinePlayer?.duration;
    playbackState.add(
      playbackState.value.copyWith(
        updatePosition: position,
        bufferedPosition: duration ?? Duration.zero,
      ),
    );
  }

  /// 0..1 progress inside the segment currently being spoken.
  ValueChanged<double>? onProgress;

  int get cursor => _cursor;

  void loadQueue(List<String> items, {int startIndex = 0, String? title}) {
    _queue
      ..clear()
      ..addAll(items);
    _cursor = startIndex.clamp(0, _queue.isEmpty ? 0 : _queue.length - 1);
    setMediaTitle(title);
  }

  /// The media notification needs a media item to show something more useful
  /// than the app name.
  void setMediaTitle(String? title) {
    mediaItem.add(
      MediaItem(
        id: 'dudo-read-aloud',
        title: (title == null || title.trim().isEmpty) ? '朗读' : title,
        artist: 'dudo',
      ),
    );
  }

  @override
  Future<void> play() async {
    if (_onlineActive) {
      setOnlinePlaying(true);
      final resume = onOnlineResume;
      if (resume != null) {
        await resume();
      } else {
        await _onlinePlayer?.play();
      }
      return;
    }
    if (_queue.isEmpty || _cursor >= _queue.length) return;
    _active = true;
    await _speakCurrent();
  }

  @override
  Future<void> pause() async {
    if (_onlineActive) {
      setOnlinePlaying(false);
      final pause = onOnlinePause;
      if (pause != null) {
        await pause();
      } else {
        await _onlinePlayer?.pause();
      }
      return;
    }
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
    if (_onlineActive) {
      await stopOnlinePlayback();
      return;
    }
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
    if (_onlineActive) {
      await onOnlineSkipToNext?.call();
      return;
    }
    if (_cursor + 1 < _queue.length) {
      _cursor++;
      await _speakCurrent();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_onlineActive) {
      await onOnlineSkipToPrevious?.call();
      return;
    }
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
