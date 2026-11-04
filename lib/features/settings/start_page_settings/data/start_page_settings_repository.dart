import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../domain/start_page_settings.dart';

abstract interface class StartPageSettingsRepository {
  Stream<StartPageSettings> watch();

  Future<StartPageSettings> load();

  Future<void> save(StartPageSettings settings);
}

/// Stores the startup-page choice as a single JSON value in `app_preferences`,
/// mirroring the theme and shelf-update repositories.
class DriftStartPageSettingsRepository implements StartPageSettingsRepository {
  const DriftStartPageSettingsRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<StartPageSettings> watch() {
    final query = _database.select(_database.appPreferences)
      ..where((table) => table.key.equals(StartPageSettings.preferenceKey));
    return query.watchSingleOrNull().map((row) => _decode(row?.value));
  }

  @override
  Future<StartPageSettings> load() async {
    final row = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(StartPageSettings.preferenceKey)))
        .getSingleOrNull();
    return _decode(row?.value);
  }

  @override
  Future<void> save(StartPageSettings settings) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(StartPageSettings.preferenceKey),
            value: Value(jsonEncode(settings.toJson())),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  StartPageSettings _decode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return StartPageSettings.defaults();
    }
    try {
      return StartPageSettings.fromJson(jsonDecode(value));
    } catch (_) {
      return StartPageSettings.defaults();
    }
  }
}
