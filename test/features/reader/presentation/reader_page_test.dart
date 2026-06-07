import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/bookshelf/data/bookshelf_repository.dart';
import 'package:dudo/features/reader/presentation/reader_page.dart';
import 'package:dudo/features/reader/presentation/layout/reader_page_metrics.dart';
import 'package:dudo/features/reader/presentation/modes/scroll/reader_scroll_mode_view.dart';
import 'package:dudo/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<_RecordingBookshelfRepository> pumpReader(
    WidgetTester tester, {
    String? firstChapterContent,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final repository = _RecordingBookshelfRepository();
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
    final chaptersByIndex = <int, Chapter>{};
    final chapterMetas = List.generate(42, (index) {
      final title = index == 0 ? '第一章' : '第${index + 1}章';
      final chapter = Chapter(
        id: 'chapter-$index',
        bookId: 'mock-book',
        chapterIndex: index,
        title: title,
        content: index == 0
            ? firstChapterContent ??
                List.filled(200, '罗辑醒来的时候，旧世界的回声仍在窗外回荡。').join('\n')
            : '这是$title的正文内容。',
        normalizedContentLength: index == 0 ? 4598 : 10 + title.length,
        isCached: true,
        fetchedAt: now,
      );
      chaptersByIndex[index] = chapter;
      return Chapter(
        id: chapter.id,
        bookId: chapter.bookId,
        chapterIndex: chapter.chapterIndex,
        title: chapter.title,
        content: null,
        normalizedContentLength: chapter.normalizedContentLength,
        isCached: chapter.isCached,
        fetchedAt: chapter.fetchedAt,
      );
    });
    repository.chapterMetas = chapterMetas;
    repository.chaptersByIndex = chaptersByIndex;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookshelfRepositoryProvider.overrideWithValue(repository),
          bookByIdProvider('mock-book')
              .overrideWith((ref) => Stream.value(book)),
          bookChapterCountProvider('mock-book')
              .overrideWith((ref) => Stream.value(chapterMetas.length)),
          currentBookChapterMetaProvider.overrideWith(
            (ref, key) => Stream.value(chapterMetas[key.chapterIndex]),
          ),
          currentBookChapterContentProvider.overrideWith(
            (ref, key) => Stream.value(chaptersByIndex[key.chapterIndex]),
          ),
        ],
        child: const MaterialApp(
          home: ReaderPage(bookId: 'mock-book'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('renders Pencil D7 pure reading state with mock chapter',
      (tester) async {
    await pumpReader(tester);

    expect(find.textContaining('第一章'), findsOneWidget);
    expect(find.textContaining('罗辑醒来的时候'), findsWidgets);
    expect(find.textContaining('这是第2章的正文内容'), findsNothing);
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

    await tester.tapAt(const Offset(195, 422));
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
    final repository = await pumpReader(tester);
    await tester.tap(find.byKey(const ValueKey('reader-gesture-layer')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('目录'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-catalog-sheet')), findsOneWidget);
    expect(find.textContaining('共 42 章'), findsOneWidget);
    expect(repository.catalogPageRequests, hasLength(1));
    expect(repository.catalogPageRequests.single.offset, 0);
    expect(repository.catalogPageRequests.single.limit, 30);
    expect(find.text('第一章'), findsWidgets);
    expect(find.text('第31章'), findsNothing);

    for (var i = 0; i < 8; i++) {
      await tester.drag(
        find.byKey(const ValueKey('reader-catalog-list')),
        const Offset(0, -300),
      );
      await tester.pump();
      if (repository.catalogPageRequests.length == 2) break;
    }
    await tester.pumpAndSettle();
    expect(repository.catalogPageRequests, hasLength(2));
    expect(repository.catalogPageRequests.last.offset, 30);

    await tester.tapAt(const Offset(195, 422));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-top-controls')), findsNothing);
    expect(find.byKey(const ValueKey('reader-bottom-controls')), findsNothing);

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
    expect(find.text('仿真'), findsOneWidget);
    expect(find.text('覆盖'), findsOneWidget);
    expect(find.text('滑动'), findsOneWidget);
    expect(find.text('滚动'), findsOneWidget);
    expect(find.text('无动画'), findsOneWidget);
    expect(find.text('音量翻页'), findsOneWidget);
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
    final repository = await pumpReader(tester);

    expect(find.textContaining('第一章 · 1/'), findsOneWidget);

    await tester.tapAt(const Offset(340, 420));
    await tester.pumpAndSettle();

    expect(find.text('第一章'), findsNothing);
    expect(find.textContaining('第一章 · 2/'), findsOneWidget);
    expect(find.textContaining('这是第2章的正文内容'), findsNothing);
    expect(repository.recentlyReadUpdates, isNotEmpty);
    expect(repository.recentlyReadUpdates.last.chapterIndex, 0);
    expect(repository.recentlyReadUpdates.last.readPosition, greaterThan(0));
    expect(repository.progressUpdates, isEmpty);

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

  testWidgets('scroll mode builds visible paragraphs lazily', (tester) async {
    final content = List.generate(
      200,
      (index) => '段落 $index：这是用于验证滚动虚拟化的唯一正文。',
    ).join('\n\n');
    await pumpReader(tester, firstChapterContent: content);
    await tester.tap(find.byKey(const ValueKey('reader-gesture-layer')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('翻页'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('滚动'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 422));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-scroll-view')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-paragraph-0')), findsOneWidget);
    expect(find.textContaining('段落 0'), findsOneWidget);
    expect(find.textContaining('段落 199'), findsNothing);
  });

  testWidgets('flushes pending scroll progress on dispose', (tester) async {
    final repository = await pumpReader(tester);
    await tester.tap(find.byKey(const ValueKey('reader-gesture-layer')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('翻页'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('滚动'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 422));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('reader-scroll-view')),
      const Offset(0, -260),
    );
    await tester.pump();
    expect(repository.progressUpdates, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(repository.progressUpdates, isNotEmpty);
    expect(repository.progressUpdates.last.chapterIndex, 0);
    expect(repository.progressUpdates.last.readPosition, greaterThan(0));
    expect(repository.recentlyReadUpdates, isEmpty);
  });

  testWidgets('scroll mode jumps adjacent chapter with target header at top',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final repository = _RecordingBookshelfRepository();
    final now = DateTime(2026, 6, 3);
    final chaptersByIndex = <int, Chapter>{};
    final chapterMetas = List.generate(3, (index) {
      final chapter = Chapter(
        id: 'near-chapter-$index',
        bookId: 'near-book',
        chapterIndex: index,
        title: 'Near Chapter $index',
        content: 'Near Chapter $index\n\nBody for near chapter $index.',
        normalizedContentLength: 44,
        isCached: true,
        fetchedAt: now,
      );
      chaptersByIndex[index] = chapter;
      return Chapter(
        id: chapter.id,
        bookId: chapter.bookId,
        chapterIndex: chapter.chapterIndex,
        title: chapter.title,
        content: null,
        normalizedContentLength: chapter.normalizedContentLength,
        isCached: chapter.isCached,
        fetchedAt: chapter.fetchedAt,
      );
    });
    repository
      ..chapterMetas = chapterMetas
      ..chaptersByIndex = chaptersByIndex;

    Widget buildHarness(ReaderScrollJumpRequest? jumpRequest) {
      final metrics = ReaderPageMetrics.fromSize(const Size(390, 844));
      final initial = chaptersByIndex[0]!;
      return MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: Stack(
            children: [
              ReaderScrollModeView(
                bookId: 'near-book',
                chapterCount: chapterMetas.length,
                initialChapterIndex: 0,
                initialReadPosition: 0,
                initialChapterTitle: initial.title,
                initialChapterText: initial.content!,
                initialChapterRawContent: initial.content!,
                repository: repository,
                metrics: metrics,
                palette: ReaderTheme.parchment,
                fontSize: 19,
                lineHeight: 1.72,
                top: 0,
                height: 760,
                interactive: true,
                preview: false,
                jumpRequest: jumpRequest,
                onProgressChanged: (_) {},
                onTap: () {},
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(buildHarness(null));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-scroll-chapter-1')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      buildHarness(
        const ReaderScrollJumpRequest(
          requestId: 1,
          chapterIndex: 1,
          readPosition: 0,
        ),
      ),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('reader-scroll-chapter-1')))
          .dy,
      0,
    );
    expect(
      find.byKey(const ValueKey('reader-scroll-chapter-0')),
      findsNothing,
    );

    await tester.pumpAndSettle();

    final headerTop = tester
        .getTopLeft(find.byKey(const ValueKey('reader-scroll-chapter-1')))
        .dy;
    expect(headerTop, 0);
  });
}

class _ProgressUpdate {
  const _ProgressUpdate({
    required this.bookId,
    required this.chapterIndex,
    required this.readPosition,
  });

  final String bookId;
  final int chapterIndex;
  final int readPosition;
}

class _CatalogPageRequest {
  const _CatalogPageRequest({
    required this.bookId,
    required this.offset,
    required this.limit,
  });

  final String bookId;
  final int offset;
  final int limit;
}

class _RecordingBookshelfRepository implements BookshelfRepository {
  List<Chapter> chapterMetas = const [];
  Map<int, Chapter> chaptersByIndex = const {};
  final catalogPageRequests = <_CatalogPageRequest>[];
  final progressUpdates = <_ProgressUpdate>[];
  final recentlyReadUpdates = <_ProgressUpdate>[];

  @override
  Future<List<Chapter>> fetchChapterMetasPage({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    catalogPageRequests.add(
      _CatalogPageRequest(bookId: bookId, offset: offset, limit: limit),
    );
    return chapterMetas.skip(offset).take(limit).toList();
  }

  @override
  Future<Chapter?> fetchChapterMetaForBookAtIndex({
    required String bookId,
    required int chapterIndex,
  }) async {
    if (chapterIndex < 0 || chapterIndex >= chapterMetas.length) return null;
    return chapterMetas[chapterIndex];
  }

  @override
  Future<Chapter?> fetchChapterContentForBookAtIndex({
    required String bookId,
    required int chapterIndex,
  }) async {
    return chaptersByIndex[chapterIndex];
  }

  @override
  Future<void> updateReadingProgress({
    required String bookId,
    required int chapterIndex,
    required int readPosition,
  }) async {
    progressUpdates.add(
      _ProgressUpdate(
        bookId: bookId,
        chapterIndex: chapterIndex,
        readPosition: readPosition,
      ),
    );
  }

  @override
  Future<void> markBookRecentlyRead({
    required String bookId,
    required int chapterIndex,
    required int readPosition,
  }) async {
    recentlyReadUpdates.add(
      _ProgressUpdate(
        bookId: bookId,
        chapterIndex: chapterIndex,
        readPosition: readPosition,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
