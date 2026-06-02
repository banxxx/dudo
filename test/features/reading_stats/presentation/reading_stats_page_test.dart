import 'package:dudo/features/reading_stats/application/reading_stats_provider.dart';
import 'package:dudo/features/reading_stats/domain/reading_stats_models.dart';
import 'package:dudo/features/reading_stats/presentation/reading_stats_page.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders the H2 reading stats design with data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingStatsTodayProvider.overrideWithValue(DateTime(2024, 5, 22)),
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
    await tester.pumpAndSettle();

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
    expect(find.text('每日阅读分布'), findsOneWidget);
    expect(find.text('峰值 82m'), findsOneWidget);
    expect(find.text('书籍贡献'), findsOneWidget);
    expect(find.text('三体'), findsOneWidget);
    expect(find.text('长安的荔枝'), findsOneWidget);
    expect(find.text('云边有个小卖部'), findsOneWidget);
  });

  testWidgets('renders H1 empty state from a custom empty range',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingStatsRangeProvider
              .overrideWith((_) => ReadingStatsRange.custom()),
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
    await tester.pumpAndSettle();

    expect(find.text('自定义'), findsOneWidget);
    expect(find.text('0m'), findsOneWidget);
    expect(find.text('本周还没有阅读记录'), findsOneWidget);
    expect(find.text('0天'), findsOneWidget);
    expect(find.text('0分'), findsOneWidget);
    expect(find.text('0本'), findsOneWidget);
    expect(find.text('暂无数据'), findsOneWidget);
    expect(find.text('开始阅读后生成节奏'), findsOneWidget);
  });

  testWidgets('opens H3-H5 date range sheet and switches presets',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingStatsTodayProvider.overrideWithValue(DateTime(2024, 5, 22)),
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
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-stats-range-button')));
    await tester.pumpAndSettle();

    expect(find.text('选择时间'), findsOneWidget);
    expect(find.text('2024年5月'), findsOneWidget);
    expect(find.text('本周阅读 6h 40m · 连续 5 天'), findsOneWidget);

    await tester.tap(find.text('本月').last);
    await tester.pumpAndSettle();
    expect(find.text('本月阅读 24h 15m · 读过 9 本'), findsOneWidget);

    await tester.tap(find.text('自定义').last);
    await tester.pumpAndSettle();
    expect(find.text('自定义时间'), findsOneWidget);
    expect(find.text('自定义 11 天 · 预计 10h 30m'), findsOneWidget);

    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(find.text('0m'), findsOneWidget);
    expect(find.text('开始阅读后生成节奏'), findsOneWidget);
  });
}
