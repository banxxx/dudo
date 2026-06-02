import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/reading_stats_repository.dart';
import '../domain/reading_stats_models.dart';

final readingStatsTodayProvider = Provider<DateTime>((_) => DateTime.now());

final readingStatsRangeProvider = StateProvider<ReadingStatsRange>(
  (ref) => ReadingStatsRange.weekOf(ref.watch(readingStatsTodayProvider)),
);

final readingStatsRepositoryProvider = Provider<ReadingStatsRepository>((ref) {
  return ReadingStatsRepository(ref.watch(appDatabaseProvider));
});

final readingStatsSummaryProvider = FutureProvider<ReadingStatsSummary>((ref) {
  final range = ref.watch(readingStatsRangeProvider);
  return ref.watch(readingStatsRepositoryProvider).getSummary(range);
});
