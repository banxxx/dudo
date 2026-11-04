import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/reading_goal/data/reading_goal_repository.dart';
import 'package:dudo/features/reading_goal/domain/reading_goal.dart';
import 'package:dudo/features/reading_goal/domain/reading_goal_method.dart';
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

  late AppDatabase database;
  late ReadingGoalRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ReadingGoalRepository(database);
  });

  tearDown(() => database.close());

  test('returns null when no goal has been saved', () async {
    expect(await repository.loadGoal(), isNull);
    expect(await repository.watchGoal().first, isNull);
  });

  test('saves and reloads the goal', () async {
    const goal = ReadingGoal(
      method: GoalMethod.chapters,
      value: 30,
      reminderEnabled: false,
      reminderMinutes: 8 * 60 + 15,
      repeatDays: {0, 2, 4},
      rules: [true, false, true],
    );

    await repository.saveGoal(goal);

    final loaded = (await repository.loadGoal())!;
    expect(loaded.method, GoalMethod.chapters);
    expect(loaded.value, 30);
    expect(loaded.reminderEnabled, isFalse);
    expect(loaded.reminderMinutes, 8 * 60 + 15);
    expect(loaded.repeatDays, {0, 2, 4});
    expect(loaded.rules, [true, false, true]);
    expect(loaded.enabled, isTrue);
  });

  test('the watched goal updates after saving', () async {
    await repository.saveGoal(
      const ReadingGoal(
        method: GoalMethod.pages,
        value: 600,
        reminderEnabled: true,
        reminderMinutes: 21 * 60 + 30,
        repeatDays: {6},
        rules: [false, false, false],
      ),
    );

    final goal = (await repository.watchGoal().first)!;
    expect(goal.method, GoalMethod.pages);
    expect(goal.value, 600);
    expect(goal.reminderMinutes, 21 * 60 + 30);
    expect(goal.repeatDays, {6});
  });

  test('closing a goal keeps its settings and re-opening restores them',
      () async {
    const goal = ReadingGoal(
      method: GoalMethod.chapters,
      value: 30,
      reminderEnabled: false,
      reminderMinutes: 8 * 60 + 15,
      repeatDays: {0, 2, 4},
      rules: [true, false, true],
    );
    await repository.saveGoal(goal);

    await repository.setEnabled(false);

    final closed = (await repository.loadGoal())!;
    expect(closed.enabled, isFalse);
    expect(closed.method, GoalMethod.chapters);
    expect(closed.value, 30);
    expect(closed.reminderEnabled, isFalse);
    expect(closed.reminderMinutes, 8 * 60 + 15);
    expect(closed.repeatDays, {0, 2, 4});
    expect(closed.rules, [true, false, true]);

    await repository.setEnabled(true);

    final reopened = (await repository.loadGoal())!;
    expect(reopened.enabled, isTrue);
    expect(reopened.method, GoalMethod.chapters);
    expect(reopened.value, 30);
    expect(reopened.reminderMinutes, 8 * 60 + 15);
  });

  test('a stored goal without an enabled flag is active', () async {
    await database.into(database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: ReadingGoal.preferenceKey,
            value: '{"method":"chapters","value":24}',
            updatedAt: DateTime(2026, 5, 20),
          ),
        );

    final goal = (await repository.loadGoal())!;
    expect(goal.enabled, isTrue);
    expect(goal.method, GoalMethod.chapters);
    expect(goal.value, 24);
  });

  test('malformed stored JSON falls back to the defaults', () async {
    await database.into(database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: ReadingGoal.preferenceKey,
            value: '{"method":"nope","value":-3}',
            updatedAt: DateTime(2026, 5, 20),
          ),
        );

    final goal = (await repository.loadGoal())!;
    expect(goal.method, GoalMethod.duration);
    expect(goal.value, 20);
    expect(goal.reminderMinutes, 21 * 60 + 30);
  });
}
