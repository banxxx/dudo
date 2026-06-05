import '../../bookshelf/data/bookshelf_repository.dart';
import '../domain/reader_location.dart';
import 'reader_progress_repository.dart';

class BookshelfReaderProgressRepository implements ReaderProgressRepository {
  const BookshelfReaderProgressRepository(this.repository);

  final BookshelfRepository repository;

  @override
  Future<ReaderLocation?> loadProgress(String bookId) async {
    final book = await repository.watchBookById(bookId).first;
    if (book == null) return null;
    return ReaderLocation(
      bookId: book.id,
      chapterIndex: book.lastChapterIndex,
      offset: book.lastReadPosition,
    );
  }

  @override
  Future<void> saveProgress(ReaderLocation location) {
    return repository.markBookRecentlyRead(
      bookId: location.bookId,
      chapterIndex: location.chapterIndex,
      readPosition: location.offset,
    );
  }
}
