import '../domain/reader_chapter.dart';

abstract interface class ChapterContentLoader {
  Future<ReaderChapter> load({
    required String bookId,
    required int chapterIndex,
  });
}
