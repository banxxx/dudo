import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/reader_annotation.dart';
import '../domain/reader_location.dart';
import '../domain/reader_range.dart';
import 'reader_annotation_repository.dart';

class BookshelfReaderAnnotationRepository
    implements ReaderAnnotationRepository {
  const BookshelfReaderAnnotationRepository(this.database);

  final AppDatabase database;

  @override
  Future<List<ReaderAnnotation>> loadAnnotations(String bookId) async {
    final chapters = await (database.select(database.chapters)
          ..where((chapter) => chapter.bookId.equals(bookId)))
        .get();
    final chapterIndexesById = {
      for (final chapter in chapters) chapter.id: chapter.chapterIndex,
    };

    final bookmarks = await (database.select(database.bookmarks)
          ..where((bookmark) => bookmark.bookId.equals(bookId)))
        .get();
    final notes = await (database.select(database.notes)
          ..where((note) => note.bookId.equals(bookId)))
        .get();

    return [
      for (final bookmark in bookmarks)
        if (chapterIndexesById[bookmark.chapterId] case final int chapterIndex)
          _bookmarkAnnotation(bookmark, chapterIndex),
      for (final note in notes)
        if (chapterIndexesById[note.chapterId] case final int chapterIndex)
          _noteAnnotation(note, chapterIndex),
    ];
  }

  @override
  Future<void> saveAnnotation(ReaderAnnotation annotation) async {
    final chapterId = await _chapterIdFor(
      bookId: annotation.bookId,
      chapterIndex: annotation.range.start.chapterIndex,
    );
    if (chapterId == null) return;

    switch (annotation.type) {
      case ReaderAnnotationType.bookmark:
        await database.into(database.bookmarks).insertOnConflictUpdate(
              BookmarksCompanion.insert(
                id: annotation.id,
                bookId: annotation.bookId,
                chapterId: chapterId,
                position: annotation.range.start.offset,
                preview: Value(annotation.preview),
                createdAt: Value(annotation.createdAt),
              ),
            );
      case ReaderAnnotationType.highlight:
      case ReaderAnnotationType.note:
        await database.into(database.notes).insertOnConflictUpdate(
              NotesCompanion.insert(
                id: annotation.id,
                bookId: annotation.bookId,
                chapterId: chapterId,
                startOffset: annotation.range.start.offset,
                endOffset: annotation.range.end.offset,
                content: annotation.preview,
                note: Value(annotation.note),
                color: Value(annotation.color),
                createdAt: Value(annotation.createdAt),
              ),
            );
    }
  }

  @override
  Future<void> deleteAnnotation(String annotationId) async {
    await (database.delete(database.bookmarks)
          ..where((bookmark) => bookmark.id.equals(annotationId)))
        .go();
    await (database.delete(database.notes)
          ..where((note) => note.id.equals(annotationId)))
        .go();
  }

  ReaderAnnotation _bookmarkAnnotation(Bookmark bookmark, int chapterIndex) {
    final location = ReaderLocation(
      bookId: bookmark.bookId,
      chapterIndex: chapterIndex,
      offset: bookmark.position,
    );
    return ReaderAnnotation(
      id: bookmark.id,
      bookId: bookmark.bookId,
      range: ReaderRange(start: location, end: location),
      type: ReaderAnnotationType.bookmark,
      preview: bookmark.preview ?? '',
      createdAt: bookmark.createdAt,
    );
  }

  ReaderAnnotation _noteAnnotation(Note note, int chapterIndex) {
    return ReaderAnnotation(
      id: note.id,
      bookId: note.bookId,
      range: ReaderRange(
        start: ReaderLocation(
          bookId: note.bookId,
          chapterIndex: chapterIndex,
          offset: note.startOffset,
        ),
        end: ReaderLocation(
          bookId: note.bookId,
          chapterIndex: chapterIndex,
          offset: note.endOffset,
        ),
      ),
      type: note.note == null || note.note!.isEmpty
          ? ReaderAnnotationType.highlight
          : ReaderAnnotationType.note,
      preview: note.content,
      note: note.note,
      color: note.color,
      createdAt: note.createdAt,
    );
  }

  Future<String?> _chapterIdFor({
    required String bookId,
    required int chapterIndex,
  }) async {
    final chapter = await (database.select(database.chapters)
          ..where(
            (chapter) =>
                chapter.bookId.equals(bookId) &
                chapter.chapterIndex.equals(chapterIndex),
          )
          ..limit(1))
        .getSingleOrNull();
    return chapter?.id;
  }
}
