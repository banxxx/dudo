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
            message: '书源规则无法解析',
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
      results: results,
      failures: failures,
      searchedSourceCount: searchedSourceCount,
      availableSourceCount: sources.length,
    );
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
