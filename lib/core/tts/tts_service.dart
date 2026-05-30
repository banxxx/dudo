import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin singleton wrapping `flutter_tts` and a background `AudioHandler` so
/// the system media controls can drive playback while the screen is locked.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  TtsAudioHandler? _handler;
  bool _ready = false;

  TtsAudioHandler? get handler => _handler;
  FlutterTts get raw => _tts;
  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;

    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

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

  Future<void> speakAll(List<String> paragraphs) async {
    _handler?.loadQueue(paragraphs);
    await _handler?.play();
  }

  Future<void> stop() async => _handler?.stop();
}

/// Background-capable [BaseAudioHandler] that drives [FlutterTts] sentence by
/// sentence. Real implementation should bridge boundaries between TTS speak
/// callbacks and AudioService state.
class TtsAudioHandler extends BaseAudioHandler with SeekHandler {
  TtsAudioHandler(this._tts) {
    _tts.setCompletionHandler(_onSentenceDone);
  }

  final FlutterTts _tts;
  final List<String> _queue = [];
  int _cursor = 0;

  void loadQueue(List<String> items) {
    _queue
      ..clear()
      ..addAll(items);
    _cursor = 0;
  }

  @override
  Future<void> play() async {
    if (_cursor >= _queue.length) return;
    playbackState.add(
      playbackState.value.copyWith(
        playing: true,
        controls: [MediaControl.pause, MediaControl.skipToNext],
        processingState: AudioProcessingState.ready,
      ),
    );
    await _tts.speak(_queue[_cursor]);
  }

  @override
  Future<void> pause() async {
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
    await _tts.stop();
    _cursor = 0;
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
      await play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_cursor > 0) {
      _cursor--;
      await play();
    }
  }

  void _onSentenceDone() {
    _cursor++;
    if (_cursor < _queue.length) {
      _tts.speak(_queue[_cursor]);
    } else {
      stop();
    }
  }
}
