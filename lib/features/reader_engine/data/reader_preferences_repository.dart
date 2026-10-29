import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/reader_preferences.dart';

abstract interface class ReaderPreferencesRepository {
  Stream<ReaderPreferences> watch();

  Future<ReaderPreferences> load();

  Future<void> save(ReaderPreferences preferences);
}

/// Stores the reader's typography, theme and chrome settings as a single JSON
/// value in `app_preferences`.
class DriftReaderPreferencesRepository implements ReaderPreferencesRepository {
  const DriftReaderPreferencesRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<ReaderPreferences> watch() {
    final query = _database.select(_database.appPreferences)
      ..where((table) => table.key.equals(ReaderPreferences.preferenceKey));
    return query.watchSingleOrNull().map((row) => _decode(row?.value));
  }

  @override
  Future<ReaderPreferences> load() async {
    final row = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(ReaderPreferences.preferenceKey)))
        .getSingleOrNull();
    return _decode(row?.value);
  }

  @override
  Future<void> save(ReaderPreferences preferences) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(ReaderPreferences.preferenceKey),
            value: Value(jsonEncode(preferences.toJson())),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  ReaderPreferences _decode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ReaderPreferences.defaults();
    }
    try {
      return ReaderPreferences.fromJson(jsonDecode(value));
    } catch (_) {
      return ReaderPreferences.defaults();
    }
  }
}
