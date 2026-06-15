import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/logger.dart';
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
    String? fallbackKind,
    String? fallbackLastChapter,
    String? fallbackWordCount,
    bool addToShelf = false,
    List<Map<String, Object?>> origins = const [],
  }) async {
    log.i(
      '[remote-import] start sourceId=$sourceId bookUrl=$bookUrl '
      'fallbackName=$fallbackName fallbackAuthor=$fallbackAuthor '
      'fallbackCoverUrl=$fallbackCoverUrl fallbackKind=$fallbackKind '
      'fallbackLastChapter=$fallbackLastChapter '
      'fallbackWordCount=$fallbackWordCount origins=$origins',
    );
    try {
      final source = await sourceRepository.findSourceById(sourceId);
      if (source == null) {
        throw RemoteBookImportException('source not found: $sourceId');
      }
      final rule = _parseSourceRule(source.rulesJson);
      if (rule == null) {
        throw RemoteBookImportException(
            'source rule cannot be parsed: $sourceId');
      }
      log.i(
        '[remote-import] source found name=${source.name} url=${source.url} '
        'ruleName=${rule.name} ruleUrl=${rule.url}',
      );

      final bookContext = <String, Object?>{
        'name': fallbackName,
        'author': fallbackAuthor,
        'kind': fallbackKind,
        'bookUrl': bookUrl,
        'origin': rule.id,
        'originName': rule.name,
        'coverUrl': fallbackCoverUrl,
        'intro': fallbackIntro,
        'tocUrl': null,
        'wordCount': fallbackWordCount,
        'latestChapterTitle': fallbackLastChapter,
        'lastChapter': fallbackLastChapter,
        'variable': null,
        'origins': origins,
      }..removeWhere((_, value) => value == null);
      log.i('[remote-import] bookContext=$bookContext');

      final info =
          await ruleEngine.loadBookInfo(rule, bookUrl, book: bookContext);
      log.i(
        '[remote-import] bookInfo name=${info?.name} author=${info?.author} '
        'kind=${info?.kind} lastChapter=${info?.lastChapter} '
        'tocUrl=${info?.tocUrl} coverUrl=${info?.coverUrl} '
        'wordCount=${info?.wordCount} intro=${_preview(info?.intro ?? '')}',
      );

      final parsedTocUrl = _cleanParsedUrl(
        info?.tocUrl,
        invalidEmptyQueryKeys: const ['novelId'],
      );
      final parsedCoverUrl = _cleanParsedUrl(info?.coverUrl);
      final tocUrl = _firstNonEmptyOrNull([parsedTocUrl, bookUrl]) ?? bookUrl;
      bookContext
        ..['name'] = _firstNonEmptyOrNull([info?.name, fallbackName])
        ..['author'] = _firstNonEmptyOrNull([info?.author, fallbackAuthor])
        ..['kind'] = _firstNonEmptyOrNull([info?.kind, fallbackKind])
        ..['coverUrl'] =
            _firstNonEmptyOrNull([parsedCoverUrl, fallbackCoverUrl])
        ..['intro'] = _firstNonEmptyOrNull([info?.intro, fallbackIntro])
        ..['tocUrl'] = tocUrl
        ..['wordCount'] =
            _firstNonEmptyOrNull([info?.wordCount, fallbackWordCount])
        ..['latestChapterTitle'] =
            _firstNonEmptyOrNull([info?.lastChapter, fallbackLastChapter])
        ..['lastChapter'] =
            _firstNonEmptyOrNull([info?.lastChapter, fallbackLastChapter]);
      bookContext.removeWhere((_, value) => value == null);
      log.i('[remote-import] loadToc tocUrl=$tocUrl bookContext=$bookContext');

      final toc = await ruleEngine.loadToc(rule, tocUrl, book: bookContext);
      final chapters = toc?.chapters ?? const <TocChapterResult>[];
      log.i(
        '[remote-import] toc chapters=${chapters.length} '
        'nextTocUrl=${toc?.nextTocUrl} samples=${_chapterSamples(chapters)}',
      );

      final now = DateTime.now();
      final bookId = _remoteBookId(sourceId, bookUrl);
      final existingBook = await bookshelfRepository.findBookById(bookId);
      final shouldBeInShelf = addToShelf || (existingBook?.inShelf ?? false);
      final title = _firstNonEmpty([info?.name, fallbackName, bookUrl]);

      await bookshelfRepository.upsertRemoteBook(
        book: BooksCompanion.insert(
          id: bookId,
          title: title,
          author: Value(_firstNonEmptyOrNull([info?.author, fallbackAuthor])),
          coverUrl:
              Value(_firstNonEmptyOrNull([parsedCoverUrl, fallbackCoverUrl])),
          intro: Value(_firstNonEmptyOrNull([info?.intro, fallbackIntro])),
          sourceId: Value(sourceId),
          sourceBookUrl: Value(bookUrl),
          localPath: const Value(null),
          inShelf: Value(shouldBeInShelf),
          createdAt: Value(existingBook?.createdAt ?? now),
          updatedAt: Value(now),
          sortOrder: Value(
            shouldBeInShelf
                ? (existingBook?.sortOrder ?? now.millisecondsSinceEpoch)
                : 0,
          ),
        ),
        chapters: [
          for (final entry in chapters.indexed)
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
      log.i(
        '[remote-import] saved bookId=$bookId title=$title '
        'chapters=${chapters.where(_hasChapterUrl).length}',
      );
      return bookId;
    } catch (error, stackTrace) {
      log.e(
        '[remote-import] failed sourceId=$sourceId bookUrl=$bookUrl',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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

  String? _cleanParsedUrl(
    String? value, {
    List<String> invalidEmptyQueryKeys = const [],
  }) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    if (_containsRuleResidue(text)) return null;
    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    for (final key in invalidEmptyQueryKeys) {
      if (uri.queryParameters.containsKey(key) &&
          (uri.queryParameters[key]?.trim().isEmpty ?? true)) {
        return null;
      }
    }
    return text;
  }

  bool _containsRuleResidue(String value) {
    final decoded = Uri.decodeFull(value);
    return RegExp(r'<\s*/?\s*js\b|@js:', caseSensitive: false)
        .hasMatch(decoded);
  }

  String _chapterSamples(List<TocChapterResult> chapters) {
    return [
      for (final chapter in chapters.take(5))
        {
          'name': chapter.name,
          'url': chapter.url,
          'isVip': chapter.isVip,
          'isPay': chapter.isPay,
        },
    ].toString();
  }

  String _preview(String value, {int maxLength = 300}) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLength) return compact;
    return '${compact.substring(0, maxLength)}...';
  }
}

class RemoteBookImportException implements Exception {
  const RemoteBookImportException(this.message);

  final String message;

  @override
  String toString() => 'RemoteBookImportException($message)';
}
