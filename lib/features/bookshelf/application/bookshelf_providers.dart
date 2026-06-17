import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/rule_engine/rule_engine.dart';
import '../../search/application/search_providers.dart';
import '../../sources/application/source_providers.dart';
import '../data/bookshelf_repository.dart';
import '../data/local_book_chapter_analysis_service.dart';
import '../data/local_book_import_service.dart';
import '../data/remote_book_import_service.dart';

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

final bookChapterCountProvider =
    StreamProvider.family<int, String>((ref, bookId) {
  return ref.watch(bookshelfRepositoryProvider).watchChapterCount(bookId);
});

final currentBookChapterContentProvider =
    StreamProvider.family<Chapter?, CurrentBookChapterKey>((ref, key) {
  return ref
      .watch(bookshelfRepositoryProvider)
      .watchChapterContentForBookAtIndex(
        bookId: key.bookId,
        chapterIndex: key.chapterIndex,
      );
});

final currentBookChapterMetaProvider =
    StreamProvider.family<Chapter?, CurrentBookChapterKey>((ref, key) {
  return ref.watch(bookshelfRepositoryProvider).watchChapterMetaForBookAtIndex(
        bookId: key.bookId,
        chapterIndex: key.chapterIndex,
      );
});

class CurrentBookChapterKey {
  const CurrentBookChapterKey({
    required this.bookId,
    required this.chapterIndex,
  });

  final String bookId;
  final int chapterIndex;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CurrentBookChapterKey &&
            other.bookId == bookId &&
            other.chapterIndex == chapterIndex;
  }

  @override
  int get hashCode => Object.hash(bookId, chapterIndex);
}

final bookChapterMetasProvider =
    StreamProvider.family<List<Chapter>, String>((ref, bookId) {
  return ref
      .watch(bookshelfRepositoryProvider)
      .watchChapterMetasForBook(bookId);
});

final initialBookChapterMetasProvider =
    StreamProvider.family<List<Chapter>, String>((ref, bookId) {
  return ref
      .watch(bookshelfRepositoryProvider)
      .watchChapterMetasForBook(bookId, limit: 30);
});

final localBookDuplicateProvider =
    FutureProvider.family<Book?, String>((ref, title) {
  return ref.watch(bookshelfRepositoryProvider).findLocalBookByTitle(title);
});

final localBookImportServiceProvider = Provider<LocalBookImporter>((ref) {
  return LocalBookImportService(
    repository: ref.watch(bookshelfRepositoryProvider),
    chapterAnalysisService: ref.watch(localBookChapterAnalysisServiceProvider),
  );
});

final localBookChapterAnalysisServiceProvider =
    Provider<LocalBookChapterAnalysisService>((ref) {
  return LocalBookChapterAnalysisService(
    repository: ref.watch(bookshelfRepositoryProvider),
  );
});

final remoteBookImportServiceProvider =
    Provider<RemoteBookImportService>((ref) {
  final cookieStore = ref.watch(legadoCookieStoreProvider).valueOrNull;
  return RemoteBookImportService(
    bookshelfRepository: ref.watch(bookshelfRepositoryProvider),
    sourceRepository: ref.watch(sourceRepositoryProvider),
    ruleEngine: RuleEngine.create(cookieStore: cookieStore),
  );
});
