import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/settings/shelf_update_settings/data/shelf_update_settings_repository.dart';
import 'package:dudo/features/settings/shelf_update_settings/domain/shelf_update_settings.dart';
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
  late ShelfUpdateSettingsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftShelfUpdateSettingsRepository(database);
  });

  tearDown(() => database.close());

  test('returns the defaults when nothing has been saved', () async {
    expect(await repository.load(), ShelfUpdateSettings.defaults());
  });

  test('saves and reloads the settings', () async {
    final settings = ShelfUpdateSettings.defaults().copyWith(
      enabled: true,
      frequency: ShelfUpdateFrequency.weekly,
      wifiOnly: false,
      chapterAlerts: false,
    );

    await repository.save(settings);

    expect(await repository.load(), settings);
  });

  test('the watched settings update after saving', () async {
    await repository.save(
      ShelfUpdateSettings.defaults().copyWith(
        frequency: ShelfUpdateFrequency.everyThreeDays,
      ),
    );

    final settings = await repository.watch().first;
    expect(settings.frequency, ShelfUpdateFrequency.everyThreeDays);
  });

  test('malformed stored JSON falls back to the defaults', () async {
    await database.into(database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: ShelfUpdateSettings.preferenceKey,
            value: '{not json',
            updatedAt: DateTime(2026, 5, 20),
          ),
        );

    expect(await repository.load(), ShelfUpdateSettings.defaults());
  });
}
