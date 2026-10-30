import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/settings/data_sync_settings/data/data_sync_settings_repository.dart';
import 'package:dudo/features/settings/data_sync_settings/domain/data_sync_settings.dart';
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
  late DataSyncSettingsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftDataSyncSettingsRepository(database);
  });

  tearDown(() => database.close());

  test('returns the defaults when nothing has been saved', () async {
    expect(await repository.load(), DataSyncSettings.defaults());
  });

  test('saves and reloads the settings', () async {
    final settings = DataSyncSettings.defaults().copyWith(
      enabled: false,
      highlights: false,
    );

    await repository.save(settings);

    expect(await repository.load(), settings);
  });

  test('the watched settings update after saving', () async {
    await repository.save(
      DataSyncSettings.defaults().copyWith(progress: false),
    );

    final settings = await repository.watch().first;
    expect(settings.progress, isFalse);
  });

  test('malformed stored JSON falls back to the defaults', () async {
    await database.into(database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: DataSyncSettings.preferenceKey,
            value: '{not json',
            updatedAt: DateTime(2026, 5, 20),
          ),
        );

    expect(await repository.load(), DataSyncSettings.defaults());
  });
}
