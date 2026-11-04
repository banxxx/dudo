import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/reading_goal/application/reading_goal_overview.dart';
import 'package:dudo/features/reading_goal/application/reading_goal_providers.dart';
import 'package:dudo/features/reading_goal/data/reading_goal_repository.dart';
import 'package:dudo/features/reading_goal/domain/reading_goal.dart';
import 'package:dudo/features/reading_goal/presentation/reading_goal_page.dart';
import 'package:dudo/features/reading_stats/application/reading_stats_provider.dart';
import 'package:dudo/features/reading_stats/domain/reading_stats_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

void main() {
  // Windows ships SQLite as winsqlite3.dll; the test runner does not have
  // sqlite3.dll on PATH like a built Flutter app does.
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }

  testWidgets('re-opening a goal never flashes the overview loading view',
      (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final goals = StreamController<ReadingGoal?>.broadcast(sync: true);
    addTearDown(goals.close);
    final repository = _FakeGoalRepository(goals, database);

    final pendingOverview = Completer<ReadingGoalOverview?>();
    addTearDown(() {
      if (!pendingOverview.isCompleted) pendingOverview.complete(null);
    });
    var overviewBuilds = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingGoalRepositoryProvider.overrideWithValue(repository),
          readingGoalProvider.overrideWith((_) => goals.stream),
          readingGoalOverviewProvider.overrideWith((ref) async {
            final goal = await ref.watch(readingGoalProvider.future);
            if (goal == null) return null;
            overviewBuilds++;
            // The first build has the closed goal's overview ready; the build
            // triggered by re-opening stays pending so the test can inspect
            // the frame in between.
            if (overviewBuilds == 1) return _overview(goal);
            return pendingOverview.future;
          }),
          readingStatsTodayProvider.overrideWithValue(DateTime(2026, 11, 4)),
        ],
        child: const MaterialApp(home: ReadingGoalPage()),
      ),
    );

    goals.add(ReadingGoal.defaults().copyWith(enabled: false));
    await tester.pumpAndSettle();
    expect(find.text('开启目标'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reading-goal-close-action')));
    await tester.pump();
    await tester.pump();

    // The refreshed overview is still loading, so the page stays on the edit
    // view instead of handing over to the blank loading placeholder.
    expect(find.text('编辑目标'), findsOneWidget);
    expect(find.text('本月目标进度'), findsNothing);

    pendingOverview.complete(_overview(ReadingGoal.defaults()));
    await tester.pumpAndSettle();

    expect(find.text('编辑目标'), findsNothing);
    expect(find.text('本月目标进度'), findsOneWidget);
  });
}

ReadingGoalOverview _overview(ReadingGoal goal) {
  final now = DateTime(2026, 11, 4);
  return ReadingGoalOverview.build(
    goal: goal,
    stats: ReadingMonthStats(
      month: DateTime(2026, 11),
      totalSeconds: 6 * 3600,
      chaptersRead: 2,
      charactersRead: 28000,
      recordedDays: 3,
      daysInMonth: 30,
      streakDays: 3,
    ),
    weekRhythm: [
      for (var i = 0; i < 7; i++)
        ReadingRhythmStat(
          label: '一二三四五六日'[i],
          minutes: 10 + i,
          start: now,
          end: now,
        ),
    ],
    now: now,
  );
}

/// Replays saves into the test's goal stream without touching SQLite.
class _FakeGoalRepository extends ReadingGoalRepository {
  _FakeGoalRepository(this._goals, AppDatabase database) : super(database);

  final StreamController<ReadingGoal?> _goals;

  ReadingGoal? _goal;

  @override
  Future<ReadingGoal?> loadGoal() async => _goal;

  @override
  Future<void> saveGoal(ReadingGoal goal) async {
    _goal = goal;
    _goals.add(goal);
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    final goal = _goal;
    if (goal == null) return;
    await saveGoal(goal.copyWith(enabled: enabled));
  }
}
