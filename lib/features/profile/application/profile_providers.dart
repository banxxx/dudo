import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookmarks/application/bookmarks_providers.dart';
import '../../bookshelf/application/bookshelf_providers.dart';
import '../../reading_stats/application/reading_stats_provider.dart';

/// Numbers shown on the profile screen, derived from the library and this
/// month's reading sessions.
class ProfileSummary {
  const ProfileSummary({
    required this.monthReadingLabel,
    required this.shelfCount,
    required this.bookmarkCount,
  });

  static const empty = ProfileSummary(
    monthReadingLabel: '0m',
    shelfCount: 0,
    bookmarkCount: 0,
  );

  /// Compact form for the stats row, e.g. "12h".
  final String monthReadingLabel;

  /// Books on the shelf.
  final int shelfCount;

  /// Bookmarks, highlights and notes combined.
  final int bookmarkCount;
}

final profileSummaryProvider = FutureProvider<ProfileSummary>((ref) async {
  final stats = await ref.watch(readingMonthStatsProvider.future);
  final books = ref.watch(shelfBooksProvider).valueOrNull ?? const [];
  final entries = ref.watch(bookmarkEntriesProvider).valueOrNull ?? const [];

  return ProfileSummary(
    monthReadingLabel: stats.compactDurationLabel,
    shelfCount: books.length,
    bookmarkCount: entries.length,
  );
});
