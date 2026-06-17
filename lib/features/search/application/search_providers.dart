import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/rule_engine/rule_engine.dart';
import '../../../core/rule_engine/legado/url/persistent_cookie_store.dart';
import '../../sources/application/source_providers.dart';
import '../data/online_search_repository.dart';
import '../data/recent_search_repository.dart';
import '../domain/online_search_models.dart';

final legadoCookieStoreProvider = FutureProvider<PersistentLegadoCookieStore>(
  (ref) async {
    final store = PersistentLegadoCookieStore(
      database: ref.watch(appDatabaseProvider),
    );
    await store.init();
    return store;
  },
);

final ruleEngineProvider = Provider<RuleEngine>((ref) {
  final cookieStore = ref.watch(legadoCookieStoreProvider).valueOrNull;
  return RuleEngine.create(cookieStore: cookieStore);
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
  await _requireData(ref.watch(legadoCookieStoreProvider));
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
