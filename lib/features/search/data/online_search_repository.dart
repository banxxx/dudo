import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/rule_engine/legado/common/legado_trace.dart';
import '../../../core/rule_engine/models/source_rule.dart';
import '../../../core/rule_engine/rule_engine.dart' as engine;
import '../../../core/utils/logger.dart';
import '../../sources/data/source_repository.dart';
import '../domain/online_search_models.dart';

typedef RuleSearch = Future<List<engine.SearchResult>> Function(
  SourceRule source,
  String keyword,
);

class OnlineSearchRepository {
  const OnlineSearchRepository({
    required this.sourceRepository,
    required this.searchRule,
  });

  factory OnlineSearchRepository.withRuleEngine({
    required SourceRepository sourceRepository,
    required engine.RuleEngine ruleEngine,
  }) {
    return OnlineSearchRepository(
      sourceRepository: sourceRepository,
      searchRule: ruleEngine.search,
    );
  }

  final SourceRepository sourceRepository;
  final RuleSearch searchRule;

  Future<OnlineSearchResponse> search(String keyword) async {
    final sources = await sourceRepository.listEnabledSources();
    return searchSources(keyword, sources);
  }

  Future<OnlineSearchResponse> searchSources(
    String keyword,
    List<Source> sources,
  ) async {
    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      return const OnlineSearchResponse(
        results: [],
        failures: [],
        searchedSourceCount: 0,
        availableSourceCount: 0,
      );
    }

    final results = <OnlineSearchBookResult>[];
    final failures = <OnlineSearchFailure>[];
    var searchedSourceCount = 0;

    log.i(
      '[online-search] start keyword="$normalizedKeyword" '
      'enabledSources=${sources.length}',
    );

    for (var index = 0; index < sources.length; index++) {
      final source = sources[index];
      final rule = _parseSourceRule(source.rulesJson);
      if (rule == null) {
        log.w(
          '[online-search] source ${index + 1}/${sources.length} '
          'parse failed name="${source.name}" id="${source.id}"',
        );
        failures.add(
          OnlineSearchFailure(
            sourceId: source.id,
            sourceName: source.name,
            message: '\u4e66\u6e90\u89c4\u5219\u65e0\u6cd5\u89e3\u6790',
          ),
        );
        continue;
      }
      if (rule.search?.searchUrl == null ||
          rule.search!.searchUrl!.trim().isEmpty) {
        log.d(
          '[online-search] source ${index + 1}/${sources.length} '
          'skipped empty searchUrl name="${source.name}" '
          'id="${source.id}" base="${rule.url}"',
        );
        continue;
      }

      searchedSourceCount += 1;
      log.i(
        '[online-search] source ${index + 1}/${sources.length} '
        'searching name="${source.name}" id="${source.id}" '
        'base="${rule.url}" rawSearchUrl="${rule.search!.searchUrl}"',
      );
      try {
        final sourceResults = await searchRule(rule, normalizedKeyword);
        log.i(
          '[online-search] source ${index + 1}/${sources.length} '
          'finished name="${source.name}" resultCount=${sourceResults.length}',
        );
        results.addAll(
          sourceResults.map(
            (result) => OnlineSearchBookResult(
              sourceId: source.id,
              sourceName: source.name,
              name: result.name,
              author: result.author,
              intro: result.intro,
              coverUrl: result.coverUrl,
              bookUrl: result.bookUrl,
              kind: result.kind,
              lastChapter: result.lastChapter,
              wordCount: result.wordCount,
              origins: [
                OnlineSearchOrigin(
                  sourceId: source.id,
                  sourceName: source.name,
                  bookUrl: result.bookUrl,
                ),
              ],
            ),
          ),
        );
      } catch (error) {
        final diagnostics = _diagnosticsFor(error);
        log.w(
          '[online-search] source ${index + 1}/${sources.length} '
          'failed name="${source.name}" id="${source.id}" '
          'diagnostics=${diagnostics.join(' | ')} error=$error',
        );
        failures.add(
          OnlineSearchFailure(
            sourceId: source.id,
            sourceName: source.name,
            message: error.toString(),
            diagnostics: diagnostics,
          ),
        );
      }
    }

