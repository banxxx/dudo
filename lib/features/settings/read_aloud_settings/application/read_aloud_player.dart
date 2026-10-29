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
  /// [title] is what the media notification shows while playing.
  Future<void> play(
    List<String> segments, {
    int startIndex = 0,
    String? title,
  });

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

  /// Stops making sound but keeps the position, so [resume] continues from
  /// where it left off instead of restarting the chapter.
  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  /// Re-reads the current segment, used when the speed changed mid-playback.
  Future<void> restartCurrent();

  /// Speaks a short sample with the given settings.
  Future<void> preview(ReadAloudSettings settings, String text);

  /// Sends a short sample to the online endpoint and discards the audio;
  /// throws an `AppException` describing why it failed.
  Future<void> testOnlineConnection(ReadAloudSettings settings);
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
  Future<void> play(
    List<String> segments, {
    int startIndex = 0,
    String? title,
  }) async {
    await _service.playSegments(segments, startIndex: startIndex, title: title);
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

  /// flutter_tts cannot resume inside an utterance, so the current segment is
  /// spoken again; the chapter position is preserved.
  @override
  Future<void> resume() => _service.resume();

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

  @override
  Future<void> testOnlineConnection(ReadAloudSettings settings) async {}
}

/// A user supplied HTTP endpoint that returns audio bytes for each segment.
class OnlineReadAloudPlayer implements ReadAloudPlayer {
  OnlineReadAloudPlayer({OnlineTtsTransport? transport})
      : _transport = transport ?? const DioOnlineTtsTransport();

  final OnlineTtsTransport _transport;
  AudioPlayer? _audioPlayer;
  File? _currentFile;
  TtsAudioHandler? get _handler => TtsService.instance.handler;
  List<String> _segments = const [];
  String? _title;
  int _cursor = 0;
  int _generation = 0;
  bool _playing = false;
  bool _paused = false;
  Completer<void>? _resumeSignal;
  ReadAloudSettings _settings = ReadAloudSettings.defaults();
  ValueChanged<int>? _onSegmentStarted;
  VoidCallback? _onCompleted;
  ValueChanged<Object>? _onFailed;
  ValueChanged<double>? _onProgress;
  StreamSubscription<Duration>? _progressSubscription;

  /// Playback goes through the audio_service handler's player when it exists,
  /// so the foreground service (and its notification) keeps running while the
  /// screen is off. Tests and early calls fall back to a plain player.
  AudioPlayer get _audio =>
      _audioPlayer ??= _handler?.onlinePlayer ?? AudioPlayer();

