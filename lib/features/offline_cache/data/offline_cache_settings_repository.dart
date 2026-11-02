import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/offline_cache_settings.dart';

abstract interface class OfflineCacheSettingsRepository {
  Stream<OfflineCacheSettings> watch();

  Future<OfflineCacheSettings> load();

  Future<void> save(OfflineCacheSettings settings);
}

/// Stores the download configuration as one JSON value in `app_preferences`,
/// matching the other settings repositories.
class DriftOfflineCacheSettingsRepository
    implements OfflineCacheSettingsRepository {
  const DriftOfflineCacheSettingsRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<OfflineCacheSettings> watch() {
    final query = _database.select(_database.appPreferences)
      ..where((table) => table.key.equals(OfflineCacheSettings.preferenceKey));
    return query.watchSingleOrNull().map((row) => _decode(row?.value));
  }

  @override
  Future<OfflineCacheSettings> load() async {
    final row = await (_database.select(_database.appPreferences)
          ..where(
            (table) => table.key.equals(OfflineCacheSettings.preferenceKey),
          ))
        .getSingleOrNull();
    return _decode(row?.value);
  }

  @override
  Future<void> save(OfflineCacheSettings settings) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(OfflineCacheSettings.preferenceKey),
            value: Value(jsonEncode(settings.toJson())),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  OfflineCacheSettings _decode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return OfflineCacheSettings.defaults();
    }
    try {
      return OfflineCacheSettings.fromJson(jsonDecode(value));
    } catch (_) {
      return OfflineCacheSettings.defaults();
    }
  }
}
