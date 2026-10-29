import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/settings/read_aloud_settings/data/read_aloud_settings_repository.dart';
import 'package:dudo/features/settings/read_aloud_settings/domain/read_aloud_settings.dart';
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
  late ReadAloudSettingsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftReadAloudSettingsRepository(database);
  });

  tearDown(() => database.close());

  test('returns the defaults when nothing has been saved', () async {
    final settings = await repository.load();

    expect(settings, ReadAloudSettings.defaults());
  });

  test('saves and reloads the settings', () async {
    final settings = ReadAloudSettings.defaults().copyWith(
      voiceName: 'zh-cn-x-ccc-local',
      voiceLocale: 'zh-CN',
      speechRate: 1.4,
      timerEnabled: true,
      timerMinutes: 30,
    );

    await repository.save(settings);

    expect(await repository.load(), settings);
  });

  test('the watched settings update after saving', () async {
    await repository.save(
      ReadAloudSettings.defaults().copyWith(volume: 0.4),
    );

    final settings = await repository.watch().first;
    expect(settings.volume, 0.4);
  });

  test('malformed stored JSON falls back to the defaults', () async {
    await database.into(database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: ReadAloudSettings.preferenceKey,
            value: '{not json',
            updatedAt: DateTime(2026, 5, 20),
          ),
        );

    expect(await repository.load(), ReadAloudSettings.defaults());
  });
}