  @override
  Future<void> apply(ReadAloudSettings settings) async {
    _settings = settings;
    // The system engine applies volume through flutter_tts; the online player
    // owns its AudioPlayer, so the slider has to be forwarded here.
    await _audioPlayer?.setVolume(settings.volume);
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
  Future<void> play(
    List<String> segments, {
    int startIndex = 0,
    String? title,
  }) async {
    // A skip or a new chapter restarts the queue without tearing the media
    // session down, so the notification does not blink between paragraphs.
    await _haltQueue();
    if (segments.isEmpty) return;
    unawaited(TtsService.instance.ensureNotificationPermission());
    // Skipping to another segment re-enters play() without a title.
    if (title != null) _title = title;
    _handler?.setMediaTitle(_title);
    _segments = List<String>.of(segments);
    _cursor = startIndex.clamp(0, segments.length - 1);
    _playing = true;
    // Lock-screen / notification controls are routed back here, so pausing
    // from the notification keeps the queue position instead of the loop
    // treating it as a finished segment.
    final handler = _handler;
    if (handler != null) {
      handler.onOnlinePause = pause;
      handler.onOnlineResume = resume;
      handler.onOnlineSkipToNext = _skipToNextSegment;
      handler.onOnlineSkipToPrevious = _skipToPreviousSegment;
    }
    final generation = ++_generation;
    unawaited(_run(generation));
  }

  /// An unreachable endpoint can time out on every segment; aborting after a
  /// few consecutive failures reports the problem instead of leaving the
  /// reader silently "reading" through the whole chapter.
  static const _maxConsecutiveFailures = 3;

  Future<void> _run(int generation) async {
    var failures = 0;
    var consecutiveFailures = 0;
    Object? lastError;
    while (
        _playing && generation == _generation && _cursor < _segments.length) {
      final index = _cursor;
      try {
        final bytes = await _transport.synthesize(_settings, _segments[index]);
        if (!_isCurrent(generation)) return;
        final file = await _writeAudio(bytes, index);
        if (!_isCurrent(generation)) return;
        _replaceFile(file);
        // From here on the handler mirrors the player into playbackState, which
        // is what starts the foreground service.
        _handler?.beginOnlinePlayback();
        await _audio.setFilePath(file.path);
        if (!_isCurrent(generation)) return;
        // The file is decoded and about to play: report a real 0..1 position
        // instead of leaving the caller in its loading state.
        _watchProgress(generation);
        _onProgress?.call(0);
        await _audio.setVolume(_settings.volume);
        await _waitWhilePaused(generation);
        if (!_isCurrent(generation)) return;
        // Reported only once the audio is ready, so a failing endpoint does not
        // move the visible page to paragraphs that were never spoken.
        _onSegmentStarted?.call(index);
        while (true) {
          await _audio.play();
          if (!_isCurrent(generation)) return;
          if (_audio.processingState == ProcessingState.completed) break;
          if (!_paused) break;
          // Pausing completes the play future; wait for resume, then continue
          // the same file from where it stopped.
          await _waitWhilePaused(generation);
          if (!_isCurrent(generation)) return;
        }
        consecutiveFailures = 0;
      } catch (error, stackTrace) {
        // One failing segment should not abort the chapter; skip it the way
        // Legado's HTTP read-aloud service does.
        failures++;
        consecutiveFailures++;
        lastError = error;
        debugPrint('[online-tts] segment $index failed: $error\n$stackTrace');
        if (consecutiveFailures >= _maxConsecutiveFailures) break;
      }
      if (!_isCurrent(generation)) return;
      _cursor++;
    }
    if (generation != _generation) return;
    _playing = false;
    if ((failures > 0 && failures == _segments.length) ||
        consecutiveFailures >= _maxConsecutiveFailures) {
      // Nothing could be synthesized at all (bad URL, offline, bad token);
      // callers show an error instead of silently "finishing".
      _onFailed?.call(lastError!);
      return;
    }
    _onCompleted?.call();
  }

  bool _isCurrent(int generation) => _playing && generation == _generation;

  Future<void> _waitWhilePaused(int generation) async {
    while (_paused && _isCurrent(generation)) {
      final signal = _resumeSignal ??= Completer<void>();
      await signal.future;
    }
  }

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
  Future<void> pause() async {
    if (!_playing || _paused) return;
    _paused = true;
    // Pausing from the in-app panel never goes through the handler's pause(),
    // so the notification has to be told as well or it keeps showing "playing".
    _handler?.setOnlinePlaying(false);
    final player = _audioPlayer;
    if (player != null) await player.pause();
  }

  @override
  Future<void> resume() async {
    if (!_paused) return;
    _paused = false;
    _handler?.setOnlinePlaying(true);
    _resumeSignal?.complete();
    _resumeSignal = null;
  }

  /// Stops the current queue and its audio but keeps the media session, used
  /// when the same player immediately starts another queue.
  Future<void> _haltQueue() async {
    _playing = false;
    _paused = false;
    _resumeSignal?.complete();
    _resumeSignal = null;
    _generation++;
    _segments = const [];
    _cursor = 0;
    unawaited(_progressSubscription?.cancel());
    _progressSubscription = null;
    await _audioPlayer?.stop();
  }

  @override
  Future<void> stop() async {
    _playing = false;
    _paused = false;
    _resumeSignal?.complete();
    _resumeSignal = null;
    _generation++;
    _segments = const [];
    _cursor = 0;
    unawaited(_progressSubscription?.cancel());
    _progressSubscription = null;
    final handler = _handler;
    if (handler != null) {
      // Also clears the notification and the control callbacks.
      await handler.stopOnlinePlayback();
    } else {
      await _audioPlayer?.stop();
    }
  }

  Future<void> _skipToNextSegment() async {
    if (!_playing) return;
    final next = _cursor + 1;
    if (next >= _segments.length) return;
    await play(List<String>.of(_segments), startIndex: next);
  }

  Future<void> _skipToPreviousSegment() async {
    if (!_playing) return;
    await play(
      List<String>.of(_segments),
      startIndex: _cursor > 0 ? _cursor - 1 : 0,
    );
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

  @override
  Future<void> testOnlineConnection(ReadAloudSettings settings) async {
    await _transport.synthesize(settings, '你好，这是朗读接口测试。');
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
  Future<void> play(
    List<String> segments, {
    int startIndex = 0,
    String? title,
  }) {
    return _active.play(segments, startIndex: startIndex, title: title);
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
  Future<void> resume() => _active.resume();

  @override
  Future<void> stop() async {
    // Online first: its stop also clears the shared handler's online mode, so
    // the system engine's stop then takes its own branch.
    await _online.stop();
    await _system.stop();
  }

  @override
  Future<void> restartCurrent() => _active.restartCurrent();

  @override
  Future<void> preview(ReadAloudSettings settings, String text) {
    _settings = settings;
    return _active.preview(settings, text);
  }

  /// Always checks the online endpoint, whatever engine is selected: the
  /// button exists to validate the interface the user just typed.
  @override
  Future<void> testOnlineConnection(ReadAloudSettings settings) {
    return _online.testOnlineConnection(settings);
  }
}

final readAloudPlayerProvider = Provider<ReadAloudPlayer>((ref) {
  return RoutingReadAloudPlayer();
});
