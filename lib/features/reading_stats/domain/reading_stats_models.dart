import '../../../shared/widgets/calendar_range_selector/calendar_range_models.dart';

enum ReadingStatsPreset { week, month, custom }

enum ReadingStatsRhythmGranularity {
  day,
  week,
  month,
  unsupported;

  String get displayLabel {
    switch (this) {
      case ReadingStatsRhythmGranularity.day:
        return '按天显示';
      case ReadingStatsRhythmGranularity.week:
        return '按周汇总';
      case ReadingStatsRhythmGranularity.month:
        return '按月汇总';
      case ReadingStatsRhythmGranularity.unsupported:
        return '超出范围';
    }
  }
}

class ReadingStatsRange {
  const ReadingStatsRange({
    required this.preset,
    required this.start,
    required this.end,
  });

  factory ReadingStatsRange.week() => ReadingStatsRange.weekOf(DateTime.now());

  factory ReadingStatsRange.weekOf(DateTime anchor) {
    final selection = CalendarDateRangeSelection.weekOf(anchor);
    return ReadingStatsRange(
      preset: ReadingStatsPreset.week,
      start: selection.start,
      end: selection.end,
    );
  }

  factory ReadingStatsRange.month() =>
      ReadingStatsRange.monthOf(DateTime.now());

  factory ReadingStatsRange.monthOf(DateTime anchor) {
    final selection = CalendarDateRangeSelection.monthOf(anchor);
    return ReadingStatsRange(
      preset: ReadingStatsPreset.month,
      start: selection.start,
      end: selection.end,
    );
  }

  factory ReadingStatsRange.custom({
    DateTime? start,
    DateTime? end,
  }) {
    final fallbackStart = start ?? DateTime.now();
    final selection = CalendarDateRangeSelection.custom(
      start: fallbackStart,
      end: end ?? fallbackStart,
    );
    return ReadingStatsRange(
      preset: ReadingStatsPreset.custom,
      start: selection.start,
      end: selection.end,
    );
  }

  factory ReadingStatsRange.fromCalendarSelection(
    CalendarDateRangeSelection selection,
  ) {
    return ReadingStatsRange(
      preset: switch (selection.preset) {
        CalendarRangePreset.week => ReadingStatsPreset.week,
        CalendarRangePreset.month => ReadingStatsPreset.month,
        CalendarRangePreset.custom => ReadingStatsPreset.custom,
      },
      start: selection.start,
      end: selection.end,
    );
  }

  final ReadingStatsPreset preset;
  final DateTime start;
  final DateTime end;

  String get label {
    switch (preset) {
      case ReadingStatsPreset.week:
        return '本周';
      case ReadingStatsPreset.month:
        return '本月';
      case ReadingStatsPreset.custom:
        return '自定义';
    }
  }

  String get title {
    switch (preset) {
      case ReadingStatsPreset.week:
        return '本周节奏';
      case ReadingStatsPreset.month:
        return '本月节奏';
      case ReadingStatsPreset.custom:
        return '阅读节奏';
    }
  }

  int get dayCount => end.difference(start).inDays + 1;

  ReadingStatsRhythmGranularity get rhythmGranularity {
    if (dayCount <= 31) return ReadingStatsRhythmGranularity.day;
    if (dayCount <= 120) return ReadingStatsRhythmGranularity.week;
    if (dayCount <= 366) return ReadingStatsRhythmGranularity.month;
    return ReadingStatsRhythmGranularity.unsupported;
  }

  String get rhythmSubtitle =>
      '近$dayCount天 · ${rhythmGranularity.displayLabel}';

  bool get isSupportedForRhythm =>
      rhythmGranularity != ReadingStatsRhythmGranularity.unsupported;

  CalendarDateRangeSelection toCalendarSelection() {
    return CalendarDateRangeSelection(
      preset: switch (preset) {
        ReadingStatsPreset.week => CalendarRangePreset.week,
        ReadingStatsPreset.month => CalendarRangePreset.month,
        ReadingStatsPreset.custom => CalendarRangePreset.custom,
      },
      start: start,
      end: end,
      visibleMonth: start,
    );
  }
}

class ReadingRhythmStat {
  const ReadingRhythmStat({
    required this.label,
    required this.minutes,
    required this.start,
    required this.end,
  });

