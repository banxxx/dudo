import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../reading_stats/application/reading_stats_provider.dart';
import '../data/reading_goal_repository.dart';
import '../domain/reading_goal.dart';
import 'reading_goal_overview.dart';

final readingGoalRepositoryProvider = Provider<ReadingGoalRepository>((ref) {
  return ReadingGoalRepository(ref.watch(appDatabaseProvider));
});

/// The saved goal, or `null` when the user has not set one.
final readingGoalProvider = StreamProvider<ReadingGoal?>((ref) {
  return ref.watch(readingGoalRepositoryProvider).watchGoal();
});

/// The saved goal combined with this month's reading activity, or `null` when
/// the user has not set a goal.
final readingGoalOverviewProvider =
    FutureProvider<ReadingGoalOverview?>((ref) async {
  final goal = await ref.watch(readingGoalProvider.future);
  if (goal == null) return null;

  final stats = await ref.watch(readingMonthStatsProvider.future);
  final weekRhythm = await ref.watch(readingWeekRhythmProvider.future);

  return ReadingGoalOverview.build(
    goal: goal,
    stats: stats,
    weekRhythm: weekRhythm,
    now: ref.watch(readingStatsTodayProvider),
  );
});
