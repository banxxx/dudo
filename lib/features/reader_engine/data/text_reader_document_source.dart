import 'dart:convert';

import '../../../core/rule_engine/models/source_rule.dart';
import '../../../core/rule_engine/rule_engine.dart';
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
    if (chapter.isCached && (chapter.content?.trim().isNotEmpty ?? false)) {
      return null;
    }
    if (chapterUrl == null || chapterUrl.isEmpty) return null;
    final sourceId = book.sourceId?.trim();
    if (sourceId == null || sourceId.isEmpty) return null;
    final sourceRepository = this.sourceRepository;
    final ruleEngine = this.ruleEngine;
    if (sourceRepository == null || ruleEngine == null) return null;

    final source = await sourceRepository.findSourceById(sourceId);
    if (source == null) return null;
    final rule = _parseSourceRule(source.rulesJson);
    if (rule == null || rule.content == null) return null;

    final content = await ruleEngine.loadContent(rule, chapterUrl);
    final rawContent = content?.content.trim();
    if (rawContent == null || rawContent.isEmpty) return null;

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
