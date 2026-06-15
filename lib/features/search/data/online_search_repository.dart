import 'dart:async';
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
    this.searchConcurrency = defaultSearchConcurrency,
    this.sourceTimeout = defaultSourceTimeout,
  });

  static const defaultSearchConcurrency = 9;
  static const defaultSourceTimeout = Duration(seconds: 30);

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
  final int searchConcurrency;
  final Duration sourceTimeout;

  Future<OnlineSearchResponse> search(String keyword) async {
    final sources = await sourceRepository.listEnabledSources();
    return searchSources(keyword, sources);
  }

  Future<OnlineSearchResponse> searchSources(
    String keyword,
    List<Source> sources,
  ) async {
    OnlineSearchResponse? latest;
    await for (final response in searchSourcesStream(keyword, sources)) {
      latest = response;
    }
    return latest ??
        const OnlineSearchResponse(
          results: [],
          failures: [],
          searchedSourceCount: 0,
          availableSourceCount: 0,
        );
  }

  Stream<OnlineSearchResponse> searchSourcesStream(
    String keyword,
    List<Source> sources,
  ) async* {
    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      yield const OnlineSearchResponse(
        results: [],
        failures: [],
        searchedSourceCount: 0,
        availableSourceCount: 0,
      );
      return;
    }

    log.i(
      '[online-search] start keyword="$normalizedKeyword" '
      'enabledSources=${sources.length}',
    );

    final tasks = <_SourceSearchTask>[];
    final immediateFailures = <_OrderedFailure>[];
    for (var index = 0; index < sources.length; index++) {
      final source = sources[index];
      final rule = _parseSourceRule(source.rulesJson);
      if (rule == null) {
        log.w(
          '[online-search] source ${index + 1}/${sources.length} '
          'parse failed name="${source.name}" id="${source.id}"',
        );
        immediateFailures.add(
          _OrderedFailure(
            index,
            OnlineSearchFailure(
              sourceId: source.id,
              sourceName: source.name,
              message: '\u4e66\u6e90\u89c4\u5219\u65e0\u6cd5\u89e3\u6790',
            ),
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

      tasks.add(
        _SourceSearchTask(
          index: index,
          totalSources: sources.length,
          source: source,
          rule: rule,
        ),
      );
    }

    final searchableSourceCount = tasks.length;
    if (tasks.isEmpty) {
      yield OnlineSearchResponse(
        results: const [],
        failures: _orderedFailures(immediateFailures),
        searchedSourceCount: 0,
        availableSourceCount: sources.length,
      );
      return;
    }

    final maxConcurrency = searchConcurrency.clamp(1, searchableSourceCount);
    final active = <int, Future<_SourceSearchOutcome>>{};
    final completedOutcomes = <int, _SourceSearchOutcome>{};
    var nextTaskIndex = 0;

    void startNextTasks() {
      while (active.length < maxConcurrency && nextTaskIndex < tasks.length) {
        final task = tasks[nextTaskIndex++];
        active[task.index] = _searchOneSource(task, normalizedKeyword);
      }
    }

    OnlineSearchResponse currentResponse({required bool isSearching}) {
      final orderedOutcomes = completedOutcomes.values.toList(growable: false)
        ..sort((a, b) => a.index.compareTo(b.index));
      final results = <OnlineSearchBookResult>[];
      final failures = <_OrderedFailure>[...immediateFailures];
      for (final outcome in orderedOutcomes) {
        results.addAll(outcome.results);
        if (outcome.failure != null) {
          failures.add(_OrderedFailure(outcome.index, outcome.failure!));
        }
      }
      return OnlineSearchResponse(
        results: _mergeAndRankResults(results, normalizedKeyword),
        failures: _orderedFailures(failures),
        searchedSourceCount: searchableSourceCount,
        availableSourceCount: sources.length,
        completedSourceCount: completedOutcomes.length,
        isSearching: isSearching,
      );
    }

    startNextTasks();
    while (active.isNotEmpty) {
      final outcome = await Future.any(active.values);
      active.remove(outcome.index);
      completedOutcomes[outcome.index] = outcome;
      startNextTasks();
      yield currentResponse(isSearching: active.isNotEmpty);
    }
  }

  Future<_SourceSearchOutcome> _searchOneSource(
    _SourceSearchTask task,
    String normalizedKeyword,
  ) async {
    final source = task.source;
    final rule = task.rule;
    log.i(
      '[online-search] source ${task.index + 1}/${task.totalSources} '
      'searching name="${source.name}" id="${source.id}" '
      'base="${rule.url}" rawSearchUrl="${rule.search!.searchUrl}"',
    );
    try {
      final sourceResults =
          await searchRule(rule, normalizedKeyword).timeout(sourceTimeout);
      log.i(
        '[online-search] source ${task.index + 1}/${task.totalSources} '
        'finished name="${source.name}" resultCount=${sourceResults.length}',
      );
      return _SourceSearchOutcome(
        index: task.index,
        results: sourceResults
            .map(
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
            )
            .toList(growable: false),
      );
    } catch (error) {
      final diagnostics = _diagnosticsFor(error);
      log.w(
        '[online-search] source ${task.index + 1}/${task.totalSources} '
        'failed name="${source.name}" id="${source.id}" '
        'diagnostics=${diagnostics.join(' | ')} error=$error',
      );
      return _SourceSearchOutcome(
        index: task.index,
        failure: OnlineSearchFailure(
          sourceId: source.id,
          sourceName: source.name,
          message: error is TimeoutException
              ? '\u4e66\u6e90\u641c\u7d22\u8d85\u65f6\uff08${sourceTimeout.inSeconds}s\uff09'
              : error.toString(),
          diagnostics: diagnostics,
        ),
      );
    }
  }

  List<OnlineSearchFailure> _orderedFailures(List<_OrderedFailure> failures) {
    final sorted = failures.toList(growable: false)
      ..sort((a, b) => a.index.compareTo(b.index));
    return sorted.map((failure) => failure.failure).toList(growable: false);
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

class _SourceSearchTask {
  const _SourceSearchTask({
    required this.index,
    required this.totalSources,
    required this.source,
    required this.rule,
  });

  final int index;
  final int totalSources;
  final Source source;
  final SourceRule rule;
}

class _SourceSearchOutcome {
  const _SourceSearchOutcome({
    required this.index,
    this.results = const [],
    this.failure,
  });

  final int index;
  final List<OnlineSearchBookResult> results;
  final OnlineSearchFailure? failure;
}

class _OrderedFailure {
  const _OrderedFailure(this.index, this.failure);

  final int index;
  final OnlineSearchFailure failure;
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
