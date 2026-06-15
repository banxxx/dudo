import 'dart:async';
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

  test('searches enabled sources in Legado customOrder order', () async {
    sourceRepository.sources = [
      _source(
        id: 'late-source',
        name: '后搜书源',
        enabled: true,
        rulesJson: _rulesJson(url: 'https://late.example'),
        sortOrder: 20,
      ),
      _source(
        id: 'early-source',
        name: '先搜书源',
        enabled: true,
        rulesJson: _rulesJson(url: 'https://early.example'),
        sortOrder: -10,
      ),
    ];
    final searched = <String>[];

    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchRule: (source, _) async {
        searched.add(source.id);
        return const [];
      },
    );

    await repository.search('三体');

    expect(searched, ['https://early.example', 'https://late.example']);
  });

  test('merges same name and author across sources like Legado', () async {
    sourceRepository.sources = [
      _source(
        id: 'source-a',
        name: '书源 A',
        enabled: true,
        rulesJson: _rulesJson(url: 'https://a.example'),
        sortOrder: 1,
      ),
      _source(
        id: 'source-b',
        name: '书源 B',
        enabled: true,
        rulesJson: _rulesJson(url: 'https://b.example'),
        sortOrder: 2,
      ),
    ];

    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchRule: (source, _) async {
        if (source.id == 'https://a.example') {
          return const [
            SearchResult(
              name: '三体',
              author: '刘慈欣',
              bookUrl: 'https://a.example/book/1',
            ),
          ];
        }
        return const [
          SearchResult(
            name: '三体',
            author: '刘慈欣',
            bookUrl: 'https://b.example/book/1',
          ),
          SearchResult(name: '三体前传', author: '刘慈欣'),
        ];
      },
    );

    final response = await repository.search('三体');

    expect(response.results, hasLength(2));
    expect(response.results.first.name, '三体');
    expect(response.results.first.sourceId, 'source-a');
    expect(response.results.first.sourceName, '书源 A、书源 B');
    expect(response.results.first.bookUrl, 'https://a.example/book/1');
    expect(response.results.last.name, '三体前传');
  });
  test('ranks kind matches before loose matches and keeps origins', () async {
    sourceRepository.sources = [
      _source(
        id: 'source-a',
        name: 'Source A',
        enabled: true,
        rulesJson: _rulesJson(url: 'https://a.example'),
        sortOrder: 1,
      ),
      _source(
        id: 'source-b',
        name: 'Source B',
        enabled: true,
        rulesJson: _rulesJson(url: 'https://b.example'),
        sortOrder: 2,
      ),
    ];

    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchRule: (source, _) async {
        if (source.id == 'https://a.example') {
          return const [
            SearchResult(
              name: 'Other',
              author: 'Someone',
              kind: 'target tag',
              bookUrl: 'https://a.example/other',
            ),
            SearchResult(
              name: 'Target Story',
              author: 'Someone',
              bookUrl: 'https://a.example/target',
            ),
          ];
        }
        return const [
          SearchResult(
            name: 'Other',
            author: 'Someone',
            kind: 'target tag',
            bookUrl: 'https://b.example/other',
          ),
        ];
      },
    );

    final response = await repository.search('target');

    expect(response.results, hasLength(2));
    expect(response.results.first.name, 'Other');
    expect(response.results.first.origins, hasLength(2));
    expect(response.results.first.sourceName, 'Source A、Source B');
    expect(response.results.last.name, 'Target Story');
  });

  test('searches sources concurrently with a Legado-like concurrency cap',
      () async {
    sourceRepository.sources = [
      for (var index = 0; index < 4; index++)
        _source(
          id: 'source-$index',
          name: 'Source $index',
          enabled: true,
          rulesJson: _rulesJson(url: 'https://source-$index.example'),
          sortOrder: index,
        ),
    ];
    var active = 0;
    var maxActive = 0;

    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchConcurrency: 2,
      searchRule: (source, _) async {
        active += 1;
        maxActive = active > maxActive ? active : maxActive;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        active -= 1;
        return [
          SearchResult(name: source.id, author: 'Author'),
        ];
      },
    );

    final response = await repository.search('target');

    expect(response.results, hasLength(4));
    expect(maxActive, 2);
  });

  test('times out one slow source without blocking successful sources',
      () async {
    sourceRepository.sources = [
      _source(
        id: 'slow-source',
        name: 'Slow Source',
        enabled: true,
        rulesJson: _rulesJson(url: 'https://slow.example'),
        sortOrder: 1,
      ),
      _source(
        id: 'fast-source',
        name: 'Fast Source',
        enabled: true,
        rulesJson: _rulesJson(url: 'https://fast.example'),
        sortOrder: 2,
      ),
    ];
    final never = Completer<List<SearchResult>>();

    final repository = OnlineSearchRepository(
      sourceRepository: sourceRepository,
      sourceTimeout: const Duration(milliseconds: 20),
      searchRule: (source, _) {
        if (source.id == 'https://slow.example') {
          return never.future;
        }
        return Future.value(
          const [SearchResult(name: 'Target', author: 'Author')],
        );
      },
    );

    final response = await repository.search('target');

    expect(response.results, hasLength(1));
    expect(response.results.single.sourceName, 'Fast Source');
    expect(response.failures, hasLength(1));
    expect(response.failures.single.sourceName, 'Slow Source');
    expect(response.failures.single.message, contains('超时'));
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
        final sortOrder = a.sortOrder.compareTo(b.sortOrder);
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
