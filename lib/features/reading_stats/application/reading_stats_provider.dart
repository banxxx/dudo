import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reading_stats_models.dart';

final readingStatsTodayProvider = Provider<DateTime>((_) => DateTime.now());

final readingStatsRangeProvider = StateProvider<ReadingStatsRange>(
  (ref) => ReadingStatsRange.weekOf(ref.watch(readingStatsTodayProvider)),
);

final readingStatsSummaryProvider = Provider<ReadingStatsSummary>((ref) {
  final range = ref.watch(readingStatsRangeProvider);
  return readingStatsSummaryFor(range);
});

ReadingStatsSummary readingStatsSummaryFor(ReadingStatsRange range) {
  switch (range.preset) {
    case ReadingStatsPreset.week:
      return ReadingStatsSummary(
        range: range,
        totalLabel: '6h 40m',
        description: '本周阅读总时长',
        stats: const [
          ReadingStatMetric(value: '5天', label: '连续'),
          ReadingStatMetric(value: '57分', label: '日均'),
          ReadingStatMetric(value: '3本', label: '读过'),
        ],
        dailyStats: const [
          DailyReadingStat(dayLabel: '一', minutes: 36),
          DailyReadingStat(dayLabel: '二', minutes: 48),
          DailyReadingStat(dayLabel: '三', minutes: 82),
          DailyReadingStat(dayLabel: '四', minutes: 28),
          DailyReadingStat(dayLabel: '五', minutes: 74),
          DailyReadingStat(dayLabel: '六', minutes: 52),
          DailyReadingStat(dayLabel: '日', minutes: 80),
        ],
        contributions: const [
          BookReadingContribution(
              title: '三体', durationLabel: '3h 10m', ratio: .78),
          BookReadingContribution(
              title: '长安的荔枝', durationLabel: '2h 05m', ratio: .52),
          BookReadingContribution(
              title: '云边有个小卖部', durationLabel: '1h 25m', ratio: .36),
        ],
        sheetSummary: '本周阅读 6h 40m · 连续 5 天',
        hasData: true,
      );
    case ReadingStatsPreset.month:
      return ReadingStatsSummary(
        range: range,
        totalLabel: '24h 15m',
        description: '本月阅读总时长',
        stats: const [
          ReadingStatMetric(value: '18天', label: '阅读'),
          ReadingStatMetric(value: '48分', label: '日均'),
          ReadingStatMetric(value: '9本', label: '读过'),
        ],
        dailyStats: const [
          DailyReadingStat(dayLabel: '一', minutes: 42),
          DailyReadingStat(dayLabel: '二', minutes: 58),
          DailyReadingStat(dayLabel: '三', minutes: 64),
          DailyReadingStat(dayLabel: '四', minutes: 46),
          DailyReadingStat(dayLabel: '五', minutes: 72),
          DailyReadingStat(dayLabel: '六', minutes: 61),
          DailyReadingStat(dayLabel: '日', minutes: 77),
        ],
        contributions: const [
          BookReadingContribution(
              title: '三体', durationLabel: '8h 30m', ratio: .86),
          BookReadingContribution(
              title: '长安的荔枝', durationLabel: '6h 45m', ratio: .68),
          BookReadingContribution(
              title: '云边有个小卖部', durationLabel: '4h 20m', ratio: .44),
        ],
        sheetSummary: '本月阅读 24h 15m · 读过 9 本',
        hasData: true,
      );
    case ReadingStatsPreset.custom:
      return ReadingStatsSummary(
        range: range,
        totalLabel: '0m',
        description: '本周还没有阅读记录',
        stats: const [
          ReadingStatMetric(value: '0天', label: '阅读'),
          ReadingStatMetric(value: '0分', label: '日均'),
          ReadingStatMetric(value: '0本', label: '读过'),
        ],
        dailyStats: const [
          DailyReadingStat(dayLabel: '一', minutes: 0),
          DailyReadingStat(dayLabel: '二', minutes: 0),
          DailyReadingStat(dayLabel: '三', minutes: 0),
          DailyReadingStat(dayLabel: '四', minutes: 0),
          DailyReadingStat(dayLabel: '五', minutes: 0),
          DailyReadingStat(dayLabel: '六', minutes: 0),
          DailyReadingStat(dayLabel: '日', minutes: 0),
        ],
        contributions: const [],
        sheetSummary: '自定义 11 天 · 预计 10h 30m',
        hasData: false,
      );
  }
}
