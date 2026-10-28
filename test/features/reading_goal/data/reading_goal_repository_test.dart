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

  test('returns the defaults when no goal has been saved', () async {
    final goal = await repository.loadGoal();

    expect(goal.method, GoalMethod.duration);
    expect(goal.value, 20);
    expect(goal.reminderEnabled, isTrue);
    expect(goal.repeatDays, {0, 1, 2, 3, 4, 5});
    expect(goal.rules, [true, true, true]);
  });

  test('saves and reloads the goal', () async {
    const goal = ReadingGoal(
      method: GoalMethod.chapters,
      value: 30,
      reminderEnabled: false,
      repeatDays: {0, 2, 4},
      rules: [true, false, true],
    );

    await repository.saveGoal(goal);

    final loaded = await repository.loadGoal();
    expect(loaded.method, GoalMethod.chapters);
    expect(loaded.value, 30);
    expect(loaded.reminderEnabled, isFalse);
    expect(loaded.repeatDays, {0, 2, 4});
    expect(loaded.rules, [true, false, true]);
  });

  test('the watched goal updates after saving', () async {
    await repository.saveGoal(
      const ReadingGoal(
        method: GoalMethod.pages,
        value: 600,
        reminderEnabled: true,
        repeatDays: {6},
        rules: [false, false, false],
      ),
    );

    final goal = await repository.watchGoal().first;
    expect(goal.method, GoalMethod.pages);
    expect(goal.value, 600);
    expect(goal.repeatDays, {6});
  });

  test('malformed stored JSON falls back to the defaults', () async {
    await database.into(database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: ReadingGoal.preferenceKey,
            value: '{"method":"nope","value":-3}',
            updatedAt: DateTime(2026, 5, 20),
          ),
        );

    final goal = await repository.loadGoal();
    expect(goal.method, GoalMethod.duration);
    expect(goal.value, 20);
  });
}
