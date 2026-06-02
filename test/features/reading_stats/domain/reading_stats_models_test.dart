import 'package:dudo/features/reading_stats/domain/reading_stats_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingStatsRange rhythm granularity', () {
    test('uses day granularity through 31 days', () {
      expect(_rangeForDays(7).rhythmGranularity,
          ReadingStatsRhythmGranularity.day);
      expect(_rangeForDays(31).rhythmGranularity,
          ReadingStatsRhythmGranularity.day);
    });

    test('uses week granularity from 32 through 120 days', () {
      expect(_rangeForDays(32).rhythmGranularity,
          ReadingStatsRhythmGranularity.week);
      expect(_rangeForDays(120).rhythmGranularity,
          ReadingStatsRhythmGranularity.week);
    });

    test('uses month granularity from 121 through 366 days', () {
      expect(_rangeForDays(121).rhythmGranularity,
          ReadingStatsRhythmGranularity.month);
      expect(_rangeForDays(366).rhythmGranularity,
          ReadingStatsRhythmGranularity.month);
    });

    test('marks ranges over 366 days unsupported', () {
      final range = _rangeForDays(367);

      expect(
          range.rhythmGranularity, ReadingStatsRhythmGranularity.unsupported);
      expect(range.isSupportedForRhythm, isFalse);
      expect(range.rhythmSubtitle, '近367天 · 超出范围');
    });
  });
}

ReadingStatsRange _rangeForDays(int days) {
  return ReadingStatsRange.custom(
    start: DateTime(2024, 1, 1),
    end: DateTime(2024, 1, 1).add(Duration(days: days - 1)),
  );
}
