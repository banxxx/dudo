import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../domain/theme_settings.dart';

abstract interface class ThemeSettingsRepository {
  Stream<ThemeSettings> watch();

  Future<ThemeSettings> load();

  Future<void> save(ThemeSettings settings);
}

/// Stores the theme appearance configuration as a single JSON value in
/// `app_preferences`, mirroring the reader and read-aloud repositories.
class DriftThemeSettingsRepository implements ThemeSettingsRepository {
  const DriftThemeSettingsRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<ThemeSettings> watch() {
    final query = _database.select(_database.appPreferences)
      ..where((table) => table.key.equals(ThemeSettings.preferenceKey));
    return query.watchSingleOrNull().map((row) => _decode(row?.value));
  }

  @override
  Future<ThemeSettings> load() async {
    final row = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(ThemeSettings.preferenceKey)))
        .getSingleOrNull();
    return _decode(row?.value);
  }

  @override
  Future<void> save(ThemeSettings settings) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(ThemeSettings.preferenceKey),
            value: Value(jsonEncode(settings.toJson())),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  ThemeSettings _decode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ThemeSettings.defaults();
    }
    try {
      return ThemeSettings.fromJson(jsonDecode(value));
    } catch (_) {
      return ThemeSettings.defaults();
    }
  }
}
