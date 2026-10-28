import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/reading_stats/data/reading_stats_repository.dart';
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
  late ReadingStatsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ReadingStatsRepository(database);
  });

  tearDown(() => database.close());

  Future<void> insertSession({
    required DateTime startedAt,
    int seconds = 600,
    int chaptersRead = 0,
    int wordsRead = 0,
  }) {
    return database.into(database.readingSessions).insert(
          ReadingSessionsCompanion.insert(
            bookId: 'book-1',
            startedAt: startedAt,
            endedAt: Value(startedAt.add(Duration(seconds: seconds))),
            durationSeconds: Value(seconds),
            chaptersRead: Value(chaptersRead),
            wordsRead: Value(wordsRead),
          ),
        );
  }

  test('aggregates only the requested month', () async {
    await insertSession(
      startedAt: DateTime(2026, 5, 20, 9),
      seconds: 720,
      chaptersRead: 3,
      wordsRead: 6000,
    );
    await insertSession(
      startedAt: DateTime(2026, 5, 21, 22),
      seconds: 480,
      chaptersRead: 2,
      wordsRead: 4000,
    );
    // Outside the month.
    await insertSession(startedAt: DateTime(2026, 4, 30, 20));
    // Zero-duration rows are ignored.
    await insertSession(startedAt: DateTime(2026, 5, 22, 9), seconds: 0);

    final stats = await repository.getMonthStats(DateTime(2026, 5, 21));

    expect(stats.month, DateTime(2026, 5));
    expect(stats.totalSeconds, 1200);
    expect(stats.totalMinutes, 20);
    expect(stats.chaptersRead, 5);
    expect(stats.charactersRead, 10000);
    expect(stats.recordedDays, 2);
    expect(stats.daysInMonth, 31);
    expect(stats.hasData, isTrue);
    expect(stats.compactDurationLabel, '20m');
    expect(stats.proseDurationLabel, '20 分钟');
  });

  test('streak counts back from today or yesterday', () async {
    await insertSession(startedAt: DateTime(2026, 5, 18, 9));
    await insertSession(startedAt: DateTime(2026, 5, 19, 9));
    await insertSession(startedAt: DateTime(2026, 5, 20, 9));

    final onReadingDay =
        await repository.getMonthStats(DateTime(2026, 5, 20));
    expect(onReadingDay.streakDays, 3);

    // No session on the 21st: the streak still counts from the 20th.
    final nextDay = await repository.getMonthStats(DateTime(2026, 5, 21));
    expect(nextDay.streakDays, 3);

    // A missed day breaks it.
    final twoDaysLater =
        await repository.getMonthStats(DateTime(2026, 5, 22));
    expect(twoDaysLater.streakDays, 0);
  });

  test('an empty month has no data', () async {
    final stats = await repository.getMonthStats(DateTime(2026, 5, 20));

    expect(stats.hasData, isFalse);
    expect(stats.totalSeconds, 0);
    expect(stats.recordedDays, 0);
    expect(stats.streakDays, 0);
    expect(stats.compactDurationLabel, '0m');
    expect(stats.daysInMonth, 31);
  });
}
