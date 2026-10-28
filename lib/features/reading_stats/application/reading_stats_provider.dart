import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/reading_session_recorder.dart';
import '../data/reading_stats_repository.dart';
import '../domain/reading_stats_models.dart';

final readingStatsTodayProvider = Provider<DateTime>((_) => DateTime.now());

final readingStatsRangeProvider = StateProvider<ReadingStatsRange>(
  (ref) => ReadingStatsRange.weekOf(ref.watch(readingStatsTodayProvider)),
);

final readingStatsRepositoryProvider = Provider<ReadingStatsRepository>((ref) {
  return ReadingStatsRepository(ref.watch(appDatabaseProvider));
});

final readingSessionRecorderProvider = Provider<ReadingSessionRecorder>((ref) {
  return ReadingSessionRecorder(ref.watch(appDatabaseProvider));
});

/// Emits whenever a reading session is stored so summaries recompute.
final readingSessionsChangedProvider = StreamProvider<void>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.select(database.readingSessions).watch().map((_) {});
});

final readingStatsSummaryProvider = FutureProvider<ReadingStatsSummary>((ref) {
  ref.watch(readingSessionsChangedProvider);
  final range = ref.watch(readingStatsRangeProvider);
  return ref.watch(readingStatsRepositoryProvider).getSummary(range);
});

/// This calendar week's daily rhythm, independent of the range selected on the
/// stats screen. Shared by the home card and the reading goal overview.
final readingWeekRhythmProvider =
    FutureProvider<List<ReadingRhythmStat>>((ref) async {
  ref.watch(readingSessionsChangedProvider);
  final summary = await ref.watch(readingStatsRepositoryProvider).getSummary(
        ReadingStatsRange.weekOf(ref.watch(readingStatsTodayProvider)),
      );
  return summary.rhythmStats;
});

/// This month's aggregate, used by the reading goal.
final readingMonthStatsProvider =
    FutureProvider<ReadingMonthStats>((ref) async {
  ref.watch(readingSessionsChangedProvider);
  return ref.watch(readingStatsRepositoryProvider).getMonthStats(
        ref.watch(readingStatsTodayProvider),
      );
});
