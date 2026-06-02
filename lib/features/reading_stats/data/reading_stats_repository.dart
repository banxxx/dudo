import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../domain/reading_stats_models.dart';

class ReadingStatsRepository {
  const ReadingStatsRepository(this.database);

  final AppDatabase database;

  Future<ReadingStatsSummary> getSummary(ReadingStatsRange range) async {
    final start = DateUtils.dateOnly(range.start);
    final exclusiveEnd =
        DateUtils.dateOnly(range.end).add(const Duration(days: 1));
    final rows = await _readSessionRows(start, exclusiveEnd);
    final dailySeconds = _dailySecondsForRange(range);
    final bookSeconds = <String, int>{};
    final bookTitles = <String, String>{};
    var totalSeconds = 0;

    for (final row in rows) {
      final date = DateUtils.dateOnly(row.session.startedAt);
      final seconds = row.session.durationSeconds;
      dailySeconds[date] = (dailySeconds[date] ?? 0) + seconds;
      bookSeconds[row.session.bookId] =
          (bookSeconds[row.session.bookId] ?? 0) + seconds;
      bookTitles[row.session.bookId] = row.book.title;
      totalSeconds += seconds;
    }

    final rhythmStats = _rhythmStats(range, dailySeconds);
    final readingDays =
        dailySeconds.values.where((seconds) => seconds > 0).length;
    final totalMinutes = _secondsToDisplayMinutes(totalSeconds);
    final averageMinutes =
        range.dayCount == 0 ? 0 : (totalMinutes / range.dayCount).round();
    final hasData = totalSeconds > 0;

    return ReadingStatsSummary(
      range: range,
      totalLabel: _formatDuration(totalSeconds),
      description: _descriptionFor(range, hasData),
      stats: [
        ReadingStatMetric(value: '$readingDays天', label: '阅读'),
        ReadingStatMetric(value: '$averageMinutes分', label: '日均'),
        ReadingStatMetric(value: '${bookSeconds.length}本', label: '读过'),
      ],
      rhythmStats: rhythmStats,
      rhythmGranularity: range.rhythmGranularity,
      rhythmSubtitle: range.rhythmSubtitle,
      contributions: _contributions(bookSeconds, bookTitles),
      sheetSummary: readingStatsRangePreviewText(range),
      hasData: hasData,
    );
  }

  Future<List<_ReadingSessionBookRow>> _readSessionRows(
    DateTime start,
    DateTime exclusiveEnd,
  ) async {
    final query = database.select(database.readingSessions).join([
      innerJoin(
        database.books,
        database.books.id.equalsExp(database.readingSessions.bookId),
      ),
    ])
      ..where(database.readingSessions.startedAt.isBiggerOrEqualValue(start))
      ..where(
          database.readingSessions.startedAt.isSmallerThanValue(exclusiveEnd))
      ..where(database.readingSessions.durationSeconds.isBiggerThanValue(0));

    final rows = await query.get();
    return rows.map((row) {
      return _ReadingSessionBookRow(
        session: row.readTable(database.readingSessions),
        book: row.readTable(database.books),
      );
    }).toList();
  }

  Map<DateTime, int> _dailySecondsForRange(ReadingStatsRange range) {
    return {
      for (var i = 0; i < range.dayCount; i++)
        DateUtils.dateOnly(range.start).add(Duration(days: i)): 0,
    };
  }

  List<ReadingRhythmStat> _rhythmStats(
    ReadingStatsRange range,
    Map<DateTime, int> dailySeconds,
  ) {
    switch (range.rhythmGranularity) {
      case ReadingStatsRhythmGranularity.day:
        return _dailyRhythmStats(range, dailySeconds);
      case ReadingStatsRhythmGranularity.week:
        return _weeklyRhythmStats(range, dailySeconds);
      case ReadingStatsRhythmGranularity.month:
        return _monthlyRhythmStats(range, dailySeconds);
      case ReadingStatsRhythmGranularity.unsupported:
        return const [];
    }
  }

  List<ReadingRhythmStat> _dailyRhythmStats(
    ReadingStatsRange range,
    Map<DateTime, int> dailySeconds,
  ) {
    return [
      for (var i = 0; i < range.dayCount; i++)
        _dailyRhythmStatFor(
          range,
          DateUtils.dateOnly(range.start).add(Duration(days: i)),
          dailySeconds[
                  DateUtils.dateOnly(range.start).add(Duration(days: i))] ??
              0,
        ),
    ];
  }

  ReadingRhythmStat _dailyRhythmStatFor(
    ReadingStatsRange range,
    DateTime date,
    int seconds,
  ) {
    return ReadingRhythmStat(
      start: date,
      end: date,
      label: _dayLabelFor(range, date),
      minutes: _secondsToDisplayMinutes(seconds),
    );
  }

