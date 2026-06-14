import '../../bookshelf/data/bookshelf_repository.dart';
import '../../../core/database/app_database.dart';

abstract interface class TextReaderBookRepository {
  Future<ReaderBookRecord?> fetchBookById(String bookId);

  Future<int> fetchChapterCount(String bookId);

  Future<List<ReaderChapterRecord>> fetchChapterMetasPage({
    required String bookId,
    required int offset,
    required int limit,
  });

  Future<ReaderChapterRecord?> fetchChapterAtIndex({
    required String bookId,
    required int chapterIndex,
  });

  Future<void> cacheChapterContent({
    required String bookId,
    required int chapterIndex,
    required String content,
    required int normalizedContentLength,
  });
}

class BookshelfTextReaderBookRepository implements TextReaderBookRepository {
  const BookshelfTextReaderBookRepository(this.repository);

  final BookshelfRepository repository;

  @override
  Future<ReaderBookRecord?> fetchBookById(String bookId) async {
    final book = await repository.watchBookById(bookId).first;
    if (book == null) return null;
    return ReaderBookRecord(
      id: book.id,
      title: book.title,
      author: book.author,
      coverUrl: book.coverUrl,
      sourceId: book.sourceId,
      sourceBookUrl: book.sourceBookUrl,
      localPath: book.localPath,
    );
  }

  @override
  Future<int> fetchChapterCount(String bookId) {
    return repository.watchChapterCount(bookId).first;
  }

  @override
  Future<List<ReaderChapterRecord>> fetchChapterMetasPage({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    final chapters = await repository.fetchChapterMetasPage(
      bookId: bookId,
      offset: offset,
      limit: limit,
    );
    return chapters.map(ReaderChapterRecord.fromDbChapter).toList();
  }

  @override
  Future<ReaderChapterRecord?> fetchChapterAtIndex({
    required String bookId,
    required int chapterIndex,
  }) async {
    final chapter = await repository.fetchChapterContentForBookAtIndex(
      bookId: bookId,
      chapterIndex: chapterIndex,
    );
    return chapter == null ? null : ReaderChapterRecord.fromDbChapter(chapter);
  }

  @override
  Future<void> cacheChapterContent({
    required String bookId,
    required int chapterIndex,
    required String content,
    required int normalizedContentLength,
  }) {
    return repository.cacheChapterContentForBookAtIndex(
      bookId: bookId,
      chapterIndex: chapterIndex,
      content: content,
      normalizedContentLength: normalizedContentLength,
    );
  }
}

class ReaderBookRecord {
  const ReaderBookRecord({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    this.sourceId,
    this.sourceBookUrl,
    this.localPath,
  });

  final String id;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? sourceId;
  final String? sourceBookUrl;
  final String? localPath;
}

class ReaderChapterRecord {
  const ReaderChapterRecord({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.title,
    required this.normalizedContentLength,
    required this.isCached,
    this.url,
    this.content,
  });

  factory ReaderChapterRecord.fromDbChapter(Chapter chapter) {
    return ReaderChapterRecord(
      id: chapter.id,
      bookId: chapter.bookId,
      chapterIndex: chapter.chapterIndex,
      title: chapter.title,
      url: chapter.url,
      content: chapter.content,
      normalizedContentLength: chapter.normalizedContentLength,
      isCached: chapter.isCached,
    );
  }

  final String id;
  final String bookId;
  final int chapterIndex;
  final String title;
  final String? url;
  final String? content;
  final int normalizedContentLength;
  final bool isCached;
}
