import 'package:dudo/app/router/app_router.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/core/utils/breakpoints.dart';
import 'package:dudo/features/bookmarks/application/bookmarks_providers.dart';
import 'package:dudo/features/bookmarks/domain/bookmark_entry.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/profile/application/profile_providers.dart';
import 'package:dudo/features/reading_goal/application/reading_goal_overview.dart';
import 'package:dudo/features/reading_goal/application/reading_goal_providers.dart';
import 'package:dudo/features/reading_goal/domain/reading_goal.dart';
import 'package:dudo/features/reading_history/application/reading_history_provider.dart';
import 'package:dudo/features/reading_history/domain/reading_history_entry.dart';
import 'package:dudo/features/reading_stats/application/reading_stats_provider.dart';
import 'package:dudo/features/reading_stats/domain/reading_stats_models.dart';
import 'package:dudo/features/settings/data_sync_settings/application/data_sync_settings_provider.dart';
import 'package:dudo/features/settings/data_sync_settings/data/data_sync_api.dart';
import 'package:dudo/features/settings/data_sync_settings/data/data_sync_settings_repository.dart';
import 'package:dudo/features/settings/data_sync_settings/data/sync_snapshot_repository.dart';
import 'package:dudo/features/settings/data_sync_settings/domain/data_sync_settings.dart';
import 'package:dudo/features/settings/data_sync_settings/domain/sync_snapshot.dart';
import 'package:dudo/features/settings/start_page_settings/domain/start_page_settings.dart';
import 'package:dudo/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpNavigation(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapBottomTab(WidgetTester tester, int index) async {
    const labels = ['首页', '书架', '搜索', '我的'];
    final tab = find
        .ancestor(
          of: find.text(labels[index]),
          matching: find.byType(GestureDetector),
        )
        .last;
    await tester.tap(tab);
    await pumpNavigation(tester);
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingStatsSummaryProvider.overrideWith(
            (_) async => _routerReadingStatsSummary(),
          ),
          profileSummaryProvider.overrideWith(
            (_) async => ProfileSummary.empty,
          ),
          readingGoalOverviewProvider.overrideWith(
            (_) async => _routerGoalOverview(),
          ),
          ...overrides,
        ],
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp.router(
              routerConfig: ref.watch(appRouterProvider),
              locale: const Locale('zh', 'CN'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
            );
          },
        ),
      ),
    );
    await pumpNavigation(tester);
  }

  test('main tab route constants match the paper navigation structure', () {
    expect(AppRoutes.home, '/home');
    expect(AppRoutes.homeName, 'home');
    expect(AppRoutes.bookmarks, '/bookmarks');
    expect(AppRoutes.bookmarksName, 'bookmarks');
    expect(AppRoutes.bookshelf, '/bookshelf');
    expect(AppRoutes.search, '/search');
    expect(AppRoutes.profile, '/profile');
    expect(AppRoutes.settings, '/settings');
    expect(AppRoutes.readingStats, '/reading-stats');
    expect(AppRoutes.readingHistory, '/reading-history');
  });

  testWidgets('router starts on home and exposes the designed bottom tabs',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(Breakpoints.medium - 1, 800);
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    expect(find.text('今天想读点什么？'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('书架'), findsOneWidget);
    expect(find.text('搜索'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('书源'), findsNothing);

    await tapBottomTab(tester, 1);

    expect(find.text('晚上好，继续沉入书页'), findsNothing);
    expect(find.text('我的书架'), findsOneWidget);

    await tapBottomTab(tester, 2);

    expect(find.text('探索书源与作品'), findsOneWidget);
    expect(find.text('搜索书名、作者、关键词'), findsOneWidget);
    expect(find.text('常用书源'), findsNothing);

    await tapBottomTab(tester, 3);

    expect(find.text('纸上旅人'), findsOneWidget);
    expect(find.text('五月阅读目标'), findsOneWidget);
    expect(find.text('书房工具'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-settings-button')));
    await pumpNavigation(tester);

    expect(find.text('偏好中心'), findsOneWidget);
    expect(find.text('阅读体验'), findsOneWidget);
    expect(find.text('内容与书源'), findsOneWidget);
  });

  testWidgets('router starts on the saved startup page', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(Breakpoints.medium - 1, 800);
    addTearDown(tester.view.reset);
    StartPageSettings.remember(
      const StartPageSettings(page: StartPage.search),
    );
    addTearDown(
      () => StartPageSettings.remember(StartPageSettings.defaults()),
    );

    await pumpApp(tester);

    expect(find.text('探索书源与作品'), findsOneWidget);
    expect(find.text('今天想读点什么？'), findsNothing);
    // The shell still shows the full tab bar around the chosen branch; the
    // search page title and its tab share the same label.
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('搜索'), findsNWidgets(2));
  });

  testWidgets('home quick actions navigate to search, bookmarks, and stats',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(Breakpoints.medium - 1, 800);
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      overrides: [
        bookmarkEntriesProvider.overrideWith(
          (_) => Stream.value(const <BookmarkEntry>[]),
        ),
      ],
    );

    await tester.tap(find.text('找书'));
    await pumpNavigation(tester);
    expect(find.text('探索书源与作品'), findsOneWidget);

    await tapBottomTab(tester, 0);
    await tester.tap(find.text('书签'));
    await pumpNavigation(tester);
    expect(find.text('阅读标记'), findsOneWidget);
    expect(find.text('暂无书签和高亮'), findsOneWidget);
    expect(find.byKey(const ValueKey('bookmarks-back-button')), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('首页'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('bookmarks-back-button')));
    await pumpNavigation(tester);
    expect(find.text('今天想读点什么？'), findsOneWidget);
    await tester.tap(find.text('统计'));
    await pumpNavigation(tester);
    expect(find.text('阅读记录'), findsWidgets);
    expect(find.text('本周节奏'), findsOneWidget);
  });

  testWidgets('uses bottom tabs on phone widths', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(Breakpoints.medium - 1, 800);
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('书架'), findsOneWidget);
  });

  testWidgets('uses compact navigation rail on tablet widths', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(Breakpoints.medium, 900);
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
  });

  testWidgets('uses extended navigation rail on large widths', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(Breakpoints.large, 900);
    addTearDown(tester.view.reset);

    await pumpApp(tester);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
  });

  testWidgets('opens data sync from the settings page', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(Breakpoints.medium - 1, 800);
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      overrides: [
        dataSyncSettingsRepositoryProvider.overrideWithValue(
          _FakeDataSyncSettingsRepository(),
        ),
        dataSyncApiProvider.overrideWithValue(_FakeDataSyncApi()),
        syncSnapshotRepositoryProvider.overrideWithValue(
          _FakeSyncSnapshots(),
        ),
        shelfBooksProvider.overrideWith(
          (_) => Stream.value(const <Book>[]),
        ),
        bookmarkEntriesProvider.overrideWith(
          (_) => Stream.value(const <BookmarkEntry>[]),
        ),
      ],
    );

    await tapBottomTab(tester, 3);
    await tester.tap(find.byKey(const ValueKey('profile-settings-button')));
    await pumpNavigation(tester);

    // The settings list scrolls past the 800px test viewport.
    await tester.ensureVisible(find.text('数据同步'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('数据同步'));
    await pumpNavigation(tester);

    expect(
      find.byKey(const ValueKey('data-sync-server-url')),
      findsOneWidget,
    );
    expect(find.text('尚未连接服务器'), findsOneWidget);
  });

  testWidgets('opens reading history from profile tools', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(Breakpoints.medium - 1, 800);
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      overrides: [
        readingHistoryProvider.overrideWith(
          (_) async => [_routerHistoryEntry()],
        ),
      ],
    );

    await tapBottomTab(tester, 3);

    await tester.tap(find.text('阅读记录'));
    await pumpNavigation(tester);

    expect(find.text('阅读记录'), findsWidgets);
    expect(find.text('云边有个小卖部'), findsOneWidget);
    expect(find.text('继续读'), findsOneWidget);
    // The weekly rhythm stays behind home → 统计, not this entry.
    expect(find.text('本周节奏'), findsNothing);
  });
}

