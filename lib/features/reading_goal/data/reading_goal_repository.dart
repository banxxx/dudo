import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/reading_goal.dart';

/// Stores the monthly reading goal as a single JSON value in
/// `app_preferences`.
class ReadingGoalRepository {
  const ReadingGoalRepository(this._database);

  final AppDatabase _database;

  Stream<ReadingGoal> watchGoal() {
    final query = _database.select(_database.appPreferences)
      ..where((table) => table.key.equals(ReadingGoal.preferenceKey));
    return query.watchSingleOrNull().map((row) => _decode(row?.value));
  }

  Future<ReadingGoal> loadGoal() async {
    final row = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(ReadingGoal.preferenceKey)))
        .getSingleOrNull();
    return _decode(row?.value);
  }

  Future<void> saveGoal(ReadingGoal goal) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(ReadingGoal.preferenceKey),
            value: Value(jsonEncode(goal.toJson())),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  ReadingGoal _decode(String? value) {
    if (value == null || value.trim().isEmpty) return ReadingGoal.defaults();
    try {
      return ReadingGoal.fromJson(jsonDecode(value));
    } catch (_) {
      return ReadingGoal.defaults();
    }
  }
}
