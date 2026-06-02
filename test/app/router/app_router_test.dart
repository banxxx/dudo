import 'package:dudo/app/router/app_router.dart';
import 'package:dudo/core/utils/breakpoints.dart';
import 'package:dudo/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
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
    await tester.pumpAndSettle();
  }

  test('main tab route constants match the paper navigation structure', () {
    expect(AppRoutes.home, '/home');
    expect(AppRoutes.homeName, 'home');
    expect(AppRoutes.bookmarks, '/home/bookmarks');
    expect(AppRoutes.bookmarksName, 'bookmarks');
    expect(AppRoutes.bookshelf, '/bookshelf');
    expect(AppRoutes.search, '/search');
    expect(AppRoutes.profile, '/profile');
    expect(AppRoutes.settings, '/settings');
    expect(AppRoutes.readingStats, '/reading-stats');
  });

  testWidgets('router starts on home and exposes the designed bottom tabs',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('晚上好，继续沉入书页'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('书架'), findsOneWidget);
    expect(find.text('搜索'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('书源'), findsNothing);

    await tester.tap(find.text('书架'));
    await tester.pumpAndSettle();

    expect(find.text('晚上好，继续沉入书页'), findsNothing);
    expect(find.text('书架还是空的'), findsOneWidget);

    await tester.tap(find.text('搜索'));
    await tester.pumpAndSettle();

    expect(find.text('探索书源与作品'), findsOneWidget);
    expect(find.text('搜索书名、作者、关键词'), findsOneWidget);
    expect(find.text('常用书源'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('纸上旅人'), findsOneWidget);
    expect(find.text('五月阅读目标'), findsOneWidget);
    expect(find.text('书房工具'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('偏好中心'), findsOneWidget);
    expect(find.text('阅读体验'), findsOneWidget);
    expect(find.text('内容与书源'), findsOneWidget);
  });

  testWidgets('home quick actions navigate to search, bookmarks, and stats',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('找书'));
    await tester.pumpAndSettle();
    expect(find.text('探索书源与作品'), findsOneWidget);

    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('书签'));
    await tester.pumpAndSettle();
    expect(find.text('阅读标记'), findsOneWidget);
    expect(find.text('暂无书签和高亮'), findsOneWidget);

    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('统计'));
    await tester.pumpAndSettle();
    expect(find.text('阅读统计'), findsOneWidget);
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

  testWidgets('opens reading stats from profile tools', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('阅读记录'));
    await tester.pumpAndSettle();

    expect(find.text('阅读统计'), findsOneWidget);
    expect(find.text('6h 40m'), findsOneWidget);
  });
}
