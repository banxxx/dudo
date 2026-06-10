import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/reader_background.dart';

abstract interface class ReaderBackgroundRepository {
  Future<ReaderBackgroundPreference> readPreference();

  Future<void> savePreference(ReaderBackgroundPreference preference);
}

class DriftReaderBackgroundRepository implements ReaderBackgroundRepository {
  const DriftReaderBackgroundRepository(this._database);

  static const preferenceKey = 'reader.background.preference';

  final AppDatabase _database;

  @override
  Future<ReaderBackgroundPreference> readPreference() async {
    final preference = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(preferenceKey)))
        .getSingleOrNull();
    final value = preference?.value;
    if (value == null || value.isEmpty) {
      return ReaderBackgroundPreference.defaults();
    }
    return ReaderBackgroundPreference.fromJsonString(value);
  }

  @override
  Future<void> savePreference(ReaderBackgroundPreference preference) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(preferenceKey),
            value: Value(preference.toJsonString()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }
}
