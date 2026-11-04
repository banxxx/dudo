import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

abstract interface class ReadingHistoryRepository {
  /// Timestamp of the last "clear history" action. Entries opened before it
  /// stay hidden until the book is read again.
  Future<DateTime?> loadClearedAt();

  Future<void> clear(DateTime now);
}

/// Stores the cleared timestamp in `app_preferences`.
///
/// Clearing only hides the list: book rows, reading positions and statistics
/// are untouched, so a cleared history can never lose reading progress.
class DriftReadingHistoryRepository implements ReadingHistoryRepository {
  const DriftReadingHistoryRepository(this._database);

  final AppDatabase _database;

  static const clearedAtKey = 'reading_history.cleared_at';

  @override
  Future<DateTime?> loadClearedAt() async {
    final row = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(clearedAtKey)))
        .getSingleOrNull();
    final value = row?.value;
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  @override
  Future<void> clear(DateTime now) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(clearedAtKey),
            value: Value(now.toIso8601String()),
            updatedAt: Value(now),
          ),
        );
  }
}
