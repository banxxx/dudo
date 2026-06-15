import 'dart:convert';

import '../../../core/rule_engine/models/source_rule.dart';
import '../../../core/rule_engine/rule_engine.dart';
import '../../../core/utils/logger.dart';
import '../../sources/data/source_repository.dart';
import '../domain/reader_chapter.dart';
import '../domain/reader_document.dart';
import '../domain/reader_source_type.dart';
import 'reader_content_parser.dart';
import 'reader_document_source.dart';
import 'text_reader_book_repository.dart';

class TextReaderDocumentSource implements ReaderDocumentSource {
  const TextReaderDocumentSource(
    this.repository, {
    this.sourceRepository,
    this.ruleEngine,
  });

  final TextReaderBookRepository repository;
  final SourceRepository? sourceRepository;
  final RuleEngine? ruleEngine;

  @override
  Future<ReaderDocument> loadDocument(String bookId) async {
    final book = await repository.fetchBookById(bookId);
    if (book == null) {
      throw ReaderDocumentNotFoundException(bookId);
    }
    final chapterCount = await repository.fetchChapterCount(bookId);
    return ReaderDocument(
      bookId: book.id,
      title: book.title,
      sourceType: _sourceTypeFor(book),
      chapterCount: chapterCount,
      metadata: {
        if (book.author != null) 'author': book.author,
        if (book.coverUrl != null) 'coverUrl': book.coverUrl,
        if (book.localPath != null) 'localPath': book.localPath,
        if (book.sourceId != null) 'sourceId': book.sourceId,
      },
    );
  }

  @override
  Future<ReaderChapterMetaPage> loadChapterMetas({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    final items = await repository.fetchChapterMetasPage(
      bookId: bookId,
      offset: offset,
      limit: limit,
    );
    return ReaderChapterMetaPage(
      items: items.map(_chapterMetaFromRecord).toList(growable: false),
      offset: offset,
      limit: limit,
      hasMore: items.length == limit,
    );
  }

  @override
  Future<ReaderChapter> loadChapter({
    required String bookId,
    required int chapterIndex,
  }) async {
    log.i(
      '[reader-remote-content] loadChapter start '
      'bookId=$bookId chapterIndex=$chapterIndex',
    );
    var chapter = await repository.fetchChapterAtIndex(
      bookId: bookId,
      chapterIndex: chapterIndex,
    );
    if (chapter == null) {
      throw ReaderChapterNotFoundException(bookId, chapterIndex);
    }
    final book = await repository.fetchBookById(bookId);
    if (book != null) {
      chapter = await _loadRemoteContentIfNeeded(book, chapter) ?? chapter;
    }
    return _chapterFromRecord(chapter);
  }

  Future<ReaderChapterRecord?> _loadRemoteContentIfNeeded(
    ReaderBookRecord book,
    ReaderChapterRecord chapter,
  ) async {
    final chapterUrl = chapter.url?.trim();
    log.i(
      '[reader-remote-content] check bookId=${book.id} title=${book.title} '
      'sourceId=${book.sourceId} chapterIndex=${chapter.chapterIndex} '
      'chapterTitle=${chapter.title} cached=${chapter.isCached} '
      'hasContent=${chapter.content?.trim().isNotEmpty ?? false} '
      'url=$chapterUrl',
    );
    if (chapter.isCached && (chapter.content?.trim().isNotEmpty ?? false)) {
      log.i(
        '[reader-remote-content] skip cached '
        'bookId=${book.id} chapterIndex=${chapter.chapterIndex}',
      );
      return null;
    }
    if (chapterUrl == null || chapterUrl.isEmpty) {
      log.w(
        '[reader-remote-content] skip empty chapter url '
        'bookId=${book.id} chapterIndex=${chapter.chapterIndex}',
      );
      return null;
    }
    final sourceId = book.sourceId?.trim();
    if (sourceId == null || sourceId.isEmpty) {
      log.w(
        '[reader-remote-content] skip empty sourceId '
        'bookId=${book.id} chapterIndex=${chapter.chapterIndex}',
      );
      return null;
    }
    final sourceRepository = this.sourceRepository;
    final ruleEngine = this.ruleEngine;
    if (sourceRepository == null || ruleEngine == null) {
      log.w(
        '[reader-remote-content] skip missing sourceRepository/ruleEngine '
        'bookId=${book.id} chapterIndex=${chapter.chapterIndex}',
      );
      return null;
    }

    final source = await sourceRepository.findSourceById(sourceId);
    if (source == null) {
      log.w(
        '[reader-remote-content] skip source not found '
        'sourceId=$sourceId bookId=${book.id}',
      );
      return null;
    }
    final rule = _parseSourceRule(source.rulesJson);
    if (rule == null || rule.content == null) {
      log.w(
        '[reader-remote-content] skip missing ruleContent '
        'sourceId=$sourceId bookId=${book.id}',
      );
      return null;
    }

    log.i(
      '[reader-remote-content] request content source=${source.name} '
      'sourceId=$sourceId chapterUrl=$chapterUrl '
      'contentRule=${_preview(rule.content?.content ?? '')}',
    );
    final content = await ruleEngine.loadContent(rule, chapterUrl);
    final rawContent = content?.content.trim();
    log.i(
      '[reader-remote-content] result bookId=${book.id} '
      'chapterIndex=${chapter.chapterIndex} title=${content?.title} '
      'contentChars=${rawContent?.length ?? 0} '
      'nextContentUrl=${content?.nextContentUrl} '
      'preview=${_preview(rawContent ?? '')}',
    );
    if (rawContent == null || rawContent.isEmpty) {
      log.w(
        '[reader-remote-content] empty parsed content '
        'bookId=${book.id} chapterIndex=${chapter.chapterIndex} '
        'chapterUrl=$chapterUrl',
      );
      return null;
    }

    final normalizedLength = normalizeReaderEngineText(
      rawContent,
      title: chapter.title,
    ).length;
    await repository.cacheChapterContent(
      bookId: chapter.bookId,
      chapterIndex: chapter.chapterIndex,
      content: rawContent,
      normalizedContentLength: normalizedLength,
    );
    return ReaderChapterRecord(
      id: chapter.id,
      bookId: chapter.bookId,
      chapterIndex: chapter.chapterIndex,
      title: chapter.title,
      url: chapter.url,
      content: rawContent,
      normalizedContentLength: normalizedLength,
      isCached: true,
    );
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

  String _preview(String value, {int maxLength = 400}) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLength) return compact;
    return '${compact.substring(0, maxLength)}...';
  }

