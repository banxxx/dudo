import 'dart:convert';

import '../../../core/rule_engine/models/source_rule.dart';
import '../../../core/rule_engine/rule_engine.dart' as engine;
import '../../sources/data/source_repository.dart';
import '../../../core/database/app_database.dart';
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

    for (final source in sources) {
      final rule = _parseSourceRule(source.rulesJson);
      if (rule == null) {
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
        continue;
      }

      searchedSourceCount += 1;
      try {
        final sourceResults = await searchRule(rule, normalizedKeyword);
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
        failures.add(
          OnlineSearchFailure(
            sourceId: source.id,
            sourceName: source.name,
            message: error.toString(),
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
}
