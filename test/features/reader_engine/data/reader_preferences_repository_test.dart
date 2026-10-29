import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/reader_engine/data/reader_preferences_repository.dart';
import 'package:dudo/features/reader_engine/domain/reader_preferences.dart';
import 'package:dudo/features/reader_engine/domain/reader_turn_mode.dart';
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
  late ReaderPreferencesRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftReaderPreferencesRepository(database);
  });

  tearDown(() => database.close());

  test('returns the defaults when nothing has been saved', () async {
    final preferences = await repository.load();

    expect(preferences.paletteId, 'parchment');
    expect(preferences.fontSize, 19);
    expect(preferences.turnMode, ReaderTurnMode.slide);
  });

  test('saves and reloads preferences', () async {
    final preferences = ReaderPreferences.defaults().copyWith(
      paletteId: 'warmBrown',
      fontSize: 22,
      turnMode: ReaderTurnMode.paged,
      volumePageTurnEnabled: false,
    );

    await repository.save(preferences);

    final loaded = await repository.load();
    expect(loaded.paletteId, 'warmBrown');
    expect(loaded.fontSize, 22);
    expect(loaded.turnMode, ReaderTurnMode.paged);
    expect(loaded.volumePageTurnEnabled, isFalse);
  });

  test('the watched preferences update after saving', () async {
    await repository.save(
      ReaderPreferences.defaults().copyWith(paletteId: 'night'),
    );

    final preferences = await repository.watch().first;
    expect(preferences.paletteId, 'night');
  });

  test('malformed stored JSON falls back to the defaults', () async {
    await database.into(database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: ReaderPreferences.preferenceKey,
            value: '{not json',
            updatedAt: DateTime(2026, 5, 20),
          ),
        );

    final preferences = await repository.load();
    expect(preferences.paletteId, 'parchment');
    expect(preferences.fontSize, 19);
  });
}
