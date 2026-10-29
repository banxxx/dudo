import 'package:dudo/core/tts/tts_models.dart';
import 'package:dudo/features/settings/read_aloud_settings/application/read_aloud_player.dart';
import 'package:dudo/features/settings/read_aloud_settings/application/read_aloud_settings_provider.dart';
import 'package:dudo/features/settings/read_aloud_settings/data/read_aloud_settings_repository.dart';
import 'package:dudo/features/settings/read_aloud_settings/domain/read_aloud_settings.dart';
import 'package:dudo/features/settings/read_aloud_settings/presentation/read_aloud_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await tester.pumpAndSettle();

    expect(player.spoken, isNotEmpty);
    expect(player.applied?.volume, 0.4);
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
  final List<String> spoken = [];
  ReadAloudSettings? applied;
  ValueChanged<int>? _onSegmentStarted;

  @override
  Future<void> apply(ReadAloudSettings settings) async {
    applied = settings;
  }

  @override
  Future<List<TtsVoice>> voices() async => voicesResult;

  @override
  Future<void> play(List<String> segments, {int startIndex = 0}) async {
    spoken
      ..clear()
      ..addAll(segments);
    _onSegmentStarted?.call(startIndex);
  }

  @override
  void bind({ValueChanged<int>? onSegmentStarted, VoidCallback? onCompleted}) {
    _onSegmentStarted = onSegmentStarted;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> restartCurrent() async {}

  @override
  Future<void> preview(ReadAloudSettings settings, String text) async {
    await play([text]);
  }
}
