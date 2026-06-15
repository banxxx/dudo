import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/rule_engine/rule_engine.dart';
import '../../sources/application/source_providers.dart';
import '../data/online_search_repository.dart';
import '../data/recent_search_repository.dart';
import '../domain/online_search_models.dart';

final ruleEngineProvider = Provider<RuleEngine>((ref) {
  return RuleEngine.create();
});

final onlineSearchRepositoryProvider = Provider<OnlineSearchRepository>((ref) {
  return OnlineSearchRepository.withRuleEngine(
    sourceRepository: ref.watch(sourceRepositoryProvider),
    ruleEngine: ref.watch(ruleEngineProvider),
  );
});

final recentSearchRepositoryProvider = Provider<RecentSearchRepository>((ref) {
  return DriftRecentSearchRepository(
      ref.watch(sourceRepositoryProvider).database);
});

final recentSearchesProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(recentSearchRepositoryProvider).watchRecentSearches();
});

final onlineSearchProvider = StreamProvider.autoDispose
    .family<OnlineSearchResponse, String>((ref, keyword) async* {
  final normalizedKeyword = keyword.trim();
  final enabledSources = await _requireData(ref.watch(enabledSourcesProvider));
  yield* ref
      .watch(onlineSearchRepositoryProvider)
      .searchSourcesStream(normalizedKeyword, enabledSources);
});

final enabledSourceCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref
      .watch(enabledSourcesProvider)
      .whenData((sources) => sources.length);
});

Future<T> _requireData<T>(AsyncValue<T> value) {
  return value.when(
    data: Future.value,
    loading: () => Completer<T>().future,
    error: (error, stackTrace) => Future<T>.error(error, stackTrace),
  );
}
