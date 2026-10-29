import 'package:dudo/core/tts/tts_models.dart';
import 'package:dudo/features/settings/read_aloud_settings/application/read_aloud_player.dart';
import 'package:dudo/features/settings/read_aloud_settings/application/read_aloud_settings_provider.dart';
import 'package:dudo/features/settings/read_aloud_settings/data/read_aloud_settings_repository.dart';
import 'package:dudo/features/settings/read_aloud_settings/domain/read_aloud_settings.dart';
import 'package:dudo/features/settings/read_aloud_settings/presentation/read_aloud_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('renders the persisted settings and device voices',
      (tester) async {
    final repository = _MemoryReadAloudRepository()
      ..settings = ReadAloudSettings.defaults().copyWith(
        speechRate: 1.3,
        volume: 0.5,
        timerMinutes: 30,
      );
    final player = _FakeReadAloudPlayer()
      ..voicesResult = const [
        TtsVoice(name: 'zh-cn-x-ccc-local', locale: 'zh-CN'),
      ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readAloudSettingsRepositoryProvider.overrideWithValue(repository),
          readAloudPlayerProvider.overrideWithValue(player),
        ],
        child: const MaterialApp(home: ReadAloudSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('试听朗读'), findsOneWidget);
    expect(find.text('1.3x'), findsWidgets);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('30 分钟'), findsOneWidget);
    expect(find.text('系统默认'), findsOneWidget);
    expect(find.text('中文 · local'), findsOneWidget);

    await tester.tap(find.text('中文 · local'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.settings.voiceName, 'zh-cn-x-ccc-local');
    expect(repository.settings.voiceLocale, 'zh-CN');
  });

  testWidgets('switching to the online engine persists the endpoint',
      (tester) async {
    final repository = _MemoryReadAloudRepository();
    final player = _FakeReadAloudPlayer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readAloudSettingsRepositoryProvider.overrideWithValue(repository),
          readAloudPlayerProvider.overrideWithValue(player),
        ],
        child: const MaterialApp(home: ReadAloudSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('在线引擎'));
    await tester.pumpAndSettle();

    expect(find.text('接口地址'), findsOneWidget);
    expect(find.text('系统默认'), findsNothing);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('read-aloud-online-url')),
        matching: find.byType(TextField),
      ),
      'https://tts.example.com/speak',
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.settings.engine, ReadAloudEngine.online);
    expect(repository.settings.onlineUrl, 'https://tts.example.com/speak');
  });

  testWidgets('retries when the engine reports no voices at first',
      (tester) async {
    final repository = _MemoryReadAloudRepository();
    final player = _FakeReadAloudPlayer()
      ..emptyFirstVoiceCall = true
      ..voicesResult = const [
        TtsVoice(name: 'zh-cn-x-ccc-local', locale: 'zh-CN'),
      ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readAloudSettingsRepositoryProvider.overrideWithValue(repository),
          readAloudPlayerProvider.overrideWithValue(player),
        ],
        child: const MaterialApp(home: ReadAloudSettingsPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(player.voicesCalls, greaterThan(1));
    expect(find.text('中文 · local'), findsOneWidget);
  });

  testWidgets('preview speaks the sample with the current settings',
      (tester) async {
    final repository = _MemoryReadAloudRepository()
      ..settings = ReadAloudSettings.defaults().copyWith(volume: 0.4);
    final player = _FakeReadAloudPlayer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readAloudSettingsRepositoryProvider.overrideWithValue(repository),
          readAloudPlayerProvider.overrideWithValue(player),
        ],
        child: const MaterialApp(home: ReadAloudSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('read-aloud-preview-button')),
    );
    await tester.pump();

    expect(player.spoken, isNotEmpty);
    expect(player.applied?.volume, 0.4);
    expect(find.byIcon(LucideIcons.square), findsOneWidget);

    // No playback position yet: the bar keeps its loading animation.
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .value,
      isNull,
    );

    player.fireProgress(0.42);
    await tester.pump();
    // The bar eases towards the reported position instead of jumping.
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .value,
      0.42,
    );

    player.fireCompleted();
    await tester.pump();

    expect(find.byIcon(LucideIcons.play), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('changing a setting stops the running preview', (tester) async {
    final repository = _MemoryReadAloudRepository();
    final player = _FakeReadAloudPlayer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readAloudSettingsRepositoryProvider.overrideWithValue(repository),
          readAloudPlayerProvider.overrideWithValue(player),
        ],
        child: const MaterialApp(home: ReadAloudSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('read-aloud-preview-button')),
    );
    await tester.pump();
    expect(find.byIcon(LucideIcons.square), findsOneWidget);

    await tester.tap(find.text('在线引擎'));
    await tester.pump();

    expect(player.stopped, isTrue);
    expect(find.byIcon(LucideIcons.play), findsOneWidget);
  });

  testWidgets('preview stays disabled until the online endpoint is filled',
      (tester) async {
    final repository = _MemoryReadAloudRepository();
    final player = _FakeReadAloudPlayer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readAloudSettingsRepositoryProvider.overrideWithValue(repository),
          readAloudPlayerProvider.overrideWithValue(player),
        ],
        child: const MaterialApp(home: ReadAloudSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('在线引擎'));
    await tester.pumpAndSettle();

    expect(find.text('填写在线接口地址后可试听'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('read-aloud-preview-button')),
    );
    await tester.pump();
    expect(player.spoken, isEmpty);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('read-aloud-online-url')),
        matching: find.byType(TextField),
      ),
      'https://tts.example.com/speak',
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(
      find.byKey(const ValueKey('read-aloud-preview-button')),
    );
    await tester.pump();

    expect(player.spoken, isNotEmpty);
    expect(find.byIcon(LucideIcons.square), findsOneWidget);
  });

  testWidgets('a failed preview shows a message instead of hanging',
      (tester) async {
    final repository = _MemoryReadAloudRepository();
    final player = _FakeReadAloudPlayer();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readAloudSettingsRepositoryProvider.overrideWithValue(repository),
          readAloudPlayerProvider.overrideWithValue(player),
        ],
        child: const MaterialApp(home: ReadAloudSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('read-aloud-preview-button')),
    );
    await tester.pump();

    player.fireFailed(Exception('offline'));
    await tester.pump();

    expect(find.text('试听失败：请检查接口地址、访问令牌与网络'), findsOneWidget);
    expect(find.byIcon(LucideIcons.play), findsOneWidget);
  });
}

