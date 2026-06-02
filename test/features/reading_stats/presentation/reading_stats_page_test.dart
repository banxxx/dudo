import 'package:dudo/features/reading_stats/application/reading_stats_provider.dart';
import 'package:dudo/features/reading_stats/domain/reading_stats_models.dart';
import 'package:dudo/features/reading_stats/presentation/reading_stats_page.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders the reading stats design with daily rhythm',
      (tester) async {
    final range = ReadingStatsRange.weekOf(DateTime(2024, 5, 22));
    await _pumpStatsPage(
      tester,
      summary: _summaryFor(
        range,
        totalLabel: '6h 40m',
        description: '本周阅读总时长',
        hasData: true,
        stats: const [
          ReadingStatMetric(value: '5天', label: '阅读'),
          ReadingStatMetric(value: '57分', label: '日均'),
          ReadingStatMetric(value: '3本', label: '读过'),
        ],
        rhythmStats: [
          ReadingRhythmStat(
            label: '一',
            minutes: 36,
            start: DateTime(2024, 5, 20),
            end: DateTime(2024, 5, 20),
          ),
          ReadingRhythmStat(
            label: '二',
            minutes: 48,
            start: DateTime(2024, 5, 21),
            end: DateTime(2024, 5, 21),
          ),
          ReadingRhythmStat(
            label: '三',
            minutes: 82,
            start: DateTime(2024, 5, 22),
            end: DateTime(2024, 5, 22),
          ),
        ],
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DudoColors.paperBackground);

    expect(find.text('阅读统计'), findsOneWidget);
    expect(find.text('本周节奏'), findsOneWidget);
    expect(find.text('本周'), findsOneWidget);
    expect(find.text('6h 40m'), findsOneWidget);
    expect(find.text('本周阅读总时长'), findsOneWidget);
    expect(find.text('5天'), findsOneWidget);
    expect(find.text('57分'), findsOneWidget);
    expect(find.text('3本'), findsOneWidget);
    expect(find.text('阅读节奏'), findsOneWidget);
    expect(find.text('近7天 · 按天显示'), findsOneWidget);
    expect(find.text('峰值 82m'), findsOneWidget);
    expect(find.text('书籍贡献'), findsOneWidget);
    expect(find.text('三体'), findsOneWidget);
    expect(find.text('长安的荔枝'), findsOneWidget);
    expect(find.text('云边有个小卖部'), findsOneWidget);
  });

  testWidgets('renders empty state from a custom empty range', (tester) async {
    final range = ReadingStatsRange.custom(
      start: DateTime(2024, 5, 22),
      end: DateTime(2024, 5, 22),
    );
    await _pumpStatsPage(
      tester,
      summary: _summaryFor(
        range,
        totalLabel: '0m',
        description: '这段时间还没有阅读记录',
        hasData: false,
        stats: const [
          ReadingStatMetric(value: '0天', label: '阅读'),
          ReadingStatMetric(value: '0分', label: '日均'),
          ReadingStatMetric(value: '0本', label: '读过'),
        ],
        rhythmStats: [
          ReadingRhythmStat(
            label: '22',
            minutes: 0,
            start: DateTime(2024, 5, 22),
            end: DateTime(2024, 5, 22),
          ),
        ],
      ),
      rangeOverride: range,
    );

    expect(find.text('自定义'), findsOneWidget);
    expect(find.text('0m'), findsOneWidget);
    expect(find.text('这段时间还没有阅读记录'), findsOneWidget);
    expect(find.text('0天'), findsOneWidget);
    expect(find.text('0分'), findsOneWidget);
    expect(find.text('0本'), findsOneWidget);
    expect(find.text('暂无数据'), findsOneWidget);
    expect(find.text('开始阅读后生成节奏'), findsOneWidget);
  });

  testWidgets('shows horizontal scroll for a 31 day daily range',
      (tester) async {
    final range = ReadingStatsRange.custom(
      start: DateTime(2024, 5, 1),
      end: DateTime(2024, 5, 31),
    );
    await _pumpStatsPage(
      tester,
      summary: _summaryFor(
        range,
        rhythmStats: [
          for (var day = 1; day <= 31; day++)
            ReadingRhythmStat(
              label: '$day',
              minutes: day,
              start: DateTime(2024, 5, day),
              end: DateTime(2024, 5, day),
            ),
        ],
      ),
      rangeOverride: range,
    );

    expect(find.text('近31天 · 按天显示'), findsOneWidget);
    expect(find.byKey(const ValueKey('reading-stats-rhythm-scroll')),
        findsOneWidget);
  });

  testWidgets('shows weekly granularity for a 90 day range', (tester) async {
    final range = ReadingStatsRange.custom(
      start: DateTime(2024, 5, 1),
      end: DateTime(2024, 7, 29),
    );
    await _pumpStatsPage(
      tester,
      summary: _summaryFor(
        range,
        rhythmStats: [
          ReadingRhythmStat(
            label: '5/1-5',
            minutes: 120,
            start: DateTime(2024, 5, 1),
            end: DateTime(2024, 5, 5),
          ),
          ReadingRhythmStat(
            label: '5/6-12',
            minutes: 240,
            start: DateTime(2024, 5, 6),
            end: DateTime(2024, 5, 12),
          ),
        ],
      ),
      rangeOverride: range,
    );

    expect(find.text('近90天 · 按周汇总'), findsOneWidget);
  });

  testWidgets('shows monthly granularity for a 365 day range', (tester) async {
    final range = ReadingStatsRange.custom(
      start: DateTime(2024, 1, 1),
      end: DateTime(2024, 12, 30),
    );
    await _pumpStatsPage(
      tester,
      summary: _summaryFor(
        range,
        rhythmStats: [
          ReadingRhythmStat(
            label: '1月',
            minutes: 120,
            start: DateTime(2024, 1, 1),
            end: DateTime(2024, 1, 31),
          ),
          ReadingRhythmStat(
            label: '2月',
            minutes: 240,
            start: DateTime(2024, 2, 1),
            end: DateTime(2024, 2, 29),
          ),
        ],
      ),
      rangeOverride: range,
    );

    expect(find.text('近365天 · 按月汇总'), findsOneWidget);
  });

  testWidgets('opens date range sheet and switches presets', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final range = ReadingStatsRange.weekOf(DateTime(2024, 5, 22));
    await _pumpStatsPage(
      tester,
      summary: _summaryFor(range),
      rangeOverride: range,
      today: DateTime(2024, 5, 22),
    );

    await tester.tap(find.byKey(const ValueKey('reading-stats-range-button')));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('选择时间'), findsOneWidget);
    expect(find.text('2024年5月'), findsOneWidget);
    expect(find.text('选择本周阅读范围'), findsOneWidget);
  });
}

