import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/source_import_models.dart';

const _sourceBatchChunkSize = 400;

class SourceRepository {
  const SourceRepository(this.database);

  final AppDatabase database;

  Stream<List<Source>> watchSources() {
    final query = database.select(database.sources)
      ..orderBy([
        (source) => OrderingTerm(
              expression: source.sortOrder,
              mode: OrderingMode.asc,
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
              mode: OrderingMode.asc,
            ),
        (source) => OrderingTerm(
              expression: source.updatedAt,
              mode: OrderingMode.desc,
            ),
      ]);
    return query.get();
  }

  Future<List<Source>> listEnabledSources() {
    final query = database.select(database.sources)
      ..where((source) => source.enabled.equals(true))
      ..orderBy([
        (source) => OrderingTerm(
              expression: source.sortOrder,
              mode: OrderingMode.asc,
            ),
        (source) => OrderingTerm(
              expression: source.updatedAt,
              mode: OrderingMode.desc,
            ),
      ]);
    return query.get();
  }

  Future<Source?> findSourceById(String id) {
    final query = database.select(database.sources)
      ..where((source) => source.id.equals(id))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<SourceImportPersistResult> upsertImportedSources(
    SourceImportParseResult parseResult, {
    ExistingSourceStrategy existingStrategy =
        ExistingSourceStrategy.updateIfNewer,
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
        nonTextCount: parseResult.nonTextCount,
        searchlessCount: parseResult.searchlessCount,
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
      var nextSortOrder = (await _maxSortOrder()) + 1;

      await database.batch((batch) {
        for (final candidate in candidates) {
          final existing =
              existingById[candidate.id] ?? existingById[candidate.url];
          final rulesJson = jsonEncode(candidate.rawJson);
          final remoteUpdatedAt = candidate.remoteUpdatedAt ?? 0;

          if (existing != null) {
            final shouldUpdate = switch (existingStrategy) {
              ExistingSourceStrategy.update => true,
              ExistingSourceStrategy.updateIfNewer => _isNewer(
                  incoming: remoteUpdatedAt,
                  existing: existing.remoteUpdatedAt,
                ),
              ExistingSourceStrategy.skip => false,
            };
            if (!shouldUpdate) {
              skippedExistingCount += 1;
              continue;
            }
            updatedCount += 1;
            // Preserve the user's local order and enable state; only the
            // imported rule payload and identity fields are replaced.
            batch.update(
              database.sources,
              SourcesCompanion(
                name: Value(candidate.name),
                url: Value(candidate.url),
                groupName: Value(candidate.groupName),
                comment: Value(candidate.comment),
                sourceType: Value(candidate.sourceType),
                remoteUpdatedAt: Value(remoteUpdatedAt),
                rulesJson: Value(rulesJson),
                updatedAt: Value(now),
              ),
              where: (source) => source.id.equals(existing.id),
            );
          } else {
            insertedCount += 1;
            final sortOrder = candidate.sortOrder ?? nextSortOrder++;
            batch.insert(
              database.sources,
              SourcesCompanion.insert(
                id: candidate.id,
                name: candidate.name,
                url: candidate.url,
                groupName: Value(candidate.groupName),
                comment: Value(candidate.comment),
                enabled: Value(candidate.enabled),
                sourceType: Value(candidate.sourceType),
                remoteUpdatedAt: Value(remoteUpdatedAt),
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
        nonTextCount: parseResult.nonTextCount,
        searchlessCount: parseResult.searchlessCount,
      );
    });
  }

  Future<int> _maxSortOrder() async {
    final maxExpression = database.sources.sortOrder.max();
    final row = await (database.selectOnly(database.sources)
          ..addColumns([maxExpression]))
        .getSingle();
    return row.read(maxExpression) ?? -1;
  }

  bool _isNewer({required int incoming, required int? existing}) {
    if (existing == null) return true;
    return incoming > existing;
  }

  Future<List<Source>> _loadExistingSourcesByIds(List<String> ids) async {
    final uniqueIds = ids.toSet().toList(growable: false);
    if (uniqueIds.isEmpty) return const [];

    final rows = <Source>[];
    for (final chunk in _sourceIdChunks(uniqueIds)) {
      final chunkRows = await (database.select(database.sources)
            ..where(
              (source) => source.id.isIn(chunk) | source.url.isIn(chunk),
            ))
          .get();
      rows.addAll(chunkRows);
    }
    return rows;
  }

  Iterable<List<String>> _sourceIdChunks(List<String> ids) sync* {
    for (var start = 0; start < ids.length; start += _sourceBatchChunkSize) {
      final end = (start + _sourceBatchChunkSize).clamp(0, ids.length);
      yield ids.sublist(start, end);
    }
  }

  Future<void> setSourceEnabled(String id, bool enabled) {
    return setSourcesEnabled([id], enabled);
  }

  Future<void> setSourcesEnabled(Iterable<String> ids, bool enabled) async {
    final uniqueIds = ids.toSet().toList(growable: false);
    if (uniqueIds.isEmpty) return;

    final now = DateTime.now();
    await database.transaction(() async {
      for (final chunk in _sourceIdChunks(uniqueIds)) {
        await (database.update(database.sources)
              ..where((source) => source.id.isIn(chunk)))
            .write(
          SourcesCompanion(
            enabled: Value(enabled),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<void> deleteSource(String id) {
    return deleteSources([id]);
  }

  Future<void> deleteSources(Iterable<String> ids) async {
    final uniqueIds = ids.toSet().toList(growable: false);
    if (uniqueIds.isEmpty) return;

    await database.transaction(() async {
      for (final chunk in _sourceIdChunks(uniqueIds)) {
        await (database.delete(database.sources)
              ..where((source) => source.id.isIn(chunk)))
            .go();
      }
    });
  }
}