  List<ReadingRhythmStat> _weeklyRhythmStats(
    ReadingStatsRange range,
    Map<DateTime, int> dailySeconds,
  ) {
    final stats = <ReadingRhythmStat>[];
    var cursor = DateUtils.dateOnly(range.start);
    final rangeEnd = DateUtils.dateOnly(range.end);

    while (!cursor.isAfter(rangeEnd)) {
      final naturalWeekEnd = cursor.add(
        Duration(days: DateTime.daysPerWeek - cursor.weekday),
      );
      final bucketEnd =
          naturalWeekEnd.isAfter(rangeEnd) ? rangeEnd : naturalWeekEnd;
      final seconds = _sumDailySeconds(dailySeconds, cursor, bucketEnd);

      stats.add(
        ReadingRhythmStat(
          label: _dateRangeLabel(cursor, bucketEnd),
          minutes: _secondsToDisplayMinutes(seconds),
          start: cursor,
          end: bucketEnd,
        ),
      );

      cursor = bucketEnd.add(const Duration(days: 1));
    }

    return stats;
  }

  List<ReadingRhythmStat> _monthlyRhythmStats(
    ReadingStatsRange range,
    Map<DateTime, int> dailySeconds,
  ) {
    final stats = <ReadingRhythmStat>[];
    var cursor = DateUtils.dateOnly(range.start);
    final rangeEnd = DateUtils.dateOnly(range.end);
    final spansMultipleYears = range.start.year != range.end.year;

    while (!cursor.isAfter(rangeEnd)) {
      final monthEnd = DateTime(
        cursor.year,
        cursor.month,
        DateUtils.getDaysInMonth(cursor.year, cursor.month),
      );
      final bucketEnd = monthEnd.isAfter(rangeEnd) ? rangeEnd : monthEnd;
      final seconds = _sumDailySeconds(dailySeconds, cursor, bucketEnd);

      stats.add(
        ReadingRhythmStat(
          label: _monthLabel(cursor, spansMultipleYears),
          minutes: _secondsToDisplayMinutes(seconds),
          start: cursor,
          end: bucketEnd,
        ),
      );

      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return stats;
  }

  int _sumDailySeconds(
    Map<DateTime, int> dailySeconds,
    DateTime start,
    DateTime end,
  ) {
    var total = 0;
    for (var cursor = start;
        !cursor.isAfter(end);
        cursor = cursor.add(const Duration(days: 1))) {
      total += dailySeconds[DateUtils.dateOnly(cursor)] ?? 0;
    }
    return total;
  }

  List<BookReadingContribution> _contributions(
    Map<String, int> bookSeconds,
    Map<String, String> bookTitles,
  ) {
    if (bookSeconds.isEmpty) return const [];

    final sorted = bookSeconds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxSeconds = sorted.first.value;

    return sorted.take(5).map((entry) {
      return BookReadingContribution(
        title: bookTitles[entry.key] ?? '未知书籍',
        durationLabel: _formatDuration(entry.value),
        ratio: maxSeconds == 0 ? 0 : (entry.value / maxSeconds).clamp(0.0, 1.0),
      );
    }).toList();
  }

  String _dayLabelFor(ReadingStatsRange range, DateTime date) {
    if (range.preset == ReadingStatsPreset.week && range.dayCount <= 7) {
      return const ['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1];
    }
    return '${date.day}';
  }

  String _dateRangeLabel(DateTime start, DateTime end) {
    if (start.month == end.month) {
      return '${start.month}/${start.day}-${end.day}';
    }
    return '${start.month}/${start.day}-${end.month}/${end.day}';
  }

  String _monthLabel(DateTime date, bool spansMultipleYears) {
    if (!spansMultipleYears) return '${date.month}月';
    return '${date.year % 100}/${date.month}';
  }

  String _descriptionFor(ReadingStatsRange range, bool hasData) {
    if (!hasData) {
      return switch (range.preset) {
        ReadingStatsPreset.week => '本周还没有阅读记录',
        ReadingStatsPreset.month => '本月还没有阅读记录',
        ReadingStatsPreset.custom => '这段时间还没有阅读记录',
      };
    }
    return switch (range.preset) {
      ReadingStatsPreset.week => '本周阅读总时长',
      ReadingStatsPreset.month => '本月阅读总时长',
      ReadingStatsPreset.custom => '所选时间阅读总时长',
    };
  }

  int _secondsToDisplayMinutes(int seconds) {
    if (seconds <= 0) return 0;
    return (seconds / 60).ceil();
  }

  String _formatDuration(int seconds) {
    final minutes = _secondsToDisplayMinutes(seconds);
    if (minutes == 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }
}

String readingStatsRangePreviewText(ReadingStatsRange range) {
  if (!range.isSupportedForRhythm) {
    return '已选择 ${range.dayCount} 天 · 最多支持 366 天';
  }

  return switch (range.preset) {
    ReadingStatsPreset.week => '选择本周阅读范围',
    ReadingStatsPreset.month => '选择本月阅读范围',
    ReadingStatsPreset.custom => '自定义 ${range.dayCount} 天',
  };
}

class _ReadingSessionBookRow {
  const _ReadingSessionBookRow({required this.session, required this.book});

  final ReadingSession session;
  final Book book;
}
