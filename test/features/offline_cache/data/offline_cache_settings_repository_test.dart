import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/offline_cache/data/offline_cache_settings_repository.dart';
import 'package:dudo/features/offline_cache/domain/offline_cache_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

void main() {
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }

  late AppDatabase database;
  late DriftOfflineCacheSettingsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftOfflineCacheSettingsRepository(database);
  });

  tearDown(() => database.close());

  test('returns the defaults when nothing has been saved', () async {
    expect(await repository.load(), OfflineCacheSettings.defaults());
  });

  test('saves and reloads the concurrency', () async {
    await repository.save(
      OfflineCacheSettings.defaults().copyWith(concurrency: 5),
    );

    expect((await repository.load()).concurrency, 5);
  });

  test('the watched settings update after saving', () async {
    await repository.save(
      OfflineCacheSettings.defaults().copyWith(concurrency: 1),
    );

    final settings = await repository.watch().first;
    expect(settings.concurrency, 1);
  });

  test('malformed or unsupported stored values fall back to the defaults',
      () async {
    await database.into(database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: OfflineCacheSettings.preferenceKey,
            value: '{"concurrency": 9}',
            updatedAt: DateTime(2026, 11, 1),
          ),
        );

    expect(await repository.load(), OfflineCacheSettings.defaults());

    await database.into(database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: OfflineCacheSettings.preferenceKey,
            value: '{not json',
            updatedAt: DateTime(2026, 11, 1),
          ),
        );

    expect(await repository.load(), OfflineCacheSettings.defaults());
  });
}
