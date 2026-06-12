import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/source_import_models.dart';

class SourceRepository {
  const SourceRepository(this.database);

  final AppDatabase database;

  Stream<List<Source>> watchSources() {
    final query = database.select(database.sources)
      ..orderBy([
        (source) => OrderingTerm(
              expression: source.sortOrder,
              mode: OrderingMode.desc,
            ),
        (source) => OrderingTerm(
              expression: source.updatedAt,
              mode: OrderingMode.desc,
            ),
      ]);
    return query.watch();
  }

  Future<List<Source>> listSources() {
    final query = database.select(database.sources)
      ..orderBy([
        (source) => OrderingTerm(
              expression: source.sortOrder,
              mode: OrderingMode.desc,
            ),
        (source) => OrderingTerm(
              expression: source.updatedAt,
              mode: OrderingMode.desc,
            ),
      ]);
    return query.get();
  }

  Future<SourceImportPersistResult> upsertImportedSources(
    SourceImportParseResult parseResult, {
    ExistingSourceStrategy existingStrategy = ExistingSourceStrategy.update,
  }) async {
    final candidates = parseResult.candidates;
    if (candidates.isEmpty) {
      return SourceImportPersistResult(
        totalInputCount: parseResult.totalInputCount,
        validCount: parseResult.validCount,
        insertedCount: 0,
        updatedCount: 0,
        skippedExistingCount: 0,
        duplicateInFileCount: parseResult.duplicateInFileCount,
        invalidCount: parseResult.invalidCount,
      );
    }

    return database.transaction(() async {
      final ids = candidates.map((candidate) => candidate.id).toList();
      final existingRows = await _loadExistingSourcesByIds(ids);
      final existingById = <String, Source>{
        for (final source in existingRows) source.id: source,
        for (final source in existingRows) source.url: source,
      };

      var insertedCount = 0;
      var updatedCount = 0;
      var skippedExistingCount = 0;
      final now = DateTime.now();

      await database.batch((batch) {
        for (var i = 0; i < candidates.length; i++) {
          final candidate = candidates[i];
          final existing =
              existingById[candidate.id] ?? existingById[candidate.url];
          final sortOrder = now.millisecondsSinceEpoch + i;
          final rulesJson = jsonEncode(candidate.rawJson);

          if (existing != null) {
            if (existingStrategy == ExistingSourceStrategy.skip) {
              skippedExistingCount += 1;
              continue;
            }
            updatedCount += 1;
            batch.update(
              database.sources,
              SourcesCompanion(
                name: Value(candidate.name),
                url: Value(candidate.url),
                groupName: Value(candidate.groupName),
                comment: Value(candidate.comment),
                rulesJson: Value(rulesJson),
                sortOrder: Value(sortOrder),
                updatedAt: Value(now),
              ),
              where: (source) => source.id.equals(existing.id),
            );
          } else {
            insertedCount += 1;
            batch.insert(
              database.sources,
              SourcesCompanion.insert(
                id: candidate.id,
                name: candidate.name,
                url: candidate.url,
                groupName: Value(candidate.groupName),
                comment: Value(candidate.comment),
                enabled: const Value(true),
                rulesJson: rulesJson,
                sortOrder: Value(sortOrder),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
          }
        }
      });

      return SourceImportPersistResult(
        totalInputCount: parseResult.totalInputCount,
        validCount: parseResult.validCount,
        insertedCount: insertedCount,
        updatedCount: updatedCount,
        skippedExistingCount: skippedExistingCount,
        duplicateInFileCount: parseResult.duplicateInFileCount,
        invalidCount: parseResult.invalidCount,
      );
    });
  }

  Future<List<Source>> _loadExistingSourcesByIds(List<String> ids) async {
    final uniqueIds = ids.toSet().toList(growable: false);
    if (uniqueIds.isEmpty) return const [];

    final rows = <Source>[];
    const chunkSize = 400;
    for (var start = 0; start < uniqueIds.length; start += chunkSize) {
      final end = (start + chunkSize).clamp(0, uniqueIds.length);
      final chunk = uniqueIds.sublist(start, end);
      final chunkRows = await (database.select(database.sources)
            ..where(
              (source) => source.id.isIn(chunk) | source.url.isIn(chunk),
            ))
          .get();
      rows.addAll(chunkRows);
    }
    return rows;
  }

  Future<void> setSourceEnabled(String id, bool enabled) async {
    await (database.update(database.sources)
          ..where((source) => source.id.equals(id)))
        .write(
      SourcesCompanion(
        enabled: Value(enabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSource(String id) async {
    await (database.delete(database.sources)
          ..where((source) => source.id.equals(id)))
        .go();
  }
}
