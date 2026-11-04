import 'package:dudo/app/router/app_router.dart';
import 'package:dudo/features/profile/application/profile_providers.dart';
import 'package:dudo/features/profile/presentation/profile_page.dart';
import 'package:dudo/features/reading_goal/application/reading_goal_overview.dart';
import 'package:dudo/features/reading_goal/application/reading_goal_providers.dart';
import 'package:dudo/features/reading_goal/domain/reading_goal.dart';
import 'package:dudo/features/reading_stats/domain/reading_stats_models.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('renders the Pencil F1 profile design', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileSummaryProvider.overrideWith(
            (_) async => const ProfileSummary(
              monthReadingLabel: '12h',
              shelfCount: 38,
              bookmarkCount: 7,
            ),
          ),
          readingGoalProvider.overrideWith(
            (_) => Stream<ReadingGoal?>.value(ReadingGoal.defaults()),
          ),
          readingGoalOverviewProvider.overrideWith((_) async => _overview()),
        ],
        child: const MaterialApp(
          home: ProfilePage(),
        ),
      ),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DudoColors.paperBackground);

    expect(find.text('纸上旅居'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('读'), findsOneWidget);
    expect(find.text('纸上旅人'), findsOneWidget);
    expect(find.text('读过的日子，都收在这里。'), findsOneWidget);
    expect(find.text('静读会员'), findsNothing);
    expect(find.text('12h'), findsOneWidget);
    expect(find.text('本月阅读'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('书签'), findsOneWidget);
    expect(find.text('五月阅读目标'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('距离 20 小时目标还差 4 小时 24 分钟。'), findsOneWidget);
    expect(find.text('书房工具'), findsOneWidget);
    expect(find.text('阅读记录'), findsOneWidget);
    expect(find.text('最近打开的书与阅读位置'), findsOneWidget);
    expect(find.text('离线缓存'), findsOneWidget);
    expect(find.text('管理已下载章节'), findsOneWidget);
    expect(find.text('笔记摘录'), findsOneWidget);
    expect(find.text('整理高亮与想法'), findsOneWidget);
    // Data sync lives in settings only, not in the profile tools.
    expect(find.text('数据同步'), findsNothing);
    expect(find.text('云端保持最新'), findsNothing);

    final eyebrow = tester.widget<Text>(find.text('纸上旅居'));
    expect(eyebrow.style?.color, DudoColors.secondary);
    expect(eyebrow.style?.fontSize, 11);

    final title = tester.widget<Text>(find.text('我的'));
    expect(title.style?.color, DudoColors.textPrimary);
    expect(title.style?.fontSize, 28);
    expect(title.style?.fontWeight, FontWeight.w700);

    final identityCardFinder = find
        .ancestor(
          of: find.text('纸上旅人'),
          matching: find.byType(Container),
        )
        .last;
    final identityCard = tester.widget<Container>(identityCardFinder);
    final identityDecoration = identityCard.decoration! as BoxDecoration;
    expect(identityCard.padding, const EdgeInsets.all(16));
    expect(identityDecoration.color, DudoColors.textPrimary);
    expect(identityDecoration.borderRadius, BorderRadius.circular(26));

    final avatar = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('读'),
            matching: find.byType(Container),
          )
          .first,
    );
    final avatarDecoration = avatar.decoration! as BoxDecoration;
    expect(avatar.constraints?.maxWidth, 76);
    expect(avatar.constraints?.maxHeight, 76);
    expect(avatarDecoration.color, DudoColors.primaryContainer);
    expect(avatarDecoration.borderRadius, BorderRadius.circular(38));

    final name = tester.widget<Text>(find.text('纸上旅人'));
    expect(name.style?.color, DudoColors.surfaceHigh);
    expect(name.style?.fontSize, 24);
    expect(name.style?.fontWeight, FontWeight.w700);

    final bio = tester.widget<Text>(find.text('读过的日子，都收在这里。'));
    expect(bio.style?.color, DudoColors.onInkMuted);
    expect(bio.style?.fontSize, 12);
    expect(bio.style?.height, 1.4);

    // The three numbers live inside the identity card, below a hairline, so
    // the goal card stays the only data-accent block on the page.
    final statsFinder = find.byKey(const ValueKey('profile-stat-month'));
    expect(
      find.descendant(of: identityCardFinder, matching: statsFinder),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('profile-stat-shelf')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('profile-stat-bookmarks')), findsOneWidget);
    expect(find.byIcon(LucideIcons.hourglass), findsOneWidget);
    expect(find.byIcon(LucideIcons.libraryBig), findsOneWidget);
    expect(find.byIcon(LucideIcons.bookmark), findsOneWidget);

    // The first column starts on the avatar's left edge.
    final avatarFinder = find
        .ancestor(of: find.text('读'), matching: find.byType(Container))
        .first;
    final avatarLeft = tester.getTopLeft(avatarFinder).dx;
    final statLeft = tester.getTopLeft(find.byIcon(LucideIcons.hourglass)).dx;
    expect(statLeft, closeTo(avatarLeft, 0.5));

    final statValue = tester.widget<Text>(find.text('12h'));
    expect(statValue.style?.color, DudoColors.onInk);
    expect(statValue.style?.fontSize, 20);
    expect(statValue.style?.fontWeight, FontWeight.w700);

    final statLabel = tester.widget<Text>(find.text('本月阅读'));
    expect(statLabel.style?.color, DudoColors.onInkMuted);
    expect(statLabel.style?.fontSize, 11);

    final goalCardFinder = find
        .ancestor(
          of: find.text('五月阅读目标'),
          matching: find.byType(Container),
        )
        .last;
    final goalCard = tester.widget<Container>(goalCardFinder);
    final goalDecoration = goalCard.decoration! as BoxDecoration;
    expect(goalCard.padding, const EdgeInsets.all(14));
    expect(goalDecoration.color, DudoColors.primaryContainer);
    expect(goalDecoration.borderRadius, BorderRadius.circular(26));

    // The goal reads as a compact echo of the goal page's donut.
    final ring = find.byKey(const ValueKey('profile-goal-ring'));
    expect(ring, findsOneWidget);
    expect(tester.getSize(ring), const Size(62, 62));

    // The chevron sits on the card's vertical centre line, not on the title.
    final chevron = find.descendant(
      of: goalCardFinder,
      matching: find.byIcon(LucideIcons.chevronRight),
    );
    expect(chevron, findsOneWidget);
    expect(
      tester.getCenter(chevron).dy,
      closeTo(tester.getCenter(goalCardFinder).dy, 0.5),
    );
    expect(
      tester.getCenter(ring).dy,
      closeTo(tester.getCenter(goalCardFinder).dy, 0.5),
    );

    final percent = tester.widget<Text>(find.text('78%'));
    expect(percent.style?.color, DudoColors.primary);
    expect(percent.style?.fontSize, 13.5);
    expect(percent.style?.fontWeight, FontWeight.w700);

    final toolRow = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('阅读记录'),
            matching: find.byType(Container),
          )
          .last,
    );
    final toolDecoration = toolRow.decoration! as BoxDecoration;
    expect(toolRow.constraints?.minHeight, 68);
    expect(
      toolRow.padding,
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
    expect(toolDecoration.color, DudoColors.surface);
    expect(toolDecoration.borderRadius, BorderRadius.circular(20));
    expect(toolDecoration.border?.top.color, DudoColors.outlineVariant);

    final toolTitle = tester.widget<Text>(find.text('阅读记录'));
    expect(toolTitle.style?.color, DudoColors.textPrimary);
    expect(toolTitle.style?.fontSize, 14.5);
    expect(toolTitle.style?.fontWeight, FontWeight.w600);

    final toolDescription =
        tester.widget<Text>(find.text('最近打开的书与阅读位置'));
    expect(toolDescription.style?.color, DudoColors.secondary);
    expect(toolDescription.style?.fontSize, 11.5);
  });

  testWidgets('renders the F1-1 empty goal card without a saved goal',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileSummaryProvider.overrideWith(
            (_) async => const ProfileSummary(
              monthReadingLabel: '12h',
              shelfCount: 38,
              bookmarkCount: 7,
            ),
          ),
          readingGoalProvider.overrideWith(
            (_) => Stream<ReadingGoal?>.value(null),
          ),
          readingGoalOverviewProvider.overrideWith((_) async => null),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('还没有阅读目标'), findsOneWidget);
    expect(find.text('设定每月目标，让阅读有迹可循'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-goal-ring')), findsNothing);

    final emptyCard = tester.widget<Container>(
      find.byKey(const ValueKey('profile-goal-empty-card')),
    );
    final decoration = emptyCard.decoration! as BoxDecoration;
    expect(emptyCard.padding, const EdgeInsets.all(14));
    expect(decoration.color, DudoColors.surface);
    expect(decoration.borderRadius, BorderRadius.circular(26));
    expect(decoration.border?.top.color, DudoColors.outlineVariant);
    expect(find.byIcon(LucideIcons.flag), findsOneWidget);
  });

  testWidgets('shows the empty card when the saved goal is closed',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileSummaryProvider.overrideWith(
            (_) async => const ProfileSummary(
              monthReadingLabel: '12h',
              shelfCount: 38,
              bookmarkCount: 7,
            ),
          ),
          readingGoalProvider.overrideWith(
            (_) => Stream<ReadingGoal?>.value(
              ReadingGoal.defaults().copyWith(enabled: false),
            ),
          ),
          readingGoalOverviewProvider.overrideWith((_) async => _overview()),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('还没有阅读目标'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-goal-empty-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-goal-ring')), findsNothing);
    // The profile card is only an entry point; opening/closing lives in the
    // goal page header, so no enable button appears here.
    expect(find.text('开启目标'), findsNothing);
  });

  testWidgets('stat cells open their destinations', (tester) async {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        GoRoute(
          path: AppRoutes.readingStats,
          builder: (_, __) => const Scaffold(body: Text('阅读记录页')),
        ),
        GoRoute(
          path: AppRoutes.bookmarks,
          builder: (_, __) => const Scaffold(body: Text('书签页')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileSummaryProvider.overrideWith(
            (_) async => const ProfileSummary(
              monthReadingLabel: '12h',
              shelfCount: 38,
              bookmarkCount: 7,
            ),
          ),
          readingGoalProvider.overrideWith(
            (_) => Stream<ReadingGoal?>.value(ReadingGoal.defaults()),
          ),
          readingGoalOverviewProvider.overrideWith((_) async => _overview()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const ValueKey('profile-stat-month')));
    await tester.pumpAndSettle();
    expect(find.text('阅读记录页'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile-stat-bookmarks')));
    await tester.pumpAndSettle();
    expect(find.text('书签页'), findsOneWidget);
  });
}

ReadingGoalOverview _overview() {
  final now = DateTime(2026, 5, 20);
  const minutes = [34, 44, 26, 52, 40, 48, 22];
  return ReadingGoalOverview.build(
    goal: ReadingGoal.defaults(),
    stats: ReadingMonthStats(
      month: DateTime(2026, 5),
      totalSeconds: 15 * 3600 + 36 * 60,
      chaptersRead: 12,
      charactersRead: 168000,
      recordedDays: 23,
      daysInMonth: 31,
      streakDays: 6,
    ),
    weekRhythm: [
      for (var i = 0; i < minutes.length; i++)
        ReadingRhythmStat(
          label: '一二三四五六日'[i],
          minutes: minutes[i],
          start: now,
          end: now,
        ),
    ],
    now: now,
  );
}
