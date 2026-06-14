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
  });

  final String id;
  final String name;
  final String url;
  final Map<String, dynamic> rawJson;
  final int? sortOrder;
  final String? groupName;
  final String? comment;
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
  });

  final int totalInputCount;
  final int validCount;
  final int insertedCount;
  final int updatedCount;
  final int skippedExistingCount;
  final int duplicateInFileCount;
  final int invalidCount;

  int get changedCount => insertedCount + updatedCount;
}

enum ExistingSourceStrategy {
  update,
  skip,
}
