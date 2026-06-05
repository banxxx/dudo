import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html_parser;

import '../domain/reader_chapter.dart';
import '../domain/reader_content_block.dart';
import '../domain/reader_document.dart';
import '../domain/reader_source_type.dart';
import 'reader_content_parser.dart';
import 'reader_document_source.dart';

abstract interface class EpubBookLoader {
  Future<EpubBook> load(String bookId);
}

class FileEpubBookLoader implements EpubBookLoader {
  const FileEpubBookLoader(this.pathsByBookId);

  final Map<String, String> pathsByBookId;

  @override
  Future<EpubBook> load(String bookId) async {
    final path = pathsByBookId[bookId];
    if (path == null) throw EpubBookNotFoundException(bookId);
    final bytes = await File(path).readAsBytes();
    return EpubReader.readBook(bytes);
  }
}

class EpubReaderDocumentSource implements ReaderDocumentSource {
  EpubReaderDocumentSource({
    required this.loader,
  });

  final EpubBookLoader loader;
  final _cache = <String, _EpubDocumentCache>{};

  @override
  Future<ReaderDocument> loadDocument(String bookId) async {
    final cache = await _load(bookId);
    return ReaderDocument(
      bookId: bookId,
      title: cache.book.Title?.trim().isNotEmpty == true
          ? cache.book.Title!.trim()
          : '未命名 EPUB',
      sourceType: ReaderSourceType.epub,
      chapterCount: cache.chapters.length,
      metadata: {
        if (cache.book.Author != null) 'author': cache.book.Author,
      },
    );
  }

