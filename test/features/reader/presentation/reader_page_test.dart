import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/bookshelf/data/bookshelf_repository.dart';
import 'package:dudo/features/reader/presentation/reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpReader(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final repository = _NoopBookshelfRepository();
    final now = DateTime(2026, 6, 3);
    final book = Book(
      id: 'mock-book',
      title: '旧世界的回声',
      author: '测试作者',
      localPath: '/books/mock.txt',
      lastChapterIndex: 0,
      lastReadPosition: 0,
      createdAt: now,
      updatedAt: now,
      inShelf: true,
      sortOrder: 1,
    );
    final chapters = List.generate(42, (index) {
      final title = index == 0 ? '第一章' : '第${index + 1}章';
      return Chapter(
        id: 'chapter-$index',
        bookId: 'mock-book',
        chapterIndex: index,
        title: title,
        content: index == 0
            ? List.filled(200, '罗辑醒来的时候，旧世界的回声仍在窗外回荡。').join('\n')
            : '这是$title的正文内容。',
        isCached: true,
        fetchedAt: now,
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookshelfRepositoryProvider.overrideWithValue(repository),
          bookByIdProvider('mock-book')
              .overrideWith((ref) => Stream.value(book)),
          bookChaptersProvider('mock-book')
              .overrideWith((ref) => Stream.value(chapters)),
        ],
        child: const MaterialApp(
          home: ReaderPage(bookId: 'mock-book'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders Pencil D7 pure reading state with mock chapter',
      (tester) async {
    await pumpReader(tester);

    expect(find.textContaining('第一章'), findsOneWidget);
    expect(find.textContaining('罗辑醒来的时候'), findsWidgets);
    expect(
        find.byKey(const ValueKey('reader-progress-percent')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-top-controls')), findsNothing);
    expect(find.byKey(const ValueKey('reader-bottom-controls')), findsNothing);

    final articleTopLeft =
        tester.getTopLeft(find.byKey(const ValueKey('reader-article')));
    final progressTopLeft =
        tester.getTopLeft(find.byKey(const ValueKey('reader-progress')));
    expect(articleTopLeft.dx, 30);
    expect(articleTopLeft.dy, 18);
    expect(progressTopLeft.dx, 30);
    expect(progressTopLeft.dy, 797);
  });

  testWidgets('tap shows Pencil D1 warm reader controls', (tester) async {
    await pumpReader(tester);

    await tester.tap(find.byKey(const ValueKey('reader-gesture-layer')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-top-controls')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reader-bottom-controls')), findsOneWidget);
    expect(find.text('目录'), findsOneWidget);
    expect(find.text('排版'), findsOneWidget);
    expect(find.text('主题'), findsOneWidget);
    expect(find.text('朗读'), findsOneWidget);
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
    await tester.tap(find.byKey(const ValueKey('reader-gesture-layer')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('目录'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-catalog-sheet')), findsOneWidget);
    expect(find.textContaining('共 42 章'), findsOneWidget);

    await tester.tapAt(const Offset(195, 120));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-gesture-layer')));
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

    await tester.tap(find.text('朗读'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('reader-listening-panel')), findsOneWidget);
    expect(find.text('朗读'), findsWidgets);

    await tester.tap(find.text('翻页'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('reader-page-turn-panel')), findsOneWidget);
    expect(find.text('翻页方式'), findsOneWidget);
  });

  testWidgets('top more opens Pencil D6 popover', (tester) async {
    await pumpReader(tester);
    await tester.tap(find.byKey(const ValueKey('reader-gesture-layer')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-more-popover')), findsOneWidget);
    expect(find.text('加入书签'), findsOneWidget);
    expect(find.text('内容反馈'), findsOneWidget);
  });

  testWidgets('hidden reader turns pages within the current chapter first',
      (tester) async {
    await pumpReader(tester);

    expect(find.textContaining('第一章 · 1/'), findsOneWidget);

    await tester.tapAt(const Offset(340, 420));
    await tester.pumpAndSettle();

    expect(find.text('第一章'), findsNothing);
    expect(find.textContaining('第一章 · 2/'), findsOneWidget);
    expect(find.textContaining('这是第2章的正文内容'), findsNothing);

    await tester.flingFrom(const Offset(330, 420), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.textContaining('第一章 · 3/'), findsOneWidget);
    expect(find.textContaining('这是第3章的正文内容'), findsNothing);
  });

  testWidgets('scroll page-turn mode enables vertical article scrolling',
      (tester) async {
    await pumpReader(tester);
    await tester.tap(find.byKey(const ValueKey('reader-gesture-layer')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('翻页'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('滚动'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 422));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-scroll-view')), findsOneWidget);
  });
}

class _NoopBookshelfRepository implements BookshelfRepository {
  @override
  Future<void> updateReadingProgress({
    required String bookId,
    required int chapterIndex,
    required int readPosition,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
