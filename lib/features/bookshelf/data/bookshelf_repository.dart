import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

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

  Future<void> insertImportedTxtBook({
    required BooksCompanion book,
    required ChaptersCompanion chapter,
  }) async {
    await database.transaction(() async {
      await database.into(database.books).insert(book);
      await database.into(database.chapters).insert(chapter);
    });
  }
}