Future<void> _pumpStatsPage(
  WidgetTester tester, {
  required ReadingStatsSummary summary,
  ReadingStatsRange? rangeOverride,
  DateTime? today,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (today != null) readingStatsTodayProvider.overrideWithValue(today),
        if (rangeOverride != null)
          readingStatsRangeProvider.overrideWith((_) => rangeOverride),
        readingStatsSummaryProvider.overrideWith((_) async => summary),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/reading-stats',
          routes: [
            GoRoute(
              path: '/reading-stats',
              builder: (_, __) => const ReadingStatsPage(),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

ReadingStatsSummary _summaryFor(
  ReadingStatsRange range, {
  String totalLabel = '6h 40m',
  String description = '所选时间阅读总时长',
  bool hasData = true,
  List<ReadingStatMetric> stats = const [
    ReadingStatMetric(value: '5天', label: '阅读'),
    ReadingStatMetric(value: '57分', label: '日均'),
    ReadingStatMetric(value: '3本', label: '读过'),
  ],
  List<ReadingRhythmStat>? rhythmStats,
}) {
  final chartStats = rhythmStats ??
      [
        ReadingRhythmStat(
          label: '一',
          minutes: 82,
          start: DateTime(2024, 5, 20),
          end: DateTime(2024, 5, 20),
        ),
      ];
  return ReadingStatsSummary(
    range: range,
    totalLabel: totalLabel,
    description: description,
    stats: stats,
    rhythmStats: chartStats,
    rhythmGranularity: range.rhythmGranularity,
    rhythmSubtitle: range.rhythmSubtitle,
    contributions: hasData
        ? const [
            BookReadingContribution(
              title: '三体',
              durationLabel: '2h 30m',
              ratio: 1,
            ),
            BookReadingContribution(
              title: '长安的荔枝',
              durationLabel: '1h 50m',
              ratio: 0.7,
            ),
            BookReadingContribution(
              title: '云边有个小卖部',
              durationLabel: '1h 10m',
              ratio: 0.45,
            ),
          ]
        : const [],
    sheetSummary: range.rhythmSubtitle,
    hasData: hasData,
  );
}
