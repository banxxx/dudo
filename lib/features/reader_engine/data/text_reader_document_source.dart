import '../domain/reader_chapter.dart';
import '../domain/reader_document.dart';
import '../domain/reader_source_type.dart';
import 'reader_content_parser.dart';
import 'reader_document_source.dart';
import 'text_reader_book_repository.dart';

class TextReaderDocumentSource implements ReaderDocumentSource {
  const TextReaderDocumentSource(this.repository);

  final TextReaderBookRepository repository;

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
    final chapter = await repository.fetchChapterAtIndex(
      bookId: bookId,
      chapterIndex: chapterIndex,
    );
    if (chapter == null) {
      throw ReaderChapterNotFoundException(bookId, chapterIndex);
    }
    return _chapterFromRecord(chapter);
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
