import 'package:dudo/app/router/app_router.dart';
import 'package:dudo/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main tab route constants match the paper navigation structure', () {
    expect(AppRoutes.home, '/home');
    expect(AppRoutes.homeName, 'home');
    expect(AppRoutes.bookshelf, '/bookshelf');
    expect(AppRoutes.search, '/search');
    expect(AppRoutes.profile, '/profile');
    expect(AppRoutes.settings, '/settings');
    expect(AppRoutes.readingStats, '/reading-stats');
  });

  testWidgets('router starts on home and exposes the designed bottom tabs',
      (tester) async {
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

  testWidgets('opens reading stats from profile tools', (tester) async {
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

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('阅读记录'));
    await tester.pumpAndSettle();

    expect(find.text('阅读统计'), findsOneWidget);
    expect(find.text('6h 40m'), findsOneWidget);
  });
}
