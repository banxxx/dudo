import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/reading_stats/data/reading_session_recorder.dart';
import 'package:dudo/features/reading_stats/data/reading_stats_repository.dart';
import 'package:dudo/features/reading_stats/domain/reading_stats_models.dart';
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
  late ReadingSessionRecorder recorder;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    recorder = ReadingSessionRecorder(database);
  });

  tearDown(() => database.close());

  test('stores a session with its duration and end time', () async {
    await database.into(database.books).insert(
          BooksCompanion.insert(id: 'book-1', title: '三体'),
        );

    await recorder.record(
      bookId: 'book-1',
      startedAt: DateTime(2026, 5, 20, 9),
      endedAt: DateTime(2026, 5, 20, 9, 3, 20),
    );

    final sessions = await database.select(database.readingSessions).get();
    expect(sessions, hasLength(1));
    expect(sessions.single.bookId, 'book-1');
    expect(sessions.single.durationSeconds, 200);
    expect(sessions.single.endedAt, DateTime(2026, 5, 20, 9, 3, 20));
    expect(sessions.single.wordsRead, 0);
  });

  test('ignores sessions shorter than a second', () async {
    await recorder.record(
      bookId: 'book-1',
      startedAt: DateTime(2026, 5, 20, 9),
      endedAt: DateTime(2026, 5, 20, 9, 0, 0, 500),
    );

    expect(await database.select(database.readingSessions).get(), isEmpty);
  });

  test('recorded sessions show up in the weekly summary', () async {
    await database.into(database.books).insert(
          BooksCompanion.insert(id: 'book-1', title: '三体'),
        );
    final wednesday = DateTime(2026, 5, 20, 9);

    await recorder.record(
      bookId: 'book-1',
      startedAt: wednesday,
      endedAt: wednesday.add(const Duration(minutes: 12)),
    );
    await recorder.record(
      bookId: 'book-1',
      startedAt: wednesday.add(const Duration(hours: 2)),
      endedAt: wednesday.add(const Duration(hours: 2, minutes: 8)),
    );

    final summary = await ReadingStatsRepository(database)
        .getSummary(ReadingStatsRange.weekOf(wednesday));

    expect(summary.hasData, isTrue);
    expect(summary.totalLabel, '20m');
    expect(summary.stats.first.value, '1天');
    final day = summary.rhythmStats.firstWhere((stat) => stat.label == '三');
    expect(day.minutes, 20);
  });
}
