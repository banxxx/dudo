import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:sqlite3/open.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/sources/data/source_repository.dart';
import 'package:dudo/features/sources/domain/source_import_format.dart';
import 'package:dudo/features/sources/domain/source_import_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Windows ships SQLite as winsqlite3.dll; the test runner does not have
  // sqlite3.dll on PATH like a built Flutter app does.
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }

  late AppDatabase database;
  late SourceRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SourceRepository(database);
  });

  tearDown(() => database.close());

  test('inserts imported sources with enabled, sourceType and timestamps',
      () async {
    final result = await repository.upsertImportedSources(
      _parseResult([
        _candidate(
          name: '音频源',
          enabled: false,
          sourceType: 1,
          remoteUpdatedAt: 1700000000000,
          sortOrder: 7,
        ),
      ]),
    );

    expect(result.insertedCount, 1);
    final source = await repository.findSourceById('https://a.example.com');
    expect(source, isNotNull);
    expect(source!.enabled, isFalse);
    expect(source.sourceType, 1);
    expect(source.remoteUpdatedAt, 1700000000000);
    expect(source.sortOrder, 7);
    expect(jsonDecode(source.rulesJson)['bookSourceName'], '音频源');
  });

  test('updateIfNewer skips sources that are not newer', () async {
    await _seedSource(
      repository: repository,
      remoteUpdatedAt: 200,
      enabled: false,
      sortOrder: 5,
    );

    final result = await repository.upsertImportedSources(
      _parseResult([
        _candidate(
          name: '旧版本',
          remoteUpdatedAt: 100,
        ),
      ]),
    );

    expect(result.updatedCount, 0);
    expect(result.skippedExistingCount, 1);
    final source = await repository.findSourceById('https://a.example.com');
    expect(source!.name, '旧名称');
  });

  test('updateIfNewer replaces rules but keeps local enabled and sort order',
      () async {
    await _seedSource(
      repository: repository,
      remoteUpdatedAt: 100,
      enabled: false,
      sortOrder: 5,
    );

    final result = await repository.upsertImportedSources(
      _parseResult([
        _candidate(
          name: '新名称',
          enabled: true,
          sourceType: 2,
          remoteUpdatedAt: 200,
        ),
      ]),
    );

    expect(result.updatedCount, 1);
    final source = await repository.findSourceById('https://a.example.com');
    expect(source!.name, '新名称');
    expect(source.enabled, isFalse);
    expect(source.sortOrder, 5);
    expect(source.sourceType, 2);
    expect(source.remoteUpdatedAt, 200);
  });

  test('updates sources imported before remoteUpdatedAt existed', () async {
    await _seedSource(repository: repository, remoteUpdatedAt: null);

    final result = await repository.upsertImportedSources(
      _parseResult([
        _candidate(name: '新名称', remoteUpdatedAt: 1),
      ]),
    );

    expect(result.updatedCount, 1);
    final source = await repository.findSourceById('https://a.example.com');
    expect(source!.name, '新名称');
  });

  test('lists sources by ascending sort order', () async {
    await _seedSource(
      repository: repository,
      remoteUpdatedAt: 100,
      sortOrder: 10,
    );
    await repository.upsertImportedSources(
      _parseResult([
        _candidate(
          id: 'https://b.example.com',
          name: '第二个源',
          sortOrder: 2,
        ),
      ]),
    );

    final sources = await repository.listSources();
    expect(sources.map((source) => source.name), ['第二个源', '旧名称']);
  });
}

Future<void> _seedSource({
  required SourceRepository repository,
  int? remoteUpdatedAt,
  bool enabled = true,
  int sortOrder = 0,
}) async {
  await repository.database.into(repository.database.sources).insert(
        SourcesCompanion.insert(
          id: 'https://a.example.com',
          name: '旧名称',
          url: 'https://a.example.com',
          enabled: Value(enabled),
          remoteUpdatedAt: Value(remoteUpdatedAt),
          rulesJson: '{}',
          sortOrder: Value(sortOrder),
        ),
      );
}

SourceImportParseResult _parseResult(List<SourceImportCandidate> candidates) {
  return SourceImportParseResult(
    format: SourceImportFormat.legado,
    candidates: candidates,
    invalidItems: const [],
    duplicateInFileCount: 0,
    totalInputCount: candidates.length,
  );
}

SourceImportCandidate _candidate({
  String id = 'https://a.example.com',
  required String name,
  bool enabled = true,
  int sourceType = 0,
  int? remoteUpdatedAt,
  int? sortOrder,
}) {
  return SourceImportCandidate(
    id: id,
    name: name,
    url: id,
    rawJson: {
      'bookSourceName': name,
      'bookSourceUrl': id,
    },
    enabled: enabled,
    sourceType: sourceType,
    remoteUpdatedAt: remoteUpdatedAt,
    sortOrder: sortOrder,
  );
}
