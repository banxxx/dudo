import '../../../core/database/app_database.dart';

/// Time window shown on the reading history page.
enum ReadingHistoryFilter {
  recent('最近'),
  week('本周'),
  month('本月');

  const ReadingHistoryFilter(this.label);

  final String label;
}

/// One book in the "recently opened" list, with the position the reader left
/// it at. The list is built from shelf books that have real progress, so a
/// book that was only imported never appears here.
class ReadingHistoryEntry {
  const ReadingHistoryEntry({
    required this.book,
    required this.chapterCount,
    required this.percent,
    this.chapterTitle,
  });

  final Book book;
  final int chapterCount;
  final int percent;
  final String? chapterTitle;

  /// The book's `updatedAt` is moved forward whenever the reader saves a
  /// position, so it is the "last opened" timestamp used by this page.
  DateTime get lastOpenedAt => book.updatedAt;

  String get positionLabel {
    final title = chapterTitle?.trim();
    final chapter = '第 ${book.lastChapterIndex + 1} 章';
    if (title == null || title.isEmpty) return '读到 $chapter';
    return '读到 $chapter · $title';
  }

  /// Compact label for the time pill: 今天 / 昨天 / 周二 / 9月12日.
  ///
  /// Days still inside the current Monday-based week read as a weekday, the
  /// same window the 本周 filter covers; anything older shows its date.
  String timeLabel(DateTime now) {
    final day = _openedDay;
    final days = _today(now).difference(day).inDays;
    if (days <= 0) return '今天';
    if (days == 1) return '昨天';
    final weekStart = _today(now).subtract(Duration(days: now.weekday - 1));
    if (!day.isBefore(weekStart)) return '周${_weekdayLabels[day.weekday - 1]}';
    return '${day.month}月${day.day}日';
  }

  /// True only for books opened today; the time pill is tinted pine for these
  /// and stays on the quiet paper fill for every other day.
  bool openedToday(DateTime now) => _today(now).difference(_openedDay).inDays <= 0;

  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  DateTime get _openedDay =>
      DateTime(lastOpenedAt.year, lastOpenedAt.month, lastOpenedAt.day);

  static DateTime _today(DateTime now) => DateTime(now.year, now.month, now.day);
}
