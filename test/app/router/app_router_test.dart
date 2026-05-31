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
    expect(find.text('书架还空着，点击右下角搜索来添加一本书吧'), findsOneWidget);
  });
}
