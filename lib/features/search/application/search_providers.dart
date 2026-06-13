import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/rule_engine/rule_engine.dart';
import '../../sources/application/source_providers.dart';
import '../data/online_search_repository.dart';
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

final onlineSearchProvider =
    FutureProvider.family<OnlineSearchResponse, String>((ref, keyword) async {
  final enabledSources = await _requireData(ref.watch(enabledSourcesProvider));
  return ref
      .watch(onlineSearchRepositoryProvider)
      .searchSources(keyword, enabledSources);
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
