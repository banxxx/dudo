import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

abstract interface class RecentSearchRepository {
  Stream<List<String>> watchRecentSearches();

  Future<List<String>> readRecentSearches();

  Future<void> addSearch(String keyword);

  Future<void> clear();
}

class DriftRecentSearchRepository implements RecentSearchRepository {
  const DriftRecentSearchRepository(this._database);

  static const preferenceKey = 'search.recentKeywords';
  static const maxRecentSearches = 10;

  final AppDatabase _database;

  @override
  Stream<List<String>> watchRecentSearches() {
    final query = _database.select(_database.appPreferences)
      ..where((table) => table.key.equals(preferenceKey));
    return query.watchSingleOrNull().map((row) => _decode(row?.value));
  }

  @override
  Future<List<String>> readRecentSearches() async {
    final row = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(preferenceKey)))
        .getSingleOrNull();
    return _decode(row?.value);
  }

  @override
  Future<void> addSearch(String keyword) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) return;

    final current = await readRecentSearches();
    final next = <String>[
      normalized,
      for (final item in current)
        if (item != normalized) item,
    ];
    final limited = next.take(maxRecentSearches).toList(growable: false);
    await _save(limited);
  }

  @override
  Future<void> clear() async {
    await (_database.delete(_database.appPreferences)
          ..where((table) => table.key.equals(preferenceKey)))
        .go();
  }

  Future<void> _save(List<String> searches) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(preferenceKey),
            value: Value(jsonEncode(searches)),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  List<String> _decode(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      final seen = <String>{};
      final items = <String>[];
      for (final item in decoded) {
        final text = item.toString().trim();
        if (text.isEmpty || !seen.add(text)) continue;
        items.add(text);
        if (items.length >= maxRecentSearches) break;
      }
      return List.unmodifiable(items);
    } catch (_) {
      return const [];
    }
  }
}