    return OnlineSearchResponse(
      results: _mergeAndRankResults(results, normalizedKeyword),
      failures: failures,
      searchedSourceCount: searchedSourceCount,
      availableSourceCount: sources.length,
    );
  }

  List<OnlineSearchBookResult> _mergeAndRankResults(
    List<OnlineSearchBookResult> results,
    String keyword,
  ) {
    final mergedByBook = <String, _MergedSearchResult>{};
    for (final result in results) {
      final key = '${result.name}\u0000${result.author}';
      final existing = mergedByBook[key];
      if (existing == null) {
        mergedByBook[key] = _MergedSearchResult(result, mergedByBook.length);
      } else {
        existing.add(result);
      }
    }

    final equal = <_MergedSearchResult>[];
    final tags = <_MergedSearchResult>[];
    final contains = <_MergedSearchResult>[];
    final other = <_MergedSearchResult>[];
    for (final result in mergedByBook.values) {
      final book = result.result;
      if (book.name == keyword || book.author == keyword) {
        equal.add(result);
      } else if (book.kind?.contains(keyword) == true) {
        tags.add(result);
      } else if (book.name.contains(keyword) || book.author.contains(keyword)) {
        contains.add(result);
      } else {
        other.add(result);
      }
    }

    int compareMerged(_MergedSearchResult a, _MergedSearchResult b) {
      final sourceCount = b.sourceCount.compareTo(a.sourceCount);
      if (sourceCount != 0) return sourceCount;
      return a.index.compareTo(b.index);
    }

    equal.sort(compareMerged);
    tags.sort(compareMerged);
    contains.sort(compareMerged);
    return [
      ...equal,
      ...tags,
      ...contains,
      ...other,
    ].map((result) => result.displayResult).toList(growable: false);
  }

  SourceRule? _parseSourceRule(String rulesJson) {
    try {
      final decoded = jsonDecode(rulesJson);
      if (decoded is! Map) return null;
      return SourceRule.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  List<String> _diagnosticsFor(Object error) {
    if (error is! LegadoRuntimeException) return const [];
    return [
      if (error.stage != null) 'stage:${error.stage}',
      ...?error.trace?.events,
    ];
  }
}

class _MergedSearchResult {
  _MergedSearchResult(this.result, this.index)
      : _sourceNames = <String>{},
        _sourceIds = <String>{},
        _origins = <OnlineSearchOrigin>[] {
    _addOrigins(result);
  }

  OnlineSearchBookResult result;
  final int index;
  final Set<String> _sourceNames;
  final Set<String> _sourceIds;
  final List<OnlineSearchOrigin> _origins;

  int get sourceCount => _sourceIds.length;

  void add(OnlineSearchBookResult next) {
    _addOrigins(next);
    final currentBookUrl = result.bookUrl?.trim();
    final nextBookUrl = next.bookUrl?.trim();
    if ((currentBookUrl == null || currentBookUrl.isEmpty) &&
        nextBookUrl != null &&
        nextBookUrl.isNotEmpty) {
      result = next;
    }
  }

  void _addOrigins(OnlineSearchBookResult next) {
    final origins = next.origins.isEmpty
        ? [
            OnlineSearchOrigin(
              sourceId: next.sourceId,
              sourceName: next.sourceName,
              bookUrl: next.bookUrl,
            ),
          ]
        : next.origins;
    for (final origin in origins) {
      if (!_sourceIds.add(origin.sourceId)) continue;
      _sourceNames.add(origin.sourceName);
      _origins.add(origin);
    }
  }

  OnlineSearchBookResult get displayResult => OnlineSearchBookResult(
        sourceId: result.sourceId,
        sourceName: _sourceNames.join('\u3001'),
        name: result.name,
        author: result.author,
        intro: result.intro,
        coverUrl: result.coverUrl,
        bookUrl: result.bookUrl,
        kind: result.kind,
        lastChapter: result.lastChapter,
        wordCount: result.wordCount,
        origins: List.unmodifiable(_origins),
      );
}
