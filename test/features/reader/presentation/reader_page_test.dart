import 'package:dudo/features/reader/presentation/reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpReader(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReaderPage(bookId: 'mock-book'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders Pencil D7 pure reading state with mock chapter',
      (tester) async {
    await pumpReader(tester);

    expect(find.text('旧世界的回声'), findsOneWidget);
    expect(find.text('第一章'), findsNWidgets(2));
    expect(find.textContaining('罗辑醒来的时候'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-top-controls')), findsNothing);
    expect(find.byKey(const ValueKey('reader-bottom-controls')), findsNothing);

    final articleTopLeft =
        tester.getTopLeft(find.byKey(const ValueKey('reader-article')));
    final progressTopLeft =
        tester.getTopLeft(find.byKey(const ValueKey('reader-progress')));
    expect(articleTopLeft.dx, 30);
    expect(articleTopLeft.dy, 92);
    expect(progressTopLeft.dx, 30);
    expect(progressTopLeft.dy, 766);
  });

  testWidgets('tap shows Pencil D1 warm reader controls', (tester) async {
    await pumpReader(tester);

    await tester.tap(find.byKey(const ValueKey('reader-page')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-top-controls')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reader-bottom-controls')), findsOneWidget);
    expect(find.text('目录'), findsOneWidget);
    expect(find.text('排版'), findsOneWidget);
    expect(find.text('主题'), findsOneWidget);
    expect(find.text('听书'), findsOneWidget);
    expect(find.text('翻页'), findsOneWidget);

    final topControls =
        tester.getTopLeft(find.byKey(const ValueKey('reader-top-controls')));
    final bottomControls =
        tester.getTopLeft(find.byKey(const ValueKey('reader-bottom-controls')));
    expect(topControls.dx, 16);
    expect(topControls.dy, 74);
    expect(bottomControls.dx, 16);
    expect(bottomControls.dy, 700);
  });

  testWidgets('bottom tools open D2-D5 and D8 panels', (tester) async {
    await pumpReader(tester);
    await tester.tap(find.byKey(const ValueKey('reader-page')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('目录'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-catalog-sheet')), findsOneWidget);
    expect(find.text('共 42 章'), findsOneWidget);

    await tester.tap(find.byTooltip('收起目录'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('排版'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('reader-typography-panel')), findsOneWidget);
    expect(find.text('阅读排版'), findsOneWidget);

    await tester.tap(find.text('主题'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-theme-panel')), findsOneWidget);
    expect(find.text('阅读主题'), findsOneWidget);

    await tester.tap(find.text('听书'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('reader-listening-panel')), findsOneWidget);
    expect(find.text('正在听书'), findsOneWidget);

    await tester.tap(find.text('翻页'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('reader-page-turn-panel')), findsOneWidget);
    expect(find.text('翻页方式'), findsOneWidget);
  });

  testWidgets('top more opens Pencil D6 popover', (tester) async {
    await pumpReader(tester);
    await tester.tap(find.byKey(const ValueKey('reader-page')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-more-popover')), findsOneWidget);
    expect(find.text('加入书签'), findsOneWidget);
    expect(find.text('内容反馈'), findsOneWidget);
  });
}
