import 'package:dudo/core/exceptions/app_exception.dart';
import 'package:dudo/core/tts/system_tts_settings.dart';
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

/// The online panel is taller than the default 800x600 test surface; a phone
/// sized viewport keeps the test button on screen without scrolling.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.settings.voiceName, 'zh-cn-x-ccc-local');
    expect(repository.settings.voiceLocale, 'zh-CN');
    // Browsing the voice list stays silent; only 试听 plays a sample.
    expect(player.spoken, isEmpty);
    expect(find.byIcon(LucideIcons.play), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('read-aloud-preview-button')),
    );
    await tester.pump();

    expect(player.spoken, isNotEmpty);
    expect(find.byIcon(LucideIcons.square), findsOneWidget);
  });

  testWidgets('every system voice is listed, not just the first eight',
      (tester) async {
    final repository = _MemoryReadAloudRepository();
    final player = _FakeReadAloudPlayer()
      ..voicesResult = [
        for (var index = 0; index < 12; index++)
          TtsVoice(name: 'zh-cn-x-v$index', locale: 'zh-CN'),
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

    expect(find.text('中文 · v0'), findsOneWidget);
    expect(find.text('中文 · v11'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(-900, 0));
    await tester.pump();

    expect(find.text('中文 · v11'), findsOneWidget);
  });

  testWidgets('a selected voice filtered out of the Chinese list stays visible',
      (tester) async {
    final repository = _MemoryReadAloudRepository()
      ..settings = ReadAloudSettings.defaults().copyWith(
        voiceName: 'en-us-x-aaa',
        voiceLocale: 'en-US',
      );
    final player = _FakeReadAloudPlayer()
      ..voicesResult = const [
        TtsVoice(name: 'en-us-x-aaa', locale: 'en-US'),
        TtsVoice(name: 'zh-cn-x-bbb', locale: 'zh-CN'),
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

    expect(find.text('en-US · aaa'), findsOneWidget);
    expect(find.text('中文 · bbb'), findsOneWidget);
  });

  testWidgets('the system voice settings row opens the platform screen',
      (tester) async {
    final repository = _MemoryReadAloudRepository();
    final player = _FakeReadAloudPlayer();
    final settingsLauncher = _FakeSystemTtsSettings();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readAloudSettingsRepositoryProvider.overrideWithValue(repository),
          readAloudPlayerProvider.overrideWithValue(player),
          systemTtsSettingsProvider.overrideWithValue(settingsLauncher),
        ],
        child: const MaterialApp(home: ReadAloudSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('read-aloud-system-tts-settings')),
    );
    await tester.pump();

    expect(settingsLauncher.opened, isTrue);
  });

  testWidgets('a device without the system screen shows a hint',
      (tester) async {
    final repository = _MemoryReadAloudRepository();
    final player = _FakeReadAloudPlayer();
    final settingsLauncher = _FakeSystemTtsSettings()..result = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readAloudSettingsRepositoryProvider.overrideWithValue(repository),
          readAloudPlayerProvider.overrideWithValue(player),
          systemTtsSettingsProvider.overrideWithValue(settingsLauncher),
        ],
        child: const MaterialApp(home: ReadAloudSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('read-aloud-system-tts-settings')),
    );
    await tester.pump();

    expect(
      find.text('无法打开系统语音设置，请手动前往系统设置 → 语音合成'),
      findsOneWidget,
    );
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

  testWidgets('an address without a scheme is flagged and cannot be used',
      (tester) async {
    _useTallViewport(tester);
    final repository = _MemoryReadAloudRepository()
      ..settings = ReadAloudSettings.defaults().copyWith(
        engine: ReadAloudEngine.online,
        onlineUrl: 'tts.example.com/speak',
      );
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

    // The field and the preview hint both explain the problem.
    expect(find.text('地址需以 http:// 或 https:// 开头'), findsNWidgets(2));

    await tester.tap(
      find.byKey(const ValueKey('read-aloud-preview-button')),
    );
    await tester.pump();
    expect(player.spoken, isEmpty);

    await tester.tap(find.byKey(const ValueKey('read-aloud-test-connection')));
    await tester.pump();
    expect(player.testCalls, 0);
  });

  testWidgets('a successful connection test says so', (tester) async {
    _useTallViewport(tester);
    final repository = _MemoryReadAloudRepository()
      ..settings = ReadAloudSettings.defaults().copyWith(
        engine: ReadAloudEngine.online,
        onlineUrl: 'https://tts.example.com/speak',
      );
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

    await tester.tap(find.byKey(const ValueKey('read-aloud-test-connection')));
    await tester.pump();
    await tester.pump();

    expect(player.testCalls, 1);
    expect(player.testedSettings?.onlineUrl, 'https://tts.example.com/speak');
    expect(find.text('连接成功，接口返回了音频'), findsOneWidget);
  });

  testWidgets('a failed connection test names the reason', (tester) async {
    _useTallViewport(tester);
    final repository = _MemoryReadAloudRepository()
      ..settings = ReadAloudSettings.defaults().copyWith(
        engine: ReadAloudEngine.online,
        onlineUrl: 'https://tts.example.com/speak',
        onlineToken: 'bad-token',
      );
    final player = _FakeReadAloudPlayer()
      ..testError = const AppException(
        type: AppExceptionType.unauthorized,
        message: '访问令牌无效或没有权限（HTTP 401）',
      );

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

    await tester.tap(find.byKey(const ValueKey('read-aloud-test-connection')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('连接失败：访问令牌无效或没有权限（HTTP 401）'),
      findsOneWidget,
    );
  });

  testWidgets('editing the endpoint clears the previous test result',
      (tester) async {
    _useTallViewport(tester);
    final repository = _MemoryReadAloudRepository()
      ..settings = ReadAloudSettings.defaults().copyWith(
        engine: ReadAloudEngine.online,
        onlineUrl: 'https://tts.example.com/speak',
      );
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

    await tester.tap(find.byKey(const ValueKey('read-aloud-test-connection')));
    await tester.pump();
    await tester.pump();
    expect(find.text('连接成功，接口返回了音频'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('read-aloud-online-url')),
        matching: find.byType(TextField),
      ),
      'https://tts.example.com/other',
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('连接成功，接口返回了音频'), findsNothing);
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

class _FakeSystemTtsSettings implements SystemTtsSettings {
  bool result = true;
  bool opened = false;

  @override
  Future<bool> open() async {
    opened = true;
    return result;
  }
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
  int testCalls = 0;
  ReadAloudSettings? testedSettings;
  Object? testError;
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
  Future<void> play(
    List<String> segments, {
    int startIndex = 0,
    String? title,
  }) async {
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
  Future<void> resume() async {}

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
  Future<void> testOnlineConnection(ReadAloudSettings settings) async {
    testCalls++;
    testedSettings = settings;
    final error = testError;
    if (error != null) throw error;
  }
}