  final String label;
  final int minutes;
  final DateTime start;
  final DateTime end;
}

class DailyReadingStat {
  const DailyReadingStat({
    required this.date,
    required this.dayLabel,
    required this.minutes,
  });

  final DateTime date;
  final String dayLabel;
  final int minutes;
}

class BookReadingContribution {
  const BookReadingContribution({
    required this.title,
    required this.durationLabel,
    required this.ratio,
  });

  final String title;
  final String durationLabel;
  final double ratio;
}

class ReadingStatsSummary {
  const ReadingStatsSummary({
    required this.range,
    required this.totalLabel,
    required this.description,
    required this.stats,
    required this.rhythmStats,
    required this.rhythmGranularity,
    required this.rhythmSubtitle,
    required this.contributions,
    required this.sheetSummary,
    required this.hasData,
    required this.readingDays,
    required this.totalMinutes,
    required this.chaptersRead,
    required this.wordsRead,
    required this.sessionCount,
    required this.longestSessionMinutes,
    required this.bestDayLabel,
    required this.bestDayMinutes,
  });

  final ReadingStatsRange range;
  final String totalLabel;
  final String description;
  final List<ReadingStatMetric> stats;
  final List<ReadingRhythmStat> rhythmStats;
  final ReadingStatsRhythmGranularity rhythmGranularity;
  final String rhythmSubtitle;
  final List<BookReadingContribution> contributions;
  final String sheetSummary;
  final bool hasData;

  /// Days in [range] with at least one recorded session.
  final int readingDays;

  /// Total reading time in minutes, used for averages.
  final int totalMinutes;
  final int chaptersRead;
  final int wordsRead;
  final int sessionCount;
  final int longestSessionMinutes;

  /// Label of the day with the most reading time, e.g. "周三" or "5月22日".
  final String? bestDayLabel;
  final int bestDayMinutes;

  /// "5/7" for the hero ring.
  String get readingDayRatioLabel => '$readingDays/${range.dayCount}';

  double get readingDayRatio =>
      range.dayCount <= 0 ? 0 : readingDays / range.dayCount;

  int get averageSessionMinutes =>
      sessionCount <= 0 ? 0 : (totalMinutes / sessionCount).round();
}

class ReadingStatMetric {
  const ReadingStatMetric({required this.value, required this.label});

  final String value;
  final String label;
}

/// Aggregated reading activity for one calendar month. Powers the reading goal
/// screen and the profile goal card.
class ReadingMonthStats {
  const ReadingMonthStats({
    required this.month,
    required this.totalSeconds,
    required this.chaptersRead,
    required this.charactersRead,
    required this.recordedDays,
    required this.daysInMonth,
    required this.streakDays,
  });

  final DateTime month;
  final int totalSeconds;
  final int chaptersRead;
  final int charactersRead;

  /// Number of days in [month] with at least one session.
  final int recordedDays;
  final int daysInMonth;

  /// Consecutive reading days ending today (or yesterday when today is empty).
  final int streakDays;

  bool get hasData => totalSeconds > 0;

  int get totalMinutes => totalSeconds <= 0 ? 0 : (totalSeconds / 60).ceil();

  /// "0m", "39m", "12h" or "15h 36m".
  String get compactDurationLabel => formatCompactDuration(totalMinutes);

  /// "0 分钟", "39 分钟", "12 小时" or "15 小时 36 分钟".
  String get proseDurationLabel => formatProseDuration(totalMinutes);
}

/// Compact duration used inside cards, e.g. "15h 36m".
String formatCompactDuration(int minutes) {
  if (minutes <= 0) return '0m';
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}

/// Character totals for the detail rows, e.g. "8600 字" or "3.2 万字".
String formatReadingWords(int words) {
  if (words <= 0) return '0 字';
  if (words < 10000) return '$words 字';
  final wan = words / 10000;
  final text = wan >= 100
      ? wan.round().toString()
      : wan.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  return '$text 万字';
}

/// Prose duration used inside sentences, e.g. "15 小时 36 分钟".
String formatProseDuration(int minutes) {
  if (minutes <= 0) return '0 分钟';
  if (minutes < 60) return '$minutes 分钟';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours 小时' : '$hours 小时 $rest 分钟';
}