  @override
  Future<ReaderChapterMetaPage> loadChapterMetas({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    final cache = await _load(bookId);
    final items = cache.chapters
        .skip(offset)
        .take(limit)
        .map(
          (chapter) => ReaderChapterMeta(
            id: _chapterId(bookId, chapter.index),
            bookId: bookId,
            index: chapter.index,
            title: chapter.title,
            normalizedContentLength: chapter.normalizedText.length,
            isCached: true,
          ),
        )
        .toList(growable: false);
    return ReaderChapterMetaPage(
      items: items,
      offset: offset,
      limit: limit,
      hasMore: offset + limit < cache.chapters.length,
    );
  }

  @override
  Future<ReaderChapter> loadChapter({
    required String bookId,
    required int chapterIndex,
  }) async {
    final cache = await _load(bookId);
    if (chapterIndex < 0 || chapterIndex >= cache.chapters.length) {
      throw EpubChapterNotFoundException(bookId, chapterIndex);
    }
    final chapter = cache.chapters[chapterIndex];
    return ReaderChapter(
      id: _chapterId(bookId, chapter.index),
      bookId: bookId,
      index: chapter.index,
      title: chapter.title,
      rawContent: chapter.htmlContent,
      normalizedText: chapter.normalizedText,
      blocks: chapter.blocks,
      metadata: {
        if (chapter.href != null) 'epubHref': chapter.href,
        if (chapter.anchor != null) 'epubAnchor': chapter.anchor,
      },
    );
  }

  Future<_EpubDocumentCache> _load(String bookId) async {
    final cached = _cache[bookId];
    if (cached != null) return cached;
    final book = await loader.load(bookId);
    final chapters = _flattenChapters(bookId, book);
    final cache = _EpubDocumentCache(book: book, chapters: chapters);
    _cache[bookId] = cache;
    return cache;
  }

  List<_EpubChapterRecord> _flattenChapters(String bookId, EpubBook book) {
    final records = <_EpubChapterRecord>[];
    void visit(EpubChapter chapter) {
      final html = chapter.HtmlContent ?? '';
      final title = chapter.Title?.trim().isNotEmpty == true
          ? chapter.Title!.trim()
          : '第 ${records.length + 1} 章';
      final textParagraphs = _extractParagraphs(html);
      final paragraphs = withoutDuplicateReaderEngineTitleParagraph(
        title: title,
        paragraphs: textParagraphs,
      );
      final normalizedText = paragraphs.join('\n\n');
      final blocks = _blocksFromParagraphs(
        chapterIndex: records.length,
        title: title,
        paragraphs: paragraphs,
      );
      records.add(
        _EpubChapterRecord(
          index: records.length,
          title: title,
          htmlContent: html,
          normalizedText: normalizedText,
          blocks: blocks,
          href: chapter.ContentFileName,
          anchor: chapter.Anchor,
        ),
      );
      for (final subChapter in chapter.SubChapters ?? const <EpubChapter>[]) {
        visit(subChapter);
      }
    }

    for (final chapter in book.Chapters ?? const <EpubChapter>[]) {
      visit(chapter);
    }
    if (records.isNotEmpty) return records;

    final htmlFiles =
        book.Content?.Html ?? const <String, EpubTextContentFile>{};
    for (final entry in htmlFiles.entries) {
      final html = entry.value.Content ?? '';
      final title = entry.value.FileName ?? entry.key;
      final paragraphs = withoutDuplicateReaderEngineTitleParagraph(
        title: title,
        paragraphs: _extractParagraphs(html),
      );
      records.add(
        _EpubChapterRecord(
          index: records.length,
          title: title,
          htmlContent: html,
          normalizedText: normalizeReaderEngineText(paragraphs.join('\n')),
          blocks: _blocksFromParagraphs(
            chapterIndex: records.length,
            title: title,
            paragraphs: paragraphs,
          ),
          href: entry.key,
        ),
      );
    }
    return records;
  }

  List<String> _extractParagraphs(String html) {
    final document = html_parser.parse(html);
    final nodes = document.querySelectorAll('p,li,blockquote');
    final paragraphs = nodes
        .map((node) => node.text.trim().replaceAll(RegExp(r'\s+'), ' '))
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
    if (paragraphs.isNotEmpty) return paragraphs;
    final bodyText = document.body?.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return bodyText == null || bodyText.isEmpty ? const [] : [bodyText];
  }

  List<ReaderContentBlock> _blocksFromParagraphs({
    required int chapterIndex,
    required String title,
    required List<String> paragraphs,
  }) {
    final blocks = <ReaderContentBlock>[
      ReaderHeadingBlock(
        blockId: 'c$chapterIndex-heading',
        chapterIndex: chapterIndex,
        startOffset: 0,
        endOffset: 0,
        text: title,
      ),
    ];
    var offset = 0;
    for (var i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      final startOffset = offset;
      final endOffset = startOffset + paragraph.length;
      blocks.add(
        ReaderParagraphBlock(
          blockId: 'c$chapterIndex-p$i',
          chapterIndex: chapterIndex,
          startOffset: startOffset,
          endOffset: endOffset,
          text: paragraph,
          paragraphIndex: i,
        ),
      );
      offset = endOffset;
      if (i + 1 < paragraphs.length) offset += 2;
    }
    return blocks;
  }

  String _chapterId(String bookId, int index) => '$bookId-epub-$index';
}

class EpubBookNotFoundException implements Exception {
  const EpubBookNotFoundException(this.bookId);

  final String bookId;

  @override
  String toString() => 'EpubBookNotFoundException($bookId)';
}

class EpubChapterNotFoundException implements Exception {
  const EpubChapterNotFoundException(this.bookId, this.chapterIndex);

  final String bookId;
  final int chapterIndex;

  @override
  String toString() => 'EpubChapterNotFoundException($bookId, $chapterIndex)';
}

class _EpubDocumentCache {
  const _EpubDocumentCache({
    required this.book,
    required this.chapters,
  });

  final EpubBook book;
  final List<_EpubChapterRecord> chapters;
}

class _EpubChapterRecord {
  const _EpubChapterRecord({
    required this.index,
    required this.title,
    required this.htmlContent,
    required this.normalizedText,
    required this.blocks,
    this.href,
    this.anchor,
  });

  final int index;
  final String title;
  final String htmlContent;
  final String normalizedText;
  final List<ReaderContentBlock> blocks;
  final String? href;
  final String? anchor;
}
