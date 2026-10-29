import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../domain/read_aloud_settings.dart';

abstract interface class ReadAloudSettingsRepository {
  Stream<ReadAloudSettings> watch();

  Future<ReadAloudSettings> load();

  Future<void> save(ReadAloudSettings settings);
}

/// Stores the read-aloud configuration as a single JSON value in
/// `app_preferences`, mirroring the reader preferences repository.
class DriftReadAloudSettingsRepository implements ReadAloudSettingsRepository {
  const DriftReadAloudSettingsRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<ReadAloudSettings> watch() {
    final query = _database.select(_database.appPreferences)
      ..where((table) => table.key.equals(ReadAloudSettings.preferenceKey));
    return query.watchSingleOrNull().map((row) => _decode(row?.value));
  }

  @override
  Future<ReadAloudSettings> load() async {
    final row = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(ReadAloudSettings.preferenceKey)))
        .getSingleOrNull();
    return _decode(row?.value);
  }

  @override
  Future<void> save(ReadAloudSettings settings) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(ReadAloudSettings.preferenceKey),
            value: Value(jsonEncode(settings.toJson())),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  ReadAloudSettings _decode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ReadAloudSettings.defaults();
    }
    try {
      return ReadAloudSettings.fromJson(jsonDecode(value));
    } catch (_) {
      return ReadAloudSettings.defaults();
    }
  }
}
