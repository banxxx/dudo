import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/tts/tts_models.dart';
import '../../../../core/tts/tts_service.dart';
import '../data/online_tts_transport.dart';
import '../domain/read_aloud_settings.dart';

/// The subset of a TTS backend the settings page and the reader need, so
/// widget tests can run without platform plugins or network access.
abstract interface class ReadAloudPlayer {
  Future<void> apply(ReadAloudSettings settings);

  Future<List<TtsVoice>> voices();

  /// Starts speaking the given chapter segments and reports progress.
  Future<void> play(List<String> segments, {int startIndex = 0});

  /// Installs progress callbacks. [onFailed] fires when playback could not
  /// produce any sound (the endpoint is unreachable and every segment failed).
  /// [onProgress] reports 0..1 inside the current segment; its first call
  /// means sound started, so callers can end their loading state.
  void bind({
    ValueChanged<int>? onSegmentStarted,
    VoidCallback? onCompleted,
    ValueChanged<Object>? onFailed,
    ValueChanged<double>? onProgress,
  });

  Future<void> pause();

  Future<void> stop();

  /// Re-reads the current segment, used when the speed changed mid-playback.
  Future<void> restartCurrent();

  /// Speaks a short sample with the given settings.
  Future<void> preview(ReadAloudSettings settings, String text);
}

/// The platform TTS engine (`flutter_tts` + `audio_service`).
class SystemReadAloudPlayer implements ReadAloudPlayer {
  const SystemReadAloudPlayer();

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
  void bind({
    ValueChanged<int>? onSegmentStarted,
    VoidCallback? onCompleted,
    ValueChanged<Object>? onFailed,
    ValueChanged<double>? onProgress,
  }) {
    final handler = _service.handler;
    if (handler == null) return;
    handler.onSegmentStarted = onSegmentStarted;
    handler.onCompleted = onCompleted;
    handler.onProgress = onProgress;
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
    // Goes through the queue instead of `speakOnce` so the completion and
    // word progress callbacks installed by [bind] fire for the sample too.
    await play([text]);
  }
}

/// A user supplied HTTP endpoint that returns audio bytes for each segment.
class OnlineReadAloudPlayer implements ReadAloudPlayer {
  OnlineReadAloudPlayer({OnlineTtsTransport? transport})
      : _transport = transport ?? const DioOnlineTtsTransport();

  final OnlineTtsTransport _transport;
  AudioPlayer? _audioPlayer;
  File? _currentFile;
  List<String> _segments = const [];
  int _cursor = 0;
  int _generation = 0;
  bool _playing = false;
  ReadAloudSettings _settings = ReadAloudSettings.defaults();
  ValueChanged<int>? _onSegmentStarted;
  VoidCallback? _onCompleted;
  ValueChanged<Object>? _onFailed;
  ValueChanged<double>? _onProgress;
  StreamSubscription<Duration>? _progressSubscription;

  AudioPlayer get _audio => _audioPlayer ??= AudioPlayer();

  @override
  Future<void> apply(ReadAloudSettings settings) async {
    _settings = settings;
  }

  @override
  Future<List<TtsVoice>> voices() async => const [];

  @override
  void bind({
    ValueChanged<int>? onSegmentStarted,
    VoidCallback? onCompleted,
    ValueChanged<Object>? onFailed,
    ValueChanged<double>? onProgress,
  }) {
    _onSegmentStarted = onSegmentStarted;
    _onCompleted = onCompleted;
    _onFailed = onFailed;
    _onProgress = onProgress;
  }

  @override
  Future<void> play(List<String> segments, {int startIndex = 0}) async {
    await stop();
    if (segments.isEmpty) return;
    _segments = List<String>.of(segments);
    _cursor = startIndex.clamp(0, segments.length - 1);
    _playing = true;
    final generation = ++_generation;
    unawaited(_run(generation));
  }

