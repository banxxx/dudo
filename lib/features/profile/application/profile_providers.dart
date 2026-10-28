import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookmarks/application/bookmarks_providers.dart';
import '../../bookshelf/application/bookshelf_providers.dart';
import '../../reading_stats/application/reading_stats_provider.dart';

/// Numbers shown on the profile screen, derived from the library and this
/// month's reading sessions.
class ProfileSummary {
  const ProfileSummary({
    required this.monthReadingLabel,
    required this.monthReadingProse,
    required this.hasReadThisMonth,
    required this.shelfCount,
    required this.bookmarkCount,
  });

  static const empty = ProfileSummary(
    monthReadingLabel: '0m',
    monthReadingProse: '0 分钟',
    hasReadThisMonth: false,
    shelfCount: 0,
    bookmarkCount: 0,
  );

  /// Compact form for the stats row, e.g. "12h".
  final String monthReadingLabel;

  /// Prose form for the identity subtitle, e.g. "12 小时".
  final String monthReadingProse;
  final bool hasReadThisMonth;

  /// Books on the shelf.
  final int shelfCount;

  /// Bookmarks, highlights and notes combined.
  final int bookmarkCount;

  String get subtitle => hasReadThisMonth
      ? '本月已阅读 $monthReadingProse，收藏 $shelfCount 本书'
      : '本月还没有阅读记录，收藏 $shelfCount 本书';
}

final profileSummaryProvider = FutureProvider<ProfileSummary>((ref) async {
  final stats = await ref.watch(readingMonthStatsProvider.future);
  final books = ref.watch(shelfBooksProvider).valueOrNull ?? const [];
  final entries = ref.watch(bookmarkEntriesProvider).valueOrNull ?? const [];

  return ProfileSummary(
    monthReadingLabel: stats.compactDurationLabel,
    monthReadingProse: stats.proseDurationLabel,
    hasReadThisMonth: stats.hasData,
    shelfCount: books.length,
    bookmarkCount: entries.length,
  );
});
