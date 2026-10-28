import 'source_import_format.dart';

class SourceImportCandidate {
  const SourceImportCandidate({
    required this.id,
    required this.name,
    required this.url,
    required this.rawJson,
    this.sortOrder,
    this.groupName,
    this.comment,
    this.enabled = true,
    this.sourceType = 0,
    this.remoteUpdatedAt,
    this.hasSearch = false,
    this.hasExplore = false,
  });

  final String id;
  final String name;
  final String url;
  final Map<String, dynamic> rawJson;
  final int? sortOrder;
  final String? groupName;
  final String? comment;

  /// Imported `enabled` value. Used for new rows; existing rows keep the
  /// user's local enable state.
  final bool enabled;

  /// Legado `bookSourceType` (0 text, 1 audio, 2 image, 3 file, 4 video).
  final int sourceType;

  /// Legado `lastUpdateTime` in milliseconds, used to decide whether an
  /// existing local source should be replaced.
  final int? remoteUpdatedAt;

  final bool hasSearch;
  final bool hasExplore;
}

class SourceImportInvalidItem {
  const SourceImportInvalidItem({
    required this.index,
    required this.reason,
    this.url,
    this.name,
  });

  final int index;
  final String reason;
  final String? url;
  final String? name;
}

class SourceImportParseResult {
  const SourceImportParseResult({
    required this.format,
    required this.candidates,
    required this.invalidItems,
    required this.duplicateInFileCount,
    required this.totalInputCount,
  });

  final SourceImportFormat format;
  final List<SourceImportCandidate> candidates;
  final List<SourceImportInvalidItem> invalidItems;
  final int duplicateInFileCount;
  final int totalInputCount;

  int get invalidCount => invalidItems.length;
  int get validCount => candidates.length;
  int get nonTextCount =>
      candidates.where((candidate) => candidate.sourceType != 0).length;
  int get searchlessCount =>
      candidates.where((candidate) => !candidate.hasSearch).length;
}

class SourceImportPersistResult {
  const SourceImportPersistResult({
    required this.totalInputCount,
    required this.validCount,
    required this.insertedCount,
    required this.updatedCount,
    required this.skippedExistingCount,
    required this.duplicateInFileCount,
    required this.invalidCount,
    this.nonTextCount = 0,
    this.searchlessCount = 0,
  });

  final int totalInputCount;
  final int validCount;
  final int insertedCount;
  final int updatedCount;
  final int skippedExistingCount;
  final int duplicateInFileCount;
  final int invalidCount;
  final int nonTextCount;
  final int searchlessCount;

  int get changedCount => insertedCount + updatedCount;
}

enum ExistingSourceStrategy {
  /// Always overwrite an existing row with the imported rules.
  update,

  /// Only overwrite when the imported `lastUpdateTime` is newer.
  updateIfNewer,

  /// Never touch an existing row.
  skip,
}
