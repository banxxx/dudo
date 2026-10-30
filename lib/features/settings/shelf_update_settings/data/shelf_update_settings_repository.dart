import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../domain/shelf_update_settings.dart';

abstract interface class ShelfUpdateSettingsRepository {
  Stream<ShelfUpdateSettings> watch();

  Future<ShelfUpdateSettings> load();

  Future<void> save(ShelfUpdateSettings settings);
}

/// Stores the shelf update configuration as a single JSON value in
/// `app_preferences`, mirroring the read-aloud settings repository.
class DriftShelfUpdateSettingsRepository
    implements ShelfUpdateSettingsRepository {
  const DriftShelfUpdateSettingsRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<ShelfUpdateSettings> watch() {
    final query = _database.select(_database.appPreferences)
      ..where((table) => table.key.equals(ShelfUpdateSettings.preferenceKey));
    return query.watchSingleOrNull().map((row) => _decode(row?.value));
  }

  @override
  Future<ShelfUpdateSettings> load() async {
    final row = await (_database.select(_database.appPreferences)
          ..where(
            (table) => table.key.equals(ShelfUpdateSettings.preferenceKey),
          ))
        .getSingleOrNull();
    return _decode(row?.value);
  }

  @override
  Future<void> save(ShelfUpdateSettings settings) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(ShelfUpdateSettings.preferenceKey),
            value: Value(jsonEncode(settings.toJson())),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  ShelfUpdateSettings _decode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ShelfUpdateSettings.defaults();
    }
    try {
      return ShelfUpdateSettings.fromJson(jsonDecode(value));
    } catch (_) {
      return ShelfUpdateSettings.defaults();
    }
  }
}
