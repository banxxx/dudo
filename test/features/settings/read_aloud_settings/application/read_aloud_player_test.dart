import 'dart:io';

import 'package:dudo/core/tts/tts_models.dart';
import 'package:dudo/features/settings/read_aloud_settings/application/read_aloud_player.dart';
import 'package:dudo/features/settings/read_aloud_settings/data/online_tts_transport.dart';
import 'package:dudo/features/settings/read_aloud_settings/domain/read_aloud_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _RecordingPlayer system;
  late _RecordingPlayer online;
  late RoutingReadAloudPlayer player;

  setUp(() {
    system = _RecordingPlayer();
    online = _RecordingPlayer();
    player = RoutingReadAloudPlayer(system: system, online: online);
  });

  test('system settings play and apply on the system engine', () async {
    final settings = ReadAloudSettings.defaults();

    await player.apply(settings);
    await player.play(const ['第一段']);

    expect(system.applied, settings);
    expect(system.spoken, ['第一段']);
    expect(online.spoken, isEmpty);
  });

  test('online settings route playback to the online engine', () async {
    final settings = ReadAloudSettings.defaults().copyWith(
      engine: ReadAloudEngine.online,
      onlineUrl: 'https://tts.example.com/speak',
    );

    await player.apply(settings);
    await player.play(const ['第一段', '第二段']);

    expect(online.applied, settings);
    expect(online.spoken, ['第一段', '第二段']);
    expect(system.spoken, isEmpty);
  });

  test('pause and resume reach the selected engine', () async {
    await player.apply(ReadAloudSettings.defaults());
    await player.pause();
    await player.resume();

    expect(system.paused, isTrue);
    expect(system.resumed, isTrue);
    expect(online.paused, isFalse);
  });

  test('bind forwards callbacks to both engines', () {
    var started = -1;
    var completed = false;

    player.bind(
      onSegmentStarted: (index) => started = index,
      onCompleted: () => completed = true,
    );

    system.fireSegmentStarted(2);
    online.fireCompleted();

    expect(started, 2);
    expect(completed, isTrue);
  });

  test('voices follow the selected engine', () async {
    system.voicesResult = const [
      TtsVoice(name: 'zh-cn-x-ccc', locale: 'zh-CN')
    ];
    online.voicesResult = const [
      TtsVoice(name: 'online-voice', locale: 'zh-CN'),
    ];

    await player.apply(ReadAloudSettings.defaults());
    expect((await player.voices()).single.name, 'zh-cn-x-ccc');

    await player.apply(
      ReadAloudSettings.defaults().copyWith(engine: ReadAloudEngine.online),
    );
    expect((await player.voices()).single.name, 'online-voice');
  });

  test('online playback reports a failure instead of completing silently',
      () async {
    final onlinePlayer = OnlineReadAloudPlayer(transport: _FailingTransport());
    Object? failure;
    var completed = false;
    onlinePlayer.bind(
      onCompleted: () => completed = true,
      onFailed: (error) => failure = error,
    );

    await onlinePlayer.play(const ['第一段']);
    await pumpEventQueue();

    expect(failure, isA<HttpException>());
    expect(completed, isFalse);
  });

  test('a dead endpoint aborts after a few segments instead of the chapter',
      () async {
    final transport = _FailingTransport();
    final onlinePlayer = OnlineReadAloudPlayer(transport: transport);
    Object? failure;
    var started = -1;
    onlinePlayer.bind(
      onSegmentStarted: (index) => started = index,
      onFailed: (error) => failure = error,
    );

    await onlinePlayer.play(const ['一', '二', '三', '四', '五', '六']);
    await pumpEventQueue();

    expect(failure, isA<HttpException>());
    expect(transport.calls, 3);
    // Nothing ever played, so the page was never moved to a new paragraph.
    expect(started, -1);
  });

  test('stop stops both engines so a switched engine cannot keep talking',
      () async {
    await player.stop();

    expect(system.stopped, isTrue);
    expect(online.stopped, isTrue);
  });
}

class _RecordingPlayer implements ReadAloudPlayer {
  final List<String> spoken = [];
  ReadAloudSettings? applied;
  List<TtsVoice> voicesResult = const [];
  bool stopped = false;
  bool paused = false;
  bool resumed = false;
  ValueChanged<int>? _onSegmentStarted;
  VoidCallback? _onCompleted;

  void fireSegmentStarted(int index) => _onSegmentStarted?.call(index);

  void fireCompleted() => _onCompleted?.call();

  @override
  Future<void> apply(ReadAloudSettings settings) async {
    applied = settings;
  }

  @override
  Future<List<TtsVoice>> voices() async => voicesResult;

  @override
  Future<void> play(
    List<String> segments, {
    int startIndex = 0,
    String? title,
  }) async {
    spoken
      ..clear()
      ..addAll(segments);
  }

  @override
  void bind({
    ValueChanged<int>? onSegmentStarted,
    VoidCallback? onCompleted,
    ValueChanged<Object>? onFailed,
    ValueChanged<double>? onProgress,
  }) {
    _onSegmentStarted = onSegmentStarted;
    _onCompleted = onCompleted;
  }

  @override
  Future<void> pause() async {
    paused = true;
  }

  @override
  Future<void> resume() async {
    resumed = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> restartCurrent() async {}

  @override
  Future<void> preview(ReadAloudSettings settings, String text) async {
    await play([text]);
  }

  @override
  Future<void> testOnlineConnection(ReadAloudSettings settings) async {}
}

class _FailingTransport implements OnlineTtsTransport {
  int calls = 0;

  @override
  Future<List<int>> synthesize(ReadAloudSettings settings, String text) async {
    calls++;
    throw const HttpException('offline');
  }
}
