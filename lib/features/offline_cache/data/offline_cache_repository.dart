import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/offline_cache.dart';

/// Aggregates the downloaded chapter content the reader has stored locally.
class OfflineCacheRepository {
  const OfflineCacheRepository(this.database);

  final AppDatabase database;

  Future<OfflineCache> measure() async {
    final chapterCount = database.chapters.id.count();
    final totalBytes = database.chapters.normalizedContentLength.sum();

    final query = database.selectOnly(database.chapters)
      ..addColumns([database.chapters.bookId, chapterCount, totalBytes])
      ..where(database.chapters.isCached.equals(true))
      ..groupBy([database.chapters.bookId]);
    final rows = await query.get();

    final bookIds = [
      for (final row in rows) row.read(database.chapters.bookId)!,
    ];
    if (bookIds.isEmpty) return const OfflineCache(books: []);

    final bookRows = await (database.select(database.books)
          ..where((book) => book.id.isIn(bookIds)))
        .get();
    final bookById = {for (final book in bookRows) book.id: book};

    final books = <OfflineCacheBook>[
      for (final row in rows)
        OfflineCacheBook(
          bookId: row.read(database.chapters.bookId)!,
          title: bookById[row.read(database.chapters.bookId)!]?.title ?? '未知书名',
          author: bookById[row.read(database.chapters.bookId)!]?.author,
          chapterCount: row.read(chapterCount) ?? 0,
          bytes: row.read(totalBytes) ?? 0,
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

  static const _clearedCompanion = ChaptersCompanion(
    content: Value(null),
    normalizedContentLength: Value(0),
    isCached: Value(false),
    fetchedAt: Value(null),
  );
}
