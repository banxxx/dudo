import 'package:dudo/app/router/app_router.dart';
import 'package:dudo/features/settings/about/data/external_link_launcher.dart';
import 'package:dudo/features/settings/about/domain/about_links.dart';
import 'package:dudo/features/settings/about/domain/about_platform.dart';
import 'package:dudo/features/settings/about/presentation/about_app_view.dart';
import 'package:dudo/features/settings/about/presentation/about_feedback_page.dart';
import 'package:dudo/features/settings/about/presentation/about_guide_page.dart';
import 'package:dudo/features/settings/about/presentation/about_privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Widget host(
    AboutPlatform platform, {
    ExternalLinkLauncher? launcher,
  }) {
    return ProviderScope(
      overrides: [
        if (launcher != null)
          externalLinkLauncherProvider.overrideWithValue(launcher),
      ],
      child: MaterialApp(
        home: AboutAppView(platform: platform),
      ),
    );
  }

  testWidgets('describes the update target with the current platform', (
    tester,
  ) async {
    await tester.pumpWidget(host(AboutPlatform.android));
    expect(find.textContaining('Android 安装包'), findsOneWidget);

    await tester.pumpWidget(host(AboutPlatform.ios));
    expect(find.textContaining('iOS 版本'), findsOneWidget);
    expect(find.textContaining('Android 安装包'), findsNothing);
  });

  testWidgets('shows a single 检测更新 action with a separate 查看日志', (
    tester,
  ) async {
    await tester.pumpWidget(host(AboutPlatform.android));

    expect(find.text('检测更新'), findsOneWidget);
    expect(find.text('查看日志'), findsOneWidget);
    expect(find.text('仓库地址'), findsOneWidget);
  });

  testWidgets('switches to the update-found state after checking', (
    tester,
  ) async {
    await tester.pumpWidget(host(AboutPlatform.android));

    await tester.tap(find.text('检测更新'));
    await tester.pumpAndSettle();

    expect(find.text('发现新版本'), findsOneWidget);
    expect(find.text('立即下载'), findsOneWidget);
    expect(find.text('检测更新'), findsNothing);
    expect(find.text('待检测'), findsNothing);
    expect(find.text('v0.1.1'), findsOneWidget);
  });

  testWidgets('feedback row opens the in-app feedback page', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.aboutApp,
      routes: [
        GoRoute(
          path: AppRoutes.aboutApp,
          builder: (_, __) => const AboutAppView(
            platform: AboutPlatform.android,
          ),
        ),
        GoRoute(
          path: AppRoutes.aboutFeedback,
          builder: (_, __) => const AboutFeedbackPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await _tapRow(tester, '反馈与建议');

    expect(find.text('posoovo@gmail.com'), findsOneWidget);
    expect(find.text('GitHub Issues'), findsOneWidget);
  });

  testWidgets('repository button opens the project home', (tester) async {
    final launcher = _FakeLauncher();
    await tester.pumpWidget(
      host(AboutPlatform.android, launcher: launcher),
    );

    await _tapRow(tester, '仓库地址');

    expect(launcher.opened, [AboutLinks.repository]);
  });

  testWidgets('help rows navigate to the guide and privacy pages', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.aboutApp,
      routes: [
        GoRoute(
          path: AppRoutes.aboutApp,
          builder: (_, __) => const AboutAppView(
            platform: AboutPlatform.android,
          ),
        ),
        GoRoute(
          path: AppRoutes.aboutGuide,
          builder: (_, __) => const AboutGuidePage(),
        ),
        GoRoute(
          path: AppRoutes.aboutPrivacy,
          builder: (_, __) => const AboutPrivacyPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await _tapRow(tester, '使用说明');
    expect(find.text('添加书源或本地书籍'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    await _tapRow(tester, '隐私政策');
    expect(find.text('数据保存在本机'), findsOneWidget);
  });
}

/// Scrolls the about page's list until [label] is on screen, then taps it.
Future<void> _tapRow(WidgetTester tester, String label) async {
  final finder = find.text(label);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _FakeLauncher implements ExternalLinkLauncher {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}
