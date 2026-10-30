import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../domain/data_sync_settings.dart';

abstract interface class DataSyncSettingsRepository {
  Stream<DataSyncSettings> watch();

  Future<DataSyncSettings> load();

  Future<void> save(DataSyncSettings settings);
}

/// Stores the cloud sync configuration as a single JSON value in
/// `app_preferences`, mirroring the read-aloud settings repository.
class DriftDataSyncSettingsRepository implements DataSyncSettingsRepository {
  const DriftDataSyncSettingsRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<DataSyncSettings> watch() {
    final query = _database.select(_database.appPreferences)
      ..where((table) => table.key.equals(DataSyncSettings.preferenceKey));
    return query.watchSingleOrNull().map((row) => _decode(row?.value));
  }

  @override
  Future<DataSyncSettings> load() async {
    final row = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(DataSyncSettings.preferenceKey)))
        .getSingleOrNull();
    return _decode(row?.value);
  }

  @override
  Future<void> save(DataSyncSettings settings) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(DataSyncSettings.preferenceKey),
            value: Value(jsonEncode(settings.toJson())),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  DataSyncSettings _decode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return DataSyncSettings.defaults();
    }
    try {
      return DataSyncSettings.fromJson(jsonDecode(value));
    } catch (_) {
      return DataSyncSettings.defaults();
    }
  }
}
