import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'reader_text_normalizer.dart';

class BookshelfRepository {
  const BookshelfRepository(this.database);

  final AppDatabase database;

  Stream<List<Book>> watchShelfBooks() {
    final query = database.select(database.books)
      ..where((book) => book.inShelf.equals(true))
      ..orderBy([
        (book) => OrderingTerm(
              expression: book.sortOrder,
              mode: OrderingMode.desc,
            ),
        (book) => OrderingTerm(
              expression: book.updatedAt,
              mode: OrderingMode.desc,
            ),
      ]);
    return query.watch();
  }

  Stream<Book?> watchBookById(String bookId) {
    final query = database.select(database.books)
      ..where((book) => book.id.equals(bookId))
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Future<Book?> findBookById(String bookId) {
    final query = database.select(database.books)
      ..where((book) => book.id.equals(bookId))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Stream<List<Chapter>> watchChaptersForBook(String bookId) {
    final query = database.select(database.chapters)
      ..where((chapter) => chapter.bookId.equals(bookId))
      ..orderBy([
        (chapter) => OrderingTerm(
              expression: chapter.chapterIndex,
              mode: OrderingMode.asc,
            ),
      ]);
    return query.watch();
  }

  Stream<Chapter?> watchChapterContentForBookAtIndex({
    required String bookId,
    required int chapterIndex,
  }) {
    final query = database.select(database.chapters)
      ..where(
        (chapter) =>
            chapter.bookId.equals(bookId) &
            chapter.chapterIndex.equals(chapterIndex),
      )
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Future<Chapter?> fetchChapterContentForBookAtIndex({
    required String bookId,
    required int chapterIndex,
  }) {
    final query = database.select(database.chapters)
      ..where(
        (chapter) =>
            chapter.bookId.equals(bookId) &
            chapter.chapterIndex.equals(chapterIndex),
      )
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> cacheChapterContentForBookAtIndex({
    required String bookId,
    required int chapterIndex,
    required String content,
    required int normalizedContentLength,
  }) async {
    await (database.update(database.chapters)
          ..where(
            (chapter) =>
                chapter.bookId.equals(bookId) &
                chapter.chapterIndex.equals(chapterIndex),
          ))
        .write(
      ChaptersCompanion(
        content: Value(content),
        normalizedContentLength: Value(normalizedContentLength),
        isCached: const Value(true),
        fetchedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<int> watchChapterCount(String bookId) {
    final count = database.chapters.id.count();
    final query = database.selectOnly(database.chapters)
      ..addColumns([count])
      ..where(database.chapters.bookId.equals(bookId));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<int> fetchChapterCount(String bookId) {
    final count = database.chapters.id.count();
    final query = database.selectOnly(database.chapters)
      ..addColumns([count])
      ..where(database.chapters.bookId.equals(bookId));
    return query.getSingle().then((row) => row.read(count) ?? 0);
  }

  Stream<Chapter?> watchChapterMetaForBookAtIndex({
    required String bookId,
    required int chapterIndex,
  }) {
    final query = _chapterMetaQuery(bookId)
      ..where(database.chapters.chapterIndex.equals(chapterIndex))
      ..limit(1);
    return query.watchSingleOrNull().map(
          (row) => row == null ? null : _readChapterMeta(row),
        );
  }

  Future<Chapter?> fetchChapterMetaForBookAtIndex({
    required String bookId,
    required int chapterIndex,
  }) async {
    final query = _chapterMetaQuery(bookId)
      ..where(database.chapters.chapterIndex.equals(chapterIndex))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _readChapterMeta(row);
  }

  Future<List<Chapter>> fetchChapterMetasPage({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    final query = _chapterMetaQuery(bookId)..limit(limit, offset: offset);
    final rows = await query.get();
    return [for (final row in rows) _readChapterMeta(row)];
  }

  Stream<List<Chapter>> watchChapterMetasForBook(
    String bookId, {
    int? limit,
  }) {
    final query = _chapterMetaQuery(bookId);
    if (limit != null) query.limit(limit);
    return query.watch().map(
          (rows) => [for (final row in rows) _readChapterMeta(row)],
        );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _chapterMetaQuery(
      String bookId) {
    return database.selectOnly(database.chapters)
      ..addColumns([
        database.chapters.id,
        database.chapters.bookId,
        database.chapters.chapterIndex,
        database.chapters.title,
        database.chapters.url,
        database.chapters.normalizedContentLength,
        database.chapters.isCached,
        database.chapters.fetchedAt,
      ])
      ..where(database.chapters.bookId.equals(bookId))
      ..orderBy([
        OrderingTerm(
          expression: database.chapters.chapterIndex,
          mode: OrderingMode.asc,
        ),
      ]);
  }

  Chapter _readChapterMeta(TypedResult row) {
    return Chapter(
      id: row.read(database.chapters.id)!,
      bookId: row.read(database.chapters.bookId)!,
      chapterIndex: row.read(database.chapters.chapterIndex)!,
      title: row.read(database.chapters.title)!,
      url: row.read(database.chapters.url),
      content: null,
      normalizedContentLength:
          row.read(database.chapters.normalizedContentLength)!,
      isCached: row.read(database.chapters.isCached)!,
      fetchedAt: row.read(database.chapters.fetchedAt),
    );
  }

  Future<void> backfillNormalizedContentLengths(String bookId) async {
    const batchSize = 50;
    while (true) {
      final query = database.select(database.chapters)
        ..where(
          (chapter) =>
              chapter.bookId.equals(bookId) &
              chapter.normalizedContentLength.equals(0) &
              chapter.content.isNotNull(),
        )
        ..orderBy([
          (chapter) => OrderingTerm(
                expression: chapter.chapterIndex,
                mode: OrderingMode.asc,
              ),
        ])
        ..limit(batchSize);
      final chapters = await query.get();
      if (chapters.isEmpty) return;

      await database.batch((batch) {
        for (final chapter in chapters) {
          batch.update(
            database.chapters,
            ChaptersCompanion(
              normalizedContentLength: Value(
                normalizedReaderTextLength(chapter.content ?? ''),
              ),
            ),
            where: (table) => table.id.equals(chapter.id),
          );
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  Future<void> addBookToShelf(String bookId) async {
    final now = DateTime.now();
    await (database.update(database.books)
          ..where((book) => book.id.equals(bookId)))
        .write(
      BooksCompanion(
        inShelf: const Value(true),
        updatedAt: Value(now),
        sortOrder: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateReadingProgress({
    required String bookId,
    required int chapterIndex,
    required int readPosition,
  }) async {
    await (database.update(database.books)
          ..where((book) => book.id.equals(bookId)))
        .write(
      BooksCompanion(
        lastChapterIndex: Value(chapterIndex),
        lastReadPosition: Value(readPosition),
      ),
    );
  }

  Future<void> markBookRecentlyRead({
    required String bookId,
    required int chapterIndex,
    required int readPosition,
  }) async {
    final now = DateTime.now();
    await (database.update(database.books)
          ..where((book) => book.id.equals(bookId)))
        .write(
      BooksCompanion(
        lastChapterIndex: Value(chapterIndex),
        lastReadPosition: Value(readPosition),
        updatedAt: Value(now),
        sortOrder: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<Book?> findLocalBookByTitle(String title) async {
    final query = database.select(database.books)
      ..where((book) => book.title.equals(title) & book.localPath.isNotNull())
      ..orderBy([
        (book) => OrderingTerm(
              expression: book.updatedAt,
              mode: OrderingMode.desc,
            ),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> insertImportedTxtBook({
    required BooksCompanion book,
    required List<ChaptersCompanion> chapters,
  }) async {
    await replaceImportedTxtBook(
      replacedBookIds: const {},
      book: book,
      chapters: chapters,
    );
  }

  Future<void> upsertRemoteBook({
    required BooksCompanion book,
    required List<ChaptersCompanion> chapters,
  }) async {
    final bookId = book.id.value;
    await database.transaction(() async {
      await database.into(database.books).insertOnConflictUpdate(book);
      await (database.delete(database.chapters)
            ..where((chapter) => chapter.bookId.equals(bookId)))
          .go();
      if (chapters.isNotEmpty) {
        await database.batch((batch) {
          batch.insertAll(database.chapters, chapters);
        });
      }
    });
  }

  Future<void> appendRemoteBookChapters({
    required String bookId,
    required List<ChaptersCompanion> chapters,
    int? remoteChapterCount,
    String? remoteNextTocUrl,
  }) async {
    await database.transaction(() async {
      await (database.update(database.books)
            ..where((book) => book.id.equals(bookId)))
          .write(
        BooksCompanion(
          remoteChapterCount: Value(remoteChapterCount),
          remoteNextTocUrl: Value(remoteNextTocUrl),
          updatedAt: Value(DateTime.now()),
        ),
      );
      if (chapters.isNotEmpty) {
        await database.batch((batch) {
          for (final chapter in chapters) {
            batch.insert(
              database.chapters,
              chapter,
              mode: InsertMode.insertOrReplace,
            );
          }
        });
      }
    });
  }

  Future<void> replaceImportedTxtBook({
    required Set<String> replacedBookIds,
    required BooksCompanion book,
    required List<ChaptersCompanion> chapters,
  }) async {
    await database.transaction(() async {
      if (replacedBookIds.isNotEmpty) {
        await (database.delete(database.readingSessions)
              ..where((session) => session.bookId.isIn(replacedBookIds)))
            .go();
        await (database.delete(database.books)
              ..where(
                (book) =>
                    book.id.isIn(replacedBookIds) & book.localPath.isNotNull(),
              ))
            .go();
      }
      await database.into(database.books).insert(book);
      if (chapters.isNotEmpty) {
        await database.batch((batch) {
          batch.insertAll(database.chapters, chapters);
        });
      }
    });
  }

  Future<void> replaceChaptersForBook({
    required String bookId,
    required List<ChaptersCompanion> chapters,
  }) async {
    await database.transaction(() async {
      await (database.delete(database.chapters)
            ..where((chapter) => chapter.bookId.equals(bookId)))
          .go();
      if (chapters.isNotEmpty) {
        await database.batch((batch) {
          batch.insertAll(database.chapters, chapters);
        });
      }
    });
  }

  Future<List<Book>> deleteLocalBooksByIds(Set<String> ids) async {
    if (ids.isEmpty) return const [];

    return database.transaction(() async {
      final booksToDelete = await (database.select(database.books)
            ..where((book) => book.id.isIn(ids) & book.localPath.isNotNull()))
          .get();
      final localIds = booksToDelete.map((book) => book.id).toList();
      if (localIds.isEmpty) return const <Book>[];

      await (database.delete(database.readingSessions)
            ..where((session) => session.bookId.isIn(localIds)))
          .go();
      await (database.delete(database.books)
            ..where((book) => book.id.isIn(localIds)))
          .go();

      return booksToDelete;
    });
  }
}
