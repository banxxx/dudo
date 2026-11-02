import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/offline_cache.dart';

/// Aggregates the downloaded chapter content the reader has stored locally.
class OfflineCacheRepository {
  const OfflineCacheRepository(this.database);

  final AppDatabase database;

  Future<OfflineCache> measure() async {
    // Measure the UTF-8 bytes of the stored text, not the character count used
    // for reading progress. `normalizedContentLength` is a reader metric and
    // would under-report non-ASCII content.
    final rows = await database.customSelect(
      'SELECT book_id, COUNT(*) AS chapter_count, '
      'COALESCE(SUM(length(CAST(content AS BLOB))), 0) AS total_bytes '
      'FROM chapters WHERE is_cached = 1 GROUP BY book_id',
      readsFrom: {database.chapters},
    ).get();

    if (rows.isEmpty) return const OfflineCache(books: []);

    final bookIds = [
      for (final row in rows) row.read<String>('book_id'),
    ];
    final bookRows = await (database.select(database.books)
          ..where((book) => book.id.isIn(bookIds)))
        .get();
    final bookById = {for (final book in bookRows) book.id: book};

    final books = <OfflineCacheBook>[
      for (final row in rows)
        OfflineCacheBook(
          bookId: row.read<String>('book_id'),
          title: bookById[row.read<String>('book_id')]?.title ?? '未知书名',
          author: bookById[row.read<String>('book_id')]?.author,
          chapterCount: row.read<int>('chapter_count'),
          bytes: row.read<int>('total_bytes'),
        ),
    ];

    // Largest footprint first so the top of the list is what matters most.
    books.sort((a, b) => b.bytes.compareTo(a.bytes));
    return OfflineCache(books: books);
  }

  Future<void> clearBook(String bookId) async {
    await (database.update(database.chapters)
          ..where(
            (chapter) =>
                chapter.bookId.equals(bookId) & chapter.isCached.equals(true),
          ))
        .write(_clearedCompanion);
  }

  Future<void> clearAll() async {
    await (database.update(database.chapters)
          ..where((chapter) => chapter.isCached.equals(true)))
        .write(_clearedCompanion);
  }

  /// Clears the selected books and rewrites the database file so the freed
  /// pages are returned to the device. Compaction is best effort: the content
  /// is already gone if the VACUUM cannot run.
  Future<void> clearBooksAndCompact(Iterable<String> bookIds) async {
    final ids = bookIds.toList(growable: false);
    if (ids.isEmpty) return;
    await (database.update(database.chapters)
          ..where(
            (chapter) =>
                chapter.bookId.isIn(ids) & chapter.isCached.equals(true),
          ))
        .write(_clearedCompanion);
    await _compact();
  }

  /// Clears every cached chapter and then rewrites the database file so the
  /// freed pages are actually returned to the device. Compaction is best
  /// effort: the content is already gone if the VACUUM cannot run.
  Future<void> clearAllAndCompact() async {
    await clearAll();
    await _compact();
  }

  Future<void> _compact() async {
    try {
      await database.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      await database.customStatement('VACUUM');
    } catch (_) {
      // The chapter content is already cleared; compaction can wait.
    }
  }

  static const _clearedCompanion = ChaptersCompanion(
    content: Value(null),
    normalizedContentLength: Value(0),
    isCached: Value(false),
    fetchedAt: Value(null),
  );
}
