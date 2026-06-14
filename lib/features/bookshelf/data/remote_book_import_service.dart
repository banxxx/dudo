import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/rule_engine/models/source_rule.dart';
import '../../../core/rule_engine/rule_engine.dart';
import '../../sources/data/source_repository.dart';
import 'bookshelf_repository.dart';

class RemoteBookImportService {
  const RemoteBookImportService({
    required this.bookshelfRepository,
    required this.sourceRepository,
    required this.ruleEngine,
  });

  final BookshelfRepository bookshelfRepository;
  final SourceRepository sourceRepository;
  final RuleEngine ruleEngine;

  Future<String> importRemoteBook({
    required String sourceId,
    required String bookUrl,
    String? fallbackName,
    String? fallbackAuthor,
    String? fallbackCoverUrl,
    String? fallbackIntro,
  }) async {
    final source = await sourceRepository.findSourceById(sourceId);
    if (source == null) {
      throw RemoteBookImportException('source not found: $sourceId');
    }
    final rule = _parseSourceRule(source.rulesJson);
    if (rule == null) {
      throw RemoteBookImportException(
          'source rule cannot be parsed: $sourceId');
    }

    final info = await ruleEngine.loadBookInfo(rule, bookUrl);
    final tocUrl = info?.tocUrl ?? bookUrl;
    final toc = await ruleEngine.loadToc(rule, tocUrl);
    final now = DateTime.now();
    final bookId = _remoteBookId(sourceId, bookUrl);
    final title = _firstNonEmpty([info?.name, fallbackName, bookUrl]);

    await bookshelfRepository.upsertRemoteBook(
      book: BooksCompanion.insert(
        id: bookId,
        title: title,
        author: Value(_firstNonEmptyOrNull([info?.author, fallbackAuthor])),
        coverUrl:
            Value(_firstNonEmptyOrNull([info?.coverUrl, fallbackCoverUrl])),
        intro: Value(_firstNonEmptyOrNull([info?.intro, fallbackIntro])),
        sourceId: Value(sourceId),
        sourceBookUrl: Value(bookUrl),
        localPath: const Value(null),
        inShelf: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
        sortOrder: Value(now.millisecondsSinceEpoch),
      ),
      chapters: [
        for (final entry
            in (toc?.chapters ?? const <TocChapterResult>[]).indexed)
          if (_hasChapterUrl(entry.$2))
            ChaptersCompanion.insert(
              id: '$bookId:${entry.$1}',
              bookId: bookId,
              chapterIndex: entry.$1,
              title: entry.$2.name,
              url: Value(entry.$2.url),
              normalizedContentLength: const Value(0),
              isCached: const Value(false),
            ),
      ],
    );
    return bookId;
  }

  SourceRule? _parseSourceRule(String rulesJson) {
    try {
      final decoded = jsonDecode(rulesJson);
      if (decoded is! Map) return null;
      return SourceRule.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  bool _hasChapterUrl(TocChapterResult chapter) {
    return chapter.name.trim().isNotEmpty &&
        (chapter.url?.trim().isNotEmpty ?? false);
  }

  String _remoteBookId(String sourceId, String bookUrl) {
    return 'remote_${_stableHash('$sourceId\u0000$bookUrl')}';
  }

  String _stableHash(String input) {
    var hash = 0xcbf29ce484222325;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  String _firstNonEmpty(Iterable<String?> values) {
    return _firstNonEmptyOrNull(values) ?? '';
  }

  String? _firstNonEmptyOrNull(Iterable<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}

class RemoteBookImportException implements Exception {
  const RemoteBookImportException(this.message);

  final String message;

  @override
  String toString() => 'RemoteBookImportException($message)';
}
