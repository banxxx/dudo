import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tts/tts_models.dart';
import '../../../../core/tts/tts_service.dart';
import '../domain/read_aloud_settings.dart';

/// The subset of the TTS engine the settings page and the reader need, so
/// widget tests can run without the platform plugin.
abstract interface class ReadAloudPlayer {
  Future<void> apply(ReadAloudSettings settings);

  Future<List<TtsVoice>> voices();

  /// Starts speaking the given chapter segments and reports progress.
  Future<void> play(List<String> segments, {int startIndex = 0});

  void bind({ValueChanged<int>? onSegmentStarted, VoidCallback? onCompleted});

  Future<void> pause();

  Future<void> stop();

  /// Re-reads the current segment, used when the speed changed mid-playback.
  Future<void> restartCurrent();

  /// Speaks a short sample with the given settings.
  Future<void> preview(ReadAloudSettings settings, String text);
}

class TtsReadAloudPlayer implements ReadAloudPlayer {
  const TtsReadAloudPlayer();

  TtsService get _service => TtsService.instance;

  @override
  Future<void> apply(ReadAloudSettings settings) {
    return _service.applyConfig(
      TtsConfig(
        language: settings.language,
        rate: settings.ttsRate,
        pitch: settings.pitch,
        volume: settings.volume,
        voiceName: settings.voiceName,
        voiceLocale: settings.voiceLocale,
      ),
    );
  }

  @override
  Future<List<TtsVoice>> voices() => _service.voices();

  @override
  Future<void> play(List<String> segments, {int startIndex = 0}) async {
    await _service.playSegments(segments, startIndex: startIndex);
  }

  @override
  void bind({ValueChanged<int>? onSegmentStarted, VoidCallback? onCompleted}) {
    final handler = _service.handler;
    if (handler == null) return;
    handler.onSegmentStarted = onSegmentStarted;
    handler.onCompleted = onCompleted;
  }

  @override
  Future<void> pause() => _service.pause();

  @override
  Future<void> stop() => _service.stop();

  @override
  Future<void> restartCurrent() => _service.restartCurrent();

  @override
  Future<void> preview(ReadAloudSettings settings, String text) async {
    await stop();
    await apply(settings);
    await _service.speakOnce(text);
  }
}

final readAloudPlayerProvider = Provider<ReadAloudPlayer>((ref) {
  return const TtsReadAloudPlayer();
});