  Future<void> _run(int generation) async {
    var failures = 0;
    Object? lastError;
    while (
        _playing && generation == _generation && _cursor < _segments.length) {
      final index = _cursor;
      _onSegmentStarted?.call(index);
      try {
        final bytes = await _transport.synthesize(_settings, _segments[index]);
        if (!_isCurrent(generation)) return;
        final file = await _writeAudio(bytes, index);
        if (!_isCurrent(generation)) return;
        _replaceFile(file);
        await _audio.setFilePath(file.path);
        if (!_isCurrent(generation)) return;
        // The file is decoded and about to play: report a real 0..1 position
        // instead of leaving the caller in its loading state.
        _watchProgress(generation);
        _onProgress?.call(0);
        await _audio.play();
        await _audio.playerStateStream.firstWhere(
          (state) =>
              state.processingState == ProcessingState.completed ||
              state.processingState == ProcessingState.idle,
        );
      } catch (error, stackTrace) {
        // A failing segment should not abort the chapter; skip it the way
        // Legado's HTTP read-aloud service does.
        failures++;
        lastError = error;
        debugPrint('[online-tts] segment $index failed: $error\n$stackTrace');
      }
      if (!_isCurrent(generation)) return;
      _cursor++;
    }
    if (generation != _generation) return;
    _playing = false;
    if (failures > 0 && failures == _segments.length) {
      // Nothing could be synthesized at all (bad URL, offline, bad token);
      // callers show an error instead of silently "finishing".
      _onFailed?.call(lastError!);
      return;
    }
    _onCompleted?.call();
  }

  bool _isCurrent(int generation) => _playing && generation == _generation;

  void _watchProgress(int generation) {
    unawaited(_progressSubscription?.cancel());
    _progressSubscription = _audio.positionStream.listen((position) {
      if (!_isCurrent(generation)) return;
      final total = _audio.duration?.inMicroseconds ?? 0;
      if (total <= 0) return;
      final fraction = (position.inMicroseconds / total).clamp(0.0, 1.0);
      _onProgress?.call(fraction.toDouble());
    });
  }

  Future<File> _writeAudio(List<int> bytes, int index) async {
    final directory = Directory(
      '${(await getTemporaryDirectory()).path}/dudo_tts',
    );
    if (!directory.existsSync()) directory.createSync(recursive: true);
    final file = File('${directory.path}/segment_$index.mp3');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _replaceFile(File next) {
    final previous = _currentFile;
    if (previous != null && previous.path != next.path) {
      unawaited(previous.delete().then((_) {}, onError: (_) {}));
    }
    _currentFile = next;
  }

  @override
  Future<void> pause() => stop();

  @override
  Future<void> stop() async {
    _playing = false;
    _generation++;
    _segments = const [];
    _cursor = 0;
    unawaited(_progressSubscription?.cancel());
    _progressSubscription = null;
    final player = _audioPlayer;
    if (player != null) await player.stop();
  }

  @override
  Future<void> restartCurrent() async {
    if (!_playing) return;
    final segments = List<String>.of(_segments);
    final cursor = _cursor;
    await play(segments, startIndex: cursor);
  }

  @override
  Future<void> preview(ReadAloudSettings settings, String text) async {
    _settings = settings;
    await play([text]);
  }
}

/// Picks the backend from the saved settings; both engines are kept alive so
/// switching engines does not recreate platform resources.
class RoutingReadAloudPlayer implements ReadAloudPlayer {
  RoutingReadAloudPlayer({
    ReadAloudPlayer? system,
    ReadAloudPlayer? online,
  })  : _system = system ?? const SystemReadAloudPlayer(),
        _online = online ?? OnlineReadAloudPlayer();

  final ReadAloudPlayer _system;
  final ReadAloudPlayer _online;
  ReadAloudSettings _settings = ReadAloudSettings.defaults();

  ReadAloudPlayer get _active =>
      _settings.engine == ReadAloudEngine.online ? _online : _system;

  @override
  Future<void> apply(ReadAloudSettings settings) {
    _settings = settings;
    return _active.apply(settings);
  }

  @override
  Future<List<TtsVoice>> voices() => _active.voices();

  @override
  Future<void> play(List<String> segments, {int startIndex = 0}) {
    return _active.play(segments, startIndex: startIndex);
  }

  @override
  void bind({
    ValueChanged<int>? onSegmentStarted,
    VoidCallback? onCompleted,
    ValueChanged<Object>? onFailed,
    ValueChanged<double>? onProgress,
  }) {
    _system.bind(
      onSegmentStarted: onSegmentStarted,
      onCompleted: onCompleted,
      onFailed: onFailed,
      onProgress: onProgress,
    );
    _online.bind(
      onSegmentStarted: onSegmentStarted,
      onCompleted: onCompleted,
      onFailed: onFailed,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> pause() => _active.pause();

  @override
  Future<void> stop() async {
    await Future.wait([_system.stop(), _online.stop()]);
  }

  @override
  Future<void> restartCurrent() => _active.restartCurrent();

  @override
  Future<void> preview(ReadAloudSettings settings, String text) {
    _settings = settings;
    return _active.preview(settings, text);
  }
}

final readAloudPlayerProvider = Provider<ReadAloudPlayer>((ref) {
  return RoutingReadAloudPlayer();
});
