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
    FutureProvider.family<OnlineSearchResponse, String>((ref, keyword) {
  return ref.watch(onlineSearchRepositoryProvider).search(keyword);
});

final enabledSourceCountProvider = FutureProvider<int>((ref) async {
  final sources =
      await ref.watch(sourceRepositoryProvider).listEnabledSources();
  return sources.length;
});
