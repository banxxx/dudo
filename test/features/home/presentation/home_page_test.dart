import 'package:dudo/features/home/presentation/home_page.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:dudo/shared/utils/time_greeting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('dudo light color tokens match the design spec', () {
    expect(DudoColors.paperBackground, const Color(0xFFF8F4EA));
    expect(DudoColors.surface, const Color(0xFFFFFBF2));
    expect(DudoColors.primary, const Color(0xFF5E6F5B));
    expect(DudoColors.textPrimary, const Color(0xFF25251F));
    expect(DudoColors.outline, const Color(0xFFD8CDBB));
  });

  testWidgets('home page renders the starter header without reading data',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DudoColors.paperBackground);

    expect(find.text('今天想读点什么？'), findsOneWidget);
    expect(find.text('还没有正在读的书，先从灵感书单开始。'), findsOneWidget);
    expect(find.text('阅读入口'), findsOneWidget);
    expect(find.text('开始新的阅读'), findsOneWidget);
    expect(find.text('清晨的安静里，翻开一本新的故事。'), findsOneWidget);
    expect(find.text('去找书'), findsOneWidget);
    expect(find.text('3 本'), findsOneWidget);
    expect(find.text('适合今天'), findsOneWidget);
    expect(find.text('今日阅读'), findsNothing);
    expect(find.text('继续阅读'), findsNothing);

    expect(find.text('找书'), findsOneWidget);
    expect(find.text('书签'), findsOneWidget);
    expect(find.text('统计'), findsOneWidget);
    expect(find.text('为你精选'), findsOneWidget);

    final firstCover = tester.getSize(
      find.ancestor(
        of: find.text('ZHANG'),
        matching: find.byType(AspectRatio),
      ),
    );
    expect(firstCover.height, greaterThan(firstCover.width));

    await tester.scrollUntilVisible(
      find.text('本周节奏'),
      120,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('本周节奏'), findsOneWidget);
  });

  testWidgets('home page keeps the reading header when reading data exists',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomePage(hasReadingData: true),
        ),
      ),
    );

    expect(find.text('今日阅读'), findsOneWidget);
    expect(find.text('${timeGreeting()}，继续沉入书页'), findsOneWidget);
    expect(find.text('继续阅读'), findsOneWidget);
    expect(find.text('三体 · 第 24 章'), findsOneWidget);
    expect(find.text('今天想读点什么？'), findsNothing);
    expect(find.text('开始新的阅读'), findsNothing);
  });
}
