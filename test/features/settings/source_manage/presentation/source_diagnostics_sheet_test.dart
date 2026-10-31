import 'dart:convert';

import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/settings/source_manage/presentation/source_diagnostics_sheet.dart';
import 'package:dudo/features/sources/application/source_providers.dart';
import 'package:dudo/features/sources/data/source_repository.dart';
import 'package:dudo/features/sources/domain/source_import_models.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows diagnostics and deletes broken sources', (tester) async {
    final repository = _FakeSourceRepository([
      _source(id: 'valid', name: '正常源', rules: _validRules()),
      _source(id: 'broken', name: '坏源', rules: 'not-json'),
      _source(
        id: 'searchless',
        name: '无搜索源',
        rules: {
          ..._validRules(),
          'searchUrl': null,
        },
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sourceRepositoryProvider.overrideWithValue(repository),
          appMessageServiceProvider.overrideWithValue(_FakeAppMessageService()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SourceDiagnosticsSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('规则诊断'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('失效'), findsWidgets);
    expect(find.text('需注意'), findsOneWidget);
    expect(find.text('问题明细'), findsOneWidget);
    expect(find.text('2 项'), findsOneWidget);
    expect(find.text('坏源'), findsOneWidget);
    expect(find.text('无搜索源'), findsOneWidget);
    expect(find.text('删除 1 个失效书源'), findsOneWidget);

    await tester.tap(find.text('删除 1 个失效书源'));
    await tester.pumpAndSettle();
    expect(find.text('删除失效书源？'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(repository.lastDeletedIds, {'broken'});
    expect(find.text('坏源'), findsNothing);
    expect(find.text('删除 1 个失效书源'), findsNothing);
  });
}

Map<String, Object?> _validRules() {
  return {
    'bookSourceName': '正常源',
    'bookSourceUrl': 'https://valid.example.com',
    'searchUrl': 'https://valid.example.com/search?q={{key}}',
    'ruleSearch': {
      'bookList': r'$.items',
      'name': r'$.name',
      'bookUrl': r'$.url',
    },
    'ruleBookInfo': {'name': r'$.name'},
    'ruleToc': {'chapterList': r'$.chapters'},
    'ruleContent': {'content': r'$.content'},
  };
}

Source _source({
  required String id,
  required String name,
  required Object rules,
}) {
  final now = DateTime(2026, 6, 13);
  return Source(
    id: id,
    name: name,
    url: 'https://$id.example.com',
    enabled: true,
    sourceType: 0,
    rulesJson: rules is String ? rules : jsonEncode(rules),
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeSourceRepository implements SourceRepository {
  _FakeSourceRepository(this._sources);

  final List<Source> _sources;
  Set<String> lastDeletedIds = const {};

  @override
  Future<List<Source>> listSources() async =>
      List<Source>.unmodifiable(_sources);

  @override
  Future<void> deleteSources(Iterable<String> ids) async {
    final idSet = ids.toSet();
    lastDeletedIds = idSet;
    _sources.removeWhere((source) => idSet.contains(source.id));
  }

  @override
  Future<SourceImportPersistResult> upsertImportedSources(
    SourceImportParseResult parseResult, {
    ExistingSourceStrategy existingStrategy = ExistingSourceStrategy.update,
  }) {
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAppMessageService implements AppMessageService {
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