class _MemoryReadAloudRepository implements ReadAloudSettingsRepository {
  ReadAloudSettings settings = ReadAloudSettings.defaults();

  @override
  Future<ReadAloudSettings> load() async => settings;

  @override
  Future<void> save(ReadAloudSettings settings) async {
    this.settings = settings;
  }

  @override
  Stream<ReadAloudSettings> watch() => Stream.value(settings);
}

class _FakeReadAloudPlayer implements ReadAloudPlayer {
  List<TtsVoice> voicesResult = const [];
  bool emptyFirstVoiceCall = false;
  int voicesCalls = 0;
  final List<String> spoken = [];
  ReadAloudSettings? applied;
  bool stopped = false;
  ValueChanged<int>? _onSegmentStarted;
  VoidCallback? _onCompleted;
  ValueChanged<Object>? _onFailed;
  ValueChanged<double>? _onProgress;

  void fireCompleted() => _onCompleted?.call();

  void fireFailed(Object error) => _onFailed?.call(error);

  void fireProgress(double progress) => _onProgress?.call(progress);

  @override
  Future<void> apply(ReadAloudSettings settings) async {
    applied = settings;
  }

  @override
  Future<List<TtsVoice>> voices() async {
    voicesCalls++;
    if (emptyFirstVoiceCall && voicesCalls == 1) return const [];
    return voicesResult;
  }

  @override
  Future<void> play(List<String> segments, {int startIndex = 0}) async {
    spoken
      ..clear()
      ..addAll(segments);
    _onSegmentStarted?.call(startIndex);
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
    _onFailed = onFailed;
    _onProgress = onProgress;
  }

  @override
  Future<void> pause() async {}

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
}
