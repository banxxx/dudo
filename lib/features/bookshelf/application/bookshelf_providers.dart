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

final localBookImportServiceProvider = Provider<LocalBookImportService>((ref) {
  return LocalBookImportService(
    repository: ref.watch(bookshelfRepositoryProvider),
  );
});