ReadingHistoryEntry _routerHistoryEntry() {
  final now = DateTime(2024, 5, 22, 9, 30);
  return ReadingHistoryEntry(
    book: Book(
      id: 'history-book',
      title: '云边有个小卖部',
      author: '张嘉佳',
      lastChapterIndex: 11,
      lastReadPosition: 120,
      createdAt: now,
      updatedAt: now,
      inShelf: true,
      sortOrder: 0,
      coverShowText: true,
    ),
    chapterCount: 24,
    chapterTitle: '海边的风',
    percent: 36,
  );
}

ReadingStatsSummary _routerReadingStatsSummary() {
  final range = ReadingStatsRange.weekOf(DateTime(2024, 5, 22));
  return ReadingStatsSummary(
    range: range,
    totalLabel: '6h 40m',
    description: '本周阅读总时长',
    stats: const [
      ReadingStatMetric(value: '5天', label: '阅读'),
      ReadingStatMetric(value: '57分', label: '日均'),
      ReadingStatMetric(value: '3本', label: '读过'),
    ],
    rhythmStats: [
      ReadingRhythmStat(
        label: '三',
        minutes: 82,
        start: DateTime(2024, 5, 22),
        end: DateTime(2024, 5, 22),
      ),
    ],
    rhythmGranularity: range.rhythmGranularity,
    rhythmSubtitle: range.rhythmSubtitle,
    contributions: const [
      BookReadingContribution(
        title: '三体',
        durationLabel: '2h 30m',
        ratio: 1,
      ),
    ],
    sheetSummary: range.rhythmSubtitle,
    hasData: true,
    readingDays: 5,
    totalMinutes: 400,
    chaptersRead: 12,
    wordsRead: 68000,
    sessionCount: 18,
    longestSessionMinutes: 48,
    bestDayLabel: '周三',
    bestDayMinutes: 82,
  );
}

