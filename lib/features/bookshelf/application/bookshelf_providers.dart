import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/bookshelf_repository.dart';
import '../data/local_book_import_service.dart';

final bookshelfTipsDismissedProvider = StateProvider<bool>((_) => false);

final bookshelfRepositoryProvider = Provider<BookshelfRepository>((ref) {
  return BookshelfRepository(ref.watch(appDatabaseProvider));
});

final shelfBooksProvider = StreamProvider<List<Book>>((ref) {
  return ref.watch(bookshelfRepositoryProvider).watchShelfBooks();
});

final bookByIdProvider = StreamProvider.family<Book?, String>((ref, bookId) {
  return ref.watch(bookshelfRepositoryProvider).watchBookById(bookId);
});

final bookChaptersProvider =
    StreamProvider.family<List<Chapter>, String>((ref, bookId) {
  return ref.watch(bookshelfRepositoryProvider).watchChaptersForBook(bookId);
});

final localBookDuplicateProvider =
    FutureProvider.family<Book?, String>((ref, title) {
  return ref.watch(bookshelfRepositoryProvider).findLocalBookByTitle(title);
});

final localBookImportServiceProvider = Provider<LocalBookImporter>((ref) {
  return LocalBookImportService(
    repository: ref.watch(bookshelfRepositoryProvider),
  );
});
