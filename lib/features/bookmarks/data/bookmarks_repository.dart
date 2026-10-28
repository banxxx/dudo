import '../../../core/database/app_database.dart';
import '../domain/bookmark_entry.dart';

/// Reads bookmarks and notes from every book in one time-ordered list.
class BookmarksRepository {
  const BookmarksRepository(this.database);

  final AppDatabase database;

  Stream<List<BookmarkEntry>> watchEntries() {
    return database
        .customSelect(
          _entriesQuery,
          readsFrom: {
            database.bookmarks,
            database.notes,
            database.books,
            database.chapters,
          },
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              BookmarkEntry(
                id: row.read<String>('entry_id'),
                type: _typeFor(row.read<String>('entry_kind')),
                bookId: row.read<String>('book_id'),
                bookTitle: row.read<String>('book_title'),
                chapterIndex: row.read<int>('chapter_index'),
                chapterTitle: row.read<String>('chapter_title'),
                offset: row.read<int>('entry_offset'),
                preview: row.read<String>('preview'),
                note: row.read<String?>('note'),
                createdAt: row.read<DateTime>('created_at'),
              ),
          ],
        );
  }

  Future<void> deleteEntry(BookmarkEntry entry) async {
    if (entry.type == BookmarkEntryType.bookmark) {
      await (database.delete(database.bookmarks)
            ..where((bookmark) => bookmark.id.equals(entry.id)))
          .go();
      return;
    }
    await (database.delete(database.notes)
          ..where((note) => note.id.equals(entry.id)))
        .go();
  }

  BookmarkEntryType _typeFor(String kind) {
    switch (kind) {
      case 'bookmark':
        return BookmarkEntryType.bookmark;
      case 'note':
        return BookmarkEntryType.note;
      case 'highlight':
      default:
        return BookmarkEntryType.highlight;
    }
  }
}

const _entriesQuery = '''
SELECT
  bm.id AS entry_id,
  'bookmark' AS entry_kind,
  bm.book_id AS book_id,
  books.title AS book_title,
  ch.idx AS chapter_index,
  ch.title AS chapter_title,
  bm.position AS entry_offset,
  COALESCE(bm.preview, '') AS preview,
  NULL AS note,
  bm.created_at AS created_at
FROM bookmarks bm
JOIN books ON books.id = bm.book_id
JOIN chapters ch ON ch.id = bm.chapter_id
UNION ALL
SELECT
  n.id AS entry_id,
  CASE WHEN n.note IS NULL OR n.note = '' THEN 'highlight' ELSE 'note' END
    AS entry_kind,
  n.book_id AS book_id,
  books.title AS book_title,
  ch.idx AS chapter_index,
  ch.title AS chapter_title,
  n.start_offset AS entry_offset,
  n.content AS preview,
  n.note AS note,
  n.created_at AS created_at
FROM notes n
JOIN books ON books.id = n.book_id
JOIN chapters ch ON ch.id = n.chapter_id
ORDER BY created_at DESC
''';