class _FakeDataSyncSettingsRepository implements DataSyncSettingsRepository {
  DataSyncSettings _settings = DataSyncSettings.defaults();

  @override
  Future<DataSyncSettings> load() async => _settings;

  @override
  Future<void> save(DataSyncSettings settings) async => _settings = settings;

  @override
  Stream<DataSyncSettings> watch() => Stream.value(_settings);
}

class _FakeDataSyncApi implements DataSyncApi {
  @override
  Future<void> ping({required String serverUrl, String? accessToken}) async {}

  @override
  Future<SyncSnapshot?> sync({
    required String serverUrl,
    String? accessToken,
    required SyncSnapshot snapshot,
  }) async =>
      null;
}

class _FakeSyncSnapshots implements SyncSnapshotStore {
  @override
  Future<SyncSnapshot> build({
    required bool includeBooks,
    required bool includeAnnotations,
    required bool includeSettings,
  }) async =>
      SyncSnapshot(generatedAt: DateTime.now());

  @override
  Future<void> apply(SyncSnapshot snapshot) async {}
}

ReadingGoalOverview _routerGoalOverview() {
  final now = DateTime(2026, 5, 20);
  return ReadingGoalOverview.build(
    goal: ReadingGoal.defaults(),
    stats: ReadingMonthStats(
      month: DateTime(2026, 5),
      totalSeconds: 0,
      chaptersRead: 0,
      charactersRead: 0,
      recordedDays: 0,
      daysInMonth: 31,
      streakDays: 0,
    ),
    weekRhythm: const [],
    now: now,
  );
}
