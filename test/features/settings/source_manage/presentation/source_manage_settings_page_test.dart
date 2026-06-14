import 'dart:async';

import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/settings/source_manage/presentation/source_manage_settings_page.dart';
import 'package:dudo/features/sources/application/source_providers.dart';
import 'package:dudo/features/sources/data/source_repository.dart';
import 'package:dudo/features/sources/domain/source_import_models.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('renders F3 baseline without design hint text', (tester) async {
    final harness = await _pumpSourceManageSettings(tester);
    addTearDown(harness.dispose);

    expect(find.text('内容与书源'), findsOneWidget);
    expect(find.text('书源管理'), findsOneWidget);
    expect(find.text('添加书源'), findsOneWidget);
    expect(find.text('同步更新'), findsOneWidget);
    expect(find.text('修复失效'), findsOneWidget);
    expect(find.text('1 个书源待启用'), findsOneWidget);
    expect(find.text('点击右上角设置，进入启用与删除管理'), findsNothing);
  });

  testWidgets('top-right settings button toggles management mode',
      (tester) async {
    final harness = await _pumpSourceManageSettings(tester);
    addTearDown(harness.dispose);

    await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
    await tester.pump();

    expect(find.text('全选'), findsOneWidget);
    expect(find.text('批量启用'), findsOneWidget);
    expect(find.text('批量禁用'), findsOneWidget);
    expect(find.text('批量删除'), findsOneWidget);
    expect(find.text('管理模式 · 可启用、禁用或删除'), findsOneWidget);
    expect(find.text('删除'), findsNWidgets(2));

    await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
    await tester.pump();

    expect(find.text('全选'), findsNothing);
    expect(find.text('批量启用'), findsNothing);
    expect(find.text('批量禁用'), findsNothing);
    expect(find.text('管理模式 · 可启用、禁用或删除'), findsNothing);
    expect(find.text('删除'), findsNothing);
  });

  testWidgets('enables a disabled source from management row', (tester) async {
    final harness = await _pumpSourceManageSettings(tester);
    addTearDown(harness.dispose);

    await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
    await tester.pump();
    await tester.tap(find.text('启用'));
    await tester.pump();

    final source = harness.repository.sourceById('fanqie');
    expect(source.enabled, isTrue);
    expect(find.text('已启用'), findsNWidgets(2));
  });

  testWidgets('single delete requires confirmation', (tester) async {
    final harness = await _pumpSourceManageSettings(tester);
    addTearDown(harness.dispose);

    await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
    await tester.pump();
    await tester.tap(find.text('删除').first);
    await tester.pump();

    expect(find.text('删除书源？'), findsOneWidget);
    expect(find.text('将删除“番茄小说”，此操作不可撤销。'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pump();
    expect(harness.repository.sourceCount, 2);

    await tester.tap(find.text('删除').first);
    await tester.pump();
    await tester.tap(find.text('删除').last);
    await tester.pump();

    expect(harness.repository.sourceCount, 1);
    expect(find.text('番茄小说'), findsNothing);
    expect(harness.repository.deleteSourceCallCount, 1);
    expect(harness.repository.deleteSourcesCallCount, 0);
  });

  testWidgets('bulk select and enable only filtered disabled sources',
      (tester) async {
    final harness = await _pumpSourceManageSettings(tester);
    addTearDown(harness.dispose);

    await tester.enterText(find.byType(TextField), '番茄');
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
    await tester.pump();

    expect(find.text('搜索结果 · 1 / 2 个'), findsOneWidget);
    await tester.tap(find.text('全选'));
    await tester.pump();
    expect(find.text('已选 1/1'), findsOneWidget);

    await tester.tap(find.text('批量启用'));
    await tester.pump();

    expect(harness.repository.sourceById('fanqie').enabled, isTrue);
    expect(harness.repository.sourceById('qidian').enabled, isTrue);
    expect(harness.repository.setSourcesEnabledCallCount, 1);
    expect(harness.repository.setSourceEnabledCallCount, 0);
    expect(harness.repository.lastSetSourcesEnabledIds, {'fanqie'});
    expect(harness.repository.lastSetSourcesEnabledValue, isTrue);
  });

  testWidgets('bulk select and disable only filtered enabled sources',
      (tester) async {
    final harness = await _pumpSourceManageSettings(tester);
    addTearDown(harness.dispose);

    await tester.enterText(find.byType(TextField), '起点');
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
    await tester.pump();

    expect(find.text('搜索结果 · 1 / 2 个'), findsOneWidget);
    await tester.tap(find.text('全选'));
    await tester.pump();
    expect(find.text('已选 1/1'), findsOneWidget);

    await tester.tap(find.text('批量禁用'));
    await tester.pump();

    expect(harness.repository.sourceById('qidian').enabled, isFalse);
    expect(harness.repository.sourceById('fanqie').enabled, isFalse);
    expect(harness.repository.setSourcesEnabledCallCount, 1);
    expect(harness.repository.setSourceEnabledCallCount, 0);
    expect(harness.repository.lastSetSourcesEnabledIds, {'qidian'});
    expect(harness.repository.lastSetSourcesEnabledValue, isFalse);
  });

  testWidgets('bulk delete uses repository batch delete once', (tester) async {
    final harness = await _pumpSourceManageSettings(tester);
    addTearDown(harness.dispose);

    await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
    await tester.pump();
    await tester.tap(find.text('全选'));
    await tester.pump();
    await tester.tap(find.text('批量删除'));
    await tester.pump();
    await tester.tap(find.text('删除').last);
    await tester.pump();

    expect(harness.repository.sourceCount, 0);
    expect(harness.repository.deleteSourcesCallCount, 1);
    expect(harness.repository.deleteSourceCallCount, 0);
    expect(harness.repository.lastDeleteSourcesIds, {'fanqie', 'qidian'});
  });

  testWidgets(
      'management bar wraps bulk actions on compact screens without overflow',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.reset);

    final harness = await _pumpSourceManageSettings(tester);
    addTearDown(harness.dispose);

    await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
    await tester.pump();

    expect(find.text('全选'), findsOneWidget);
    expect(find.text('已选 0/2'), findsOneWidget);
    expect(find.text('批量启用'), findsOneWidget);
    expect(find.text('批量禁用'), findsOneWidget);
    expect(find.text('批量删除'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<_Harness> _pumpSourceManageSettings(WidgetTester tester) async {
  final repository = _FakeSourceRepository(_seedSources());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sourceRepositoryProvider.overrideWithValue(repository),
        appMessageServiceProvider.overrideWithValue(_FakeAppMessageService()),
      ],
      child: const MaterialApp(home: SourceManageSettingsPage()),
    ),
  );
  await tester.pump();
  await tester.pump();
  return _Harness(repository);
}

List<Source> _seedSources() {
  final now = DateTime(2026, 6, 13);
  return [
    Source(
      id: 'fanqie',
      name: '番茄小说',
      url: 'https://fanqie.example.com',
      groupName: '网络文学',
      comment: '待启用',
      enabled: false,
      rulesJson: '{}',
      sortOrder: 2,
      createdAt: now,
      updatedAt: now,
    ),
    Source(
      id: 'qidian',
      name: '起点中文',
      url: 'https://qidian.example.com',
      groupName: '正版源',
      comment: null,
      enabled: true,
      rulesJson: '{}',
      sortOrder: 1,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

class _Harness {
  const _Harness(this.repository);

  final _FakeSourceRepository repository;

  void dispose() {
    repository.dispose();
  }
}

class _FakeSourceRepository implements SourceRepository {
  _FakeSourceRepository(List<Source> sources) : _sources = [...sources] {
    _emit();
  }

  final List<Source> _sources;
  final _controller = StreamController<List<Source>>.broadcast();

  int setSourceEnabledCallCount = 0;
  int setSourcesEnabledCallCount = 0;
  int deleteSourceCallCount = 0;
  int deleteSourcesCallCount = 0;
  Set<String> lastSetSourcesEnabledIds = const {};
  bool? lastSetSourcesEnabledValue;
  Set<String> lastDeleteSourcesIds = const {};

  int get sourceCount => _sources.length;

  Source sourceById(String id) {
    return _sources.singleWhere((source) => source.id == id);
  }

  void dispose() {
    _controller.close();
  }

  void _emit() {
    _controller.add(List<Source>.unmodifiable(_sources));
  }

  @override
  AppDatabase get database => throw UnimplementedError();

  @override
  Stream<List<Source>> watchSources() async* {
    yield List<Source>.unmodifiable(_sources);
    yield* _controller.stream;
  }

  @override
  Future<List<Source>> listSources() async =>
      List<Source>.unmodifiable(_sources);

  @override
  Future<List<Source>> listEnabledSources() async =>
      _sources.where((source) => source.enabled).toList(growable: false);

  @override
  Future<Source?> findSourceById(String id) async {
    for (final source in _sources) {
      if (source.id == id) return source;
    }
    return null;
  }

  @override
  Future<void> setSourceEnabled(String id, bool enabled) async {
    setSourceEnabledCallCount += 1;
    await _setSourcesEnabled({id}, enabled, recordBatchCall: false);
  }

  @override
  Future<void> setSourcesEnabled(Iterable<String> ids, bool enabled) async {
    setSourcesEnabledCallCount += 1;
    await _setSourcesEnabled(ids, enabled);
  }

  Future<void> _setSourcesEnabled(
    Iterable<String> ids,
    bool enabled, {
    bool recordBatchCall = true,
  }) async {
    final idSet = ids.toSet();
    if (recordBatchCall) {
      lastSetSourcesEnabledIds = idSet;
      lastSetSourcesEnabledValue = enabled;
    }
    for (var i = 0; i < _sources.length; i++) {
      final source = _sources[i];
      if (idSet.contains(source.id)) {
        _sources[i] = source.copyWith(
          enabled: enabled,
          updatedAt: DateTime(2026, 6, 13, 12),
        );
      }
    }
    _emit();
  }

  @override
  Future<void> deleteSource(String id) async {
    deleteSourceCallCount += 1;
    await _deleteSources({id}, recordBatchCall: false);
  }

  @override
  Future<void> deleteSources(Iterable<String> ids) async {
    deleteSourcesCallCount += 1;
    await _deleteSources(ids);
  }

  Future<void> _deleteSources(
    Iterable<String> ids, {
    bool recordBatchCall = true,
  }) async {
    final idSet = ids.toSet();
    if (recordBatchCall) {
      lastDeleteSourcesIds = idSet;
    }
    _sources.removeWhere((source) => idSet.contains(source.id));
    _emit();
  }

  @override
  Future<SourceImportPersistResult> upsertImportedSources(
    SourceImportParseResult parseResult, {
    ExistingSourceStrategy existingStrategy = ExistingSourceStrategy.update,
  }) {
    throw UnimplementedError();
  }
}

class _FakeAppMessageService implements AppMessageService {
  @override
  void dismiss(String dedupeKey) {}

  @override
  void dismissAll() {}

  @override
  void error(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}

  @override
  void info(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}

  @override
  void loading({
    required String title,
    String? description,
    AppMessagePosition position = AppMessagePosition.center,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}

  @override
  void show(AppMessageRequest request) {}

  @override
  void showCenter({
    required String title,
    String? description,
    AppMessageKind kind = AppMessageKind.info,
    String? dedupeKey,
    bool replaceExisting = false,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
  }) {}

  @override
  void success(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}

  @override
  void warning(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {}
}
