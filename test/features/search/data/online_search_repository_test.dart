import 'dart:convert';

import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/core/rule_engine/rule_engine.dart';
import 'package:dudo/features/search/data/online_search_repository.dart';
import 'package:dudo/features/sources/data/source_repository.dart';
import 'package:dudo/features/sources/domain/source_import_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeSourceRepository sourceRepository;

  setUp(() {
    sourceRepository = _FakeSourceRepository();
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

  test('returns a no-source response when no sources are enabled', () async {
    sourceRepository.sources = [
      _source(
        id: 'disabled-source',
        name: '未启用书源',
        enabled: false,
        rulesJson: _rulesJson(),
      ),
    ];

    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchRule: (_, __) async => throw StateError('should not search'),
    );

    final response = await repository.search('三体');

    expect(response.results, isEmpty);
    expect(response.failures, isEmpty);
    expect(response.searchedSourceCount, 0);
    expect(response.availableSourceCount, 0);
  });

  test('skips enabled sources without a searchUrl', () async {
    sourceRepository.sources = [
      _source(
        id: 'browse-only-source',
        name: '浏览书源',
        enabled: true,
        rulesJson: _rulesJson(searchUrl: ''),
      ),
    ];

    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchRule: (_, __) async => throw StateError('should not search'),
    );

    final response = await repository.search('三体');

    expect(response.results, isEmpty);
    expect(response.failures, isEmpty);
    expect(response.searchedSourceCount, 0);
    expect(response.availableSourceCount, 1);
  });

  test('searches enabled sources and maps source metadata onto results',
      () async {
    sourceRepository.sources = [
      _source(
        id: 'https://source.example',
        name: '测试书源',
        enabled: true,
        rulesJson: _rulesJson(),
      ),
    ];

    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchRule: (_, keyword) async => const [
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
    sourceRepository.sources = [
      _source(
        id: 'bad-source',
        name: '坏书源',
        enabled: true,
        rulesJson: '{not json}',
      ),
    ];

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
    sourceRepository.sources = [
      _source(
        id: 'failing-source',
        name: '失败书源',
        enabled: true,
        rulesJson: _rulesJson(url: 'https://failing.example'),
        sortOrder: 1,
      ),
      _source(
        id: 'good-source',
        name: '好书源',
        enabled: true,
        rulesJson: _rulesJson(),
        sortOrder: 2,
      ),
    ];

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

class _FakeSourceRepository implements SourceRepository {
  _FakeSourceRepository({List<Source>? sources}) : sources = sources ?? [];

  List<Source> sources;

  @override
  AppDatabase get database => throw UnimplementedError();

  @override
  Future<void> deleteSource(String id) => throw UnimplementedError();

  @override
  Future<void> deleteSources(Iterable<String> ids) =>
      throw UnimplementedError();

  @override
  Future<List<Source>> listEnabledSources() async {
    final enabledSources = sources.where((source) => source.enabled).toList()
      ..sort((a, b) {
        final sortOrder = b.sortOrder.compareTo(a.sortOrder);
        if (sortOrder != 0) return sortOrder;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return enabledSources;
  }

  @override
  Future<Source?> findSourceById(String id) async {
    for (final source in sources) {
      if (source.id == id) return source;
    }
    return null;
  }

  @override
  Future<List<Source>> listSources() => throw UnimplementedError();

  @override
  Future<void> setSourceEnabled(String id, bool enabled) =>
      throw UnimplementedError();

  @override
  Future<void> setSourcesEnabled(Iterable<String> ids, bool enabled) =>
      throw UnimplementedError();

  @override
  Future<SourceImportPersistResult> upsertImportedSources(
    SourceImportParseResult parseResult, {
    ExistingSourceStrategy existingStrategy = ExistingSourceStrategy.update,
  }) =>
      throw UnimplementedError();

  @override
  Stream<List<Source>> watchSources() => throw UnimplementedError();
}

Source _source({
  required String id,
  required String name,
  required bool enabled,
  required String rulesJson,
  int sortOrder = 0,
}) {
  final now = DateTime(2026, 6, 13);
  return Source(
    id: id,
    name: name,
    url: id,
    enabled: enabled,
    rulesJson: rulesJson,
    sortOrder: sortOrder,
    createdAt: now,
    updatedAt: now,
  );
}

String _rulesJson({
  String url = 'https://source.example',
  String? searchUrl,
}) {
  return jsonEncode({
    'bookSourceUrl': url,
    'bookSourceName': '测试书源',
    'searchUrl': searchUrl ?? '$url/search?q={{key}}',
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
