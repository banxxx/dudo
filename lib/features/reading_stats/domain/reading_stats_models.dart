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
}

class ReadingStatMetric {
  const ReadingStatMetric({required this.value, required this.label});

  final String value;
  final String label;
}
