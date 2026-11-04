import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../bookshelf/application/bookshelf_providers.dart';
import '../data/reading_history_repository.dart';
import '../domain/reading_history_entry.dart';

final readingHistoryRepositoryProvider =
    Provider<ReadingHistoryRepository>((ref) {
  return DriftReadingHistoryRepository(ref.watch(appDatabaseProvider));
});

final readingHistoryClearedAtProvider = FutureProvider<DateTime?>((ref) {
  return ref.watch(readingHistoryRepositoryProvider).loadClearedAt();
});

/// Books the reader has actually started, newest first.
///
/// The shelf stream already refreshes whenever a book's progress changes, so
/// the list follows the reader without a manual reload.
final readingHistoryProvider =
    FutureProvider<List<ReadingHistoryEntry>>((ref) async {
  final books = await ref.watch(shelfBooksProvider.future);
  final clearedAt = await ref.watch(readingHistoryClearedAtProvider.future);
  final bookshelf = ref.watch(bookshelfRepositoryProvider);

  final entries = <ReadingHistoryEntry>[];
  for (final book in books) {
    if (book.lastChapterIndex <= 0 && book.lastReadPosition <= 0) continue;
    if (clearedAt != null && !book.updatedAt.isAfter(clearedAt)) continue;

    final chapterCount = await bookshelf.fetchChapterCount(book.id);
    final chapter = await bookshelf.fetchChapterMetaForBookAtIndex(
      bookId: book.id,
      chapterIndex: book.lastChapterIndex,
    );
    entries.add(
      ReadingHistoryEntry(
        book: book,
        chapterCount: chapterCount,
        chapterTitle: chapter?.title,
        percent: _percentFor(book, chapterCount, chapter),
      ),
    );
  }

  entries.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
  return entries;
});

/// Same rule as the book detail page: chapter position plus the offset inside
/// the current chapter, so the list matches the progress shown elsewhere.
int _percentFor(Book book, int chapterCount, Chapter? chapter) {
  if (chapterCount <= 0) return 0;
  if (book.lastChapterIndex <= 0 && book.lastReadPosition <= 0) return 0;

  final current = book.lastChapterIndex.clamp(0, chapterCount - 1);
  final contentLength = chapter?.normalizedContentLength ?? 0;
  final chapterProgress = contentLength <= 0
      ? 0.0
      : book.lastReadPosition.clamp(0, contentLength).toDouble() /
          contentLength;
  return (((current + chapterProgress) / chapterCount) * 100)
      .round()
      .clamp(1, 100);
}