  ReaderSourceType _sourceTypeFor(ReaderBookRecord book) {
    if (book.localPath != null) return ReaderSourceType.localTxt;
    if (book.sourceId != null) return ReaderSourceType.remoteNovel;
    return ReaderSourceType.plainText;
  }

  ReaderChapterMeta _chapterMetaFromRecord(ReaderChapterRecord chapter) {
    return ReaderChapterMeta(
      id: chapter.id,
      bookId: chapter.bookId,
      index: chapter.chapterIndex,
      title: chapter.title,
      normalizedContentLength: chapter.normalizedContentLength,
      isCached: chapter.isCached,
    );
  }

  ReaderChapter _chapterFromRecord(ReaderChapterRecord chapter) {
    final rawContent = chapter.content ?? '';
    final normalizedText = normalizeReaderEngineText(
      rawContent,
      title: chapter.title,
    );
    return ReaderChapter(
      id: chapter.id,
      bookId: chapter.bookId,
      index: chapter.chapterIndex,
      title: chapter.title,
      rawContent: rawContent,
      normalizedText: normalizedText,
      blocks: buildReaderContentBlocks(
        chapterIndex: chapter.chapterIndex,
        title: chapter.title,
        content: rawContent,
      ),
      metadata: {
        if (chapter.url != null) 'url': chapter.url,
        'isCached': chapter.isCached,
      },
    );
  }
}

class ReaderDocumentNotFoundException implements Exception {
  const ReaderDocumentNotFoundException(this.bookId);

  final String bookId;

  @override
  String toString() => 'ReaderDocumentNotFoundException($bookId)';
}

class ReaderChapterNotFoundException implements Exception {
  const ReaderChapterNotFoundException(this.bookId, this.chapterIndex);

  final String bookId;
  final int chapterIndex;

  @override
  String toString() {
    return 'ReaderChapterNotFoundException($bookId, $chapterIndex)';
  }
}
