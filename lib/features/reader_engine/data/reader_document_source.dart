import '../domain/reader_chapter.dart';
import '../domain/reader_document.dart';

abstract interface class ReaderDocumentSource {
  Future<ReaderDocument> loadDocument(String bookId);

  Future<ReaderChapterMetaPage> loadChapterMetas({
    required String bookId,
    required int offset,
    required int limit,
  });

  Future<ReaderChapter> loadChapter({
    required String bookId,
    required int chapterIndex,
  });
}

class ReaderChapterMetaPage {
  const ReaderChapterMetaPage({
    required this.items,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });

  final List<ReaderChapterMeta> items;
  final int offset;
  final int limit;
  final bool hasMore;
}

class ReaderChapterMeta {
  const ReaderChapterMeta({
    required this.id,
    required this.bookId,
    required this.index,
    required this.title,
    required this.normalizedContentLength,
    this.isCached = false,
  });

  final String id;
  final String bookId;
  final int index;
  final String title;
  final int normalizedContentLength;
  final bool isCached;
}
