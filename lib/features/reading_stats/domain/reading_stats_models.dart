enum ReadingStatsPreset { week, month, custom }

class ReadingStatsRange {
  const ReadingStatsRange({
    required this.preset,
    required this.start,
    required this.end,
  });

  factory ReadingStatsRange.week() => ReadingStatsRange(
        preset: ReadingStatsPreset.week,
        start: DateTime(2024, 5, 18),
        end: DateTime(2024, 5, 24),
      );

  factory ReadingStatsRange.month() => ReadingStatsRange(
        preset: ReadingStatsPreset.month,
        start: DateTime(2024, 5),
        end: DateTime(2024, 5, 31),
      );

  factory ReadingStatsRange.custom() => ReadingStatsRange(
        preset: ReadingStatsPreset.custom,
        start: DateTime(2024, 5, 10),
        end: DateTime(2024, 5, 20),
      );

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
}

class DailyReadingStat {
  const DailyReadingStat({
    required this.dayLabel,
    required this.minutes,
  });

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
    required this.dailyStats,
    required this.contributions,
    required this.sheetSummary,
    required this.hasData,
  });

  final ReadingStatsRange range;
  final String totalLabel;
  final String description;
  final List<ReadingStatMetric> stats;
  final List<DailyReadingStat> dailyStats;
  final List<BookReadingContribution> contributions;
  final String sheetSummary;
  final bool hasData;
}

class ReadingStatMetric {
  const ReadingStatMetric({required this.value, required this.label});

  final String value;
  final String label;
}
