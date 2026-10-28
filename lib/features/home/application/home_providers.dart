import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../bookshelf/application/bookshelf_providers.dart';
import '../../reading_stats/application/reading_stats_provider.dart';
import '../../reading_stats/domain/reading_stats_models.dart';

/// The reader estimates roughly 450 characters per minute; reuse the same pace
/// so the home hero and the reader agree on the remaining time.
const int _charactersPerMinute = 450;

final _chapterNumberPrefix = RegExp(
  r'^第\s*[0-9零一二三四五六七八九十百千两]+\s*[章节回卷][\s、,，:：·\-—]*',
);

/// The shelf book with real reading progress that was read most recently.
final currentReadingBookProvider = Provider<Book?>((ref) {
  final books = ref.watch(shelfBooksProvider).valueOrNull;
  if (books == null || books.isEmpty) return null;

  Book? latest;
  for (final book in books) {
    if (book.lastChapterIndex <= 0 && book.lastReadPosition <= 0) continue;
    if (latest == null || book.updatedAt.isAfter(latest.updatedAt)) {
      latest = book;
    }
  }
  return latest;
});

/// Everything the home "continue reading" hero needs, derived from the book on
/// the shelf and its current chapter.
class HomeReadingSnapshot {
  const HomeReadingSnapshot({
    required this.bookId,
    required this.bookTitle,
    required this.author,
    required this.chapterIndex,
    required this.chapterCount,
    required this.subtitle,
    required this.progressPercent,
    required this.remainingMinutes,
  });

  final String bookId;
  final String bookTitle;
  final String? author;
  final int chapterIndex;
  final int chapterCount;
  final String subtitle;
  final int progressPercent;
  final int? remainingMinutes;

  String get chapterLabel => chapterCount > 0 ? '第 ${chapterIndex + 1} 章' : '';

  /// The small label above the title. The chapter lives here so long book
  /// titles are not truncated before their chapter number.
  String get continueLabel =>
      chapterLabel.isEmpty ? '继续阅读' : '继续阅读 · $chapterLabel';

  String get progressLabel => progressPercent > 0 ? '$progressPercent%' : '在读';

  String get remainingLabel {
    final minutes = remainingMinutes;
    if (minutes == null) return '继续上次进度';
    return '剩余 $minutes 分钟';
  }

  String get coverLabel {
    final name = (author ?? '').trim();
    final source = name.isEmpty ? bookTitle.trim() : name;
    if (source.isEmpty) return 'DUDO';
    return source.length <= 2 ? source : source.substring(0, 2);
  }
}

final homeReadingSnapshotProvider = Provider<HomeReadingSnapshot?>((ref) {
  final book = ref.watch(currentReadingBookProvider);
  if (book == null) return null;

  final loadedChapterCount =
      ref.watch(bookChapterCountProvider(book.id)).valueOrNull ?? 0;
  final chapterCount =
      math.max(book.remoteChapterCount ?? 0, loadedChapterCount);
  final chapter = ref
      .watch(
        currentBookChapterMetaProvider(
          CurrentBookChapterKey(
            bookId: book.id,
            chapterIndex: book.lastChapterIndex,
          ),
        ),
      )
      .valueOrNull;
  final chapterLength = chapter?.normalizedContentLength ?? 0;

  return HomeReadingSnapshot(
    bookId: book.id,
    bookTitle: book.title,
    author: book.author,
    chapterIndex: book.lastChapterIndex,
    chapterCount: chapterCount,
    subtitle: _subtitleFor(chapter, book),
    progressPercent: _bookProgressPercent(book, chapterCount, chapterLength),
    remainingMinutes: _remainingMinutes(book, chapterLength),
  );
});

/// This week's reading rhythm (minutes per day), shown at the bottom of home.
final homeWeeklyRhythmProvider = FutureProvider<List<ReadingRhythmStat>>((ref) {
  return ref.watch(readingWeekRhythmProvider.future);
});

String _subtitleFor(Chapter? chapter, Book book) {
  final chapterTitle = chapter?.title.trim() ?? '';
  if (chapterTitle.isNotEmpty) {
    final stripped = chapterTitle.replaceFirst(_chapterNumberPrefix, '').trim();
    return stripped.isEmpty ? chapterTitle : stripped;
  }
  final intro = book.intro?.trim() ?? '';
  if (intro.isNotEmpty) return intro;
  return '继续上一次的阅读';
}

int _bookProgressPercent(Book book, int chapterCount, int chapterLength) {
  if (chapterCount <= 0) return 0;

  final current = book.lastChapterIndex.clamp(0, chapterCount - 1);
  final chapterProgress = chapterLength <= 0
      ? 0.0
      : book.lastReadPosition.clamp(0, chapterLength) / chapterLength;
  return (((current + chapterProgress) / chapterCount) * 100)
      .round()
      .clamp(1, 100);
}

int? _remainingMinutes(Book book, int chapterLength) {
  if (chapterLength <= 0) return null;

  final remaining = chapterLength - book.lastReadPosition;
  if (remaining <= 0) return null;
  return math.max(1, (remaining / _charactersPerMinute).ceil());
}
