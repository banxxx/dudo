import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/core/rule_engine/rule_engine.dart';
import 'package:dudo/features/search/data/online_search_repository.dart';
import 'package:dudo/features/sources/data/source_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SourceRepository sourceRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    sourceRepository = SourceRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('returns an empty response for blank keywords', () async {
    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchRule: (_, __) async => throw StateError('should not search'),
    );

    final response = await repository.search('   ');

    expect(response.results, isEmpty);
    expect(response.failures, isEmpty);
    expect(response.searchedSourceCount, 0);
    expect(response.availableSourceCount, 0);
  });

  test('searches enabled sources and maps source metadata onto results',
      () async {
    await _insertSource(
      database,
      id: 'https://source.example',
      name: '测试书源',
      enabled: true,
      rulesJson: _rulesJson(),
    );

    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchRule: (_, keyword) async => [
        SearchResult(
          name: '三体',
          author: '刘慈欣',
          intro: '文明在宇宙尺度中的回响。',
          coverUrl: 'https://source.example/cover.jpg',
          bookUrl: 'https://source.example/book/1',
        ),
      ],
    );

    final response = await repository.search('三体');

    expect(response.availableSourceCount, 1);
    expect(response.searchedSourceCount, 1);
    expect(response.failures, isEmpty);
    expect(response.results, hasLength(1));
    expect(response.results.single.sourceId, 'https://source.example');
    expect(response.results.single.sourceName, '测试书源');
    expect(response.results.single.name, '三体');
  });

  test('records invalid rulesJson as a source failure', () async {
    await _insertSource(
      database,
      id: 'bad-source',
      name: '坏书源',
      enabled: true,
      rulesJson: '{not json}',
    );

    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchRule: (_, __) async => [],
    );

    final response = await repository.search('三体');

    expect(response.results, isEmpty);
    expect(response.failures, hasLength(1));
    expect(response.failures.single.sourceId, 'bad-source');
    expect(response.failures.single.message, '书源规则无法解析');
  });

  test('keeps successful source results when another source fails', () async {
    await _insertSource(
      database,
      id: 'good-source',
      name: '好书源',
      enabled: true,
      rulesJson: _rulesJson(),
      sortOrder: 2,
    );
    await _insertSource(
      database,
      id: 'failing-source',
      name: '失败书源',
      enabled: true,
      rulesJson: _rulesJson(url: 'https://failing.example'),
      sortOrder: 1,
    );

    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchRule: (source, _) async {
        if (source.id == 'https://failing.example') {
          throw Exception('network failed');
        }
        return const [SearchResult(name: '三体', author: '刘慈欣')];
      },
    );

    final response = await repository.search('三体');

    expect(response.results, hasLength(1));
    expect(response.failures, hasLength(1));
    expect(response.failures.single.sourceName, '失败书源');
  });
}

Future<void> _insertSource(
  AppDatabase database, {
  required String id,
  required String name,
  required bool enabled,
  required String rulesJson,
  int sortOrder = 0,
}) async {
  await database.into(database.sources).insert(
        SourcesCompanion.insert(
          id: id,
          name: name,
          url: id,
          enabled: Value(enabled),
          rulesJson: rulesJson,
          sortOrder: Value(sortOrder),
        ),
      );
}

String _rulesJson({String url = 'https://source.example'}) {
  return jsonEncode({
    'bookSourceUrl': url,
    'bookSourceName': '测试书源',
    'searchUrl': '$url/search?q={{key}}',
    'ruleSearch': {
      'bookList': '.book',
      'name': '.name@text',
      'author': '.author@text',
      'intro': '.intro@text',
      'coverUrl': '.cover@src',
      'bookUrl': '.book@href',
    },
  });
}
