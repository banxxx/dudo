import 'dart:async';

import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/bookshelf/data/bookshelf_repository.dart';
import 'package:dudo/features/bookshelf/presentation/bookshelf_library_page.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('uses a subtle loading hint before bookshelf data resolves',
      (tester) async {
    final controller = StreamController<List<Book>>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelfBooksProvider.overrideWith((ref) => controller.stream),
        ],
        child: const MaterialApp(
          home: BookshelfLibraryPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('正在整理书架'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('书架还是空的'), findsNothing);
    expect(find.text('可以从这里开始'), findsNothing);
  });

  testWidgets('renders books as cover-forward tiles on shelf rows',
      (tester) async {
    final now = DateTime(2026, 6, 2);
    final books = [
      Book(
        id: 'local-1',
        coverShowText: true,
        title: '云边有个小卖部',
        author: '张嘉佳',
        localPath: '/books/cloud.txt',
        lastChapterIndex: 0,
        lastReadPosition: 0,
        createdAt: now,
        updatedAt: now,
        inShelf: true,
        sortOrder: 0,
      ),
      Book(
        id: 'local-2',
        coverShowText: true,
        title: '可能性的艺术',
        author: '刘瑜',
        localPath: '/books/art.txt',
        lastChapterIndex: 2,
        lastReadPosition: 120,
        createdAt: now,
        updatedAt: now,
        inShelf: true,
        sortOrder: 1,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelfBooksProvider.overrideWith((ref) => Stream.value(books)),
        ],
        child: const MaterialApp(
          home: BookshelfLibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('已导入 2 本'), findsOneWidget);
    expect(find.text('管理'), findsOneWidget);
    // Titles live on the covers, so no caption block sits under the shelf.
    expect(find.text('云边有个小卖部'), findsOneWidget);
    expect(find.text('可能性的艺术'), findsOneWidget);
    expect(find.text('张嘉佳'), findsNothing);
    expect(find.text('刘瑜'), findsNothing);
    expect(find.text('未读'), findsNothing);
    expect(find.text('阅读中'), findsNothing);

    // Each book is a tappable cover-forward tile in a three-column shelf row.
    expect(find.byKey(const ValueKey('shelf-book-local-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('shelf-book-local-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('shelf-plank-0')), findsOneWidget);

    final coverAspect = tester.widget<AspectRatio>(
      find
          .ancestor(
            of: find.text('云边有个小卖部'),
            matching: find.byType(AspectRatio),
          )
          .first,
    );
    expect(coverAspect.aspectRatio, 3 / 4);

    // The tile is exactly the cover: nothing is stacked underneath it.
    final tileSize =
        tester.getSize(find.byKey(const ValueKey('shelf-book-local-1')));
    expect(tileSize.height, closeTo(tileSize.width * 4 / 3, 0.5));

    final coverGradients = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(AspectRatio),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((decoration) => decoration.gradient is LinearGradient);
    expect(coverGradients, isNotEmpty);

    final coverLabel = tester.widget<Text>(find.text('云边有个小卖部'));
    expect(coverLabel.style?.fontFamily, isNotNull);
    expect(coverLabel.style?.fontWeight, FontWeight.w700);

    // A paper bookmark marks started books, and only started books.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('shelf-book-local-2')),
        matching: find.byType(ClipPath),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('shelf-book-local-1')),
        matching: find.byType(ClipPath),
      ),
      findsNothing,
    );
  });

  testWidgets('enters management mode and selects local books', (tester) async {
    final now = DateTime(2026, 6, 2);
    final books = [
      Book(
        id: 'local-1',
        coverShowText: true,
        title: '云边有个小卖部',
        author: '张嘉佳',
        localPath: '/books/cloud.txt',
        lastChapterIndex: 0,
        lastReadPosition: 0,
        createdAt: now,
        updatedAt: now,
        inShelf: true,
        sortOrder: 0,
      ),
      Book(
        id: 'local-2',
        coverShowText: true,
        title: '可能性的艺术',
        author: '刘瑜',
        localPath: '/books/art.txt',
        lastChapterIndex: 2,
        lastReadPosition: 120,
        createdAt: now,
        updatedAt: now,
        inShelf: true,
        sortOrder: 1,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelfBooksProvider.overrideWith((ref) => Stream.value(books)),
        ],
        child: const MaterialApp(
          home: BookshelfLibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('管理'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('管理书架'), findsOneWidget);
    expect(find.text('已选 0 本'), findsOneWidget);
    expect(find.text('全选'), findsOneWidget);
    expect(find.text('请选择书籍'), findsOneWidget);

    final manageBarTopLeft = tester.getTopLeft(
      find
          .ancestor(
            of: find.text('管理书架'),
            matching: find.byType(Container),
          )
          .last,
    );
    expect(manageBarTopLeft.dx, 20);
    expect(manageBarTopLeft.dy, 20);

    final bottomBarFinder = find
        .ancestor(
          of: find.text('请选择书籍'),
          matching: find.byType(Container),
        )
        .last;
    final bottomBarTopLeft = tester.getTopLeft(bottomBarFinder);
    final bottomBarBottomRight = tester.getBottomRight(bottomBarFinder);
    expect(bottomBarTopLeft.dx, 0);
    expect(bottomBarBottomRight.dy, 600);

    await tester.tap(find.byKey(const ValueKey('shelf-book-local-1')));
    await tester.pumpAndSettle();

    expect(find.text('已选 1 本'), findsOneWidget);
    expect(find.text('删除 1 本'), findsOneWidget);

    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();

    expect(find.text('已选 2 本'), findsOneWidget);
    expect(find.text('取消全选'), findsOneWidget);
    expect(find.text('删除 2 本'), findsOneWidget);

    await tester.tap(find.text('取消全选'));
    await tester.pumpAndSettle();

    expect(find.text('已选 0 本'), findsOneWidget);
    expect(find.text('全选'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pump();

    expect(find.text('管理书架'), findsOneWidget);

    await tester.pump(AppMotion.medium);
    await tester.pump();

    expect(find.text('管理书架'), findsNothing);
    expect(find.text('管理'), findsOneWidget);
  });

  testWidgets('delete action does not show a confirmation dialog',
      (tester) async {
    final now = DateTime(2026, 6, 2);
    final books = [
      Book(
        id: 'local-1',
        coverShowText: true,
        title: '云边有个小卖部',
        author: '张嘉佳',
        localPath: '/books/cloud.txt',
        lastChapterIndex: 0,
        lastReadPosition: 0,
        createdAt: now,
        updatedAt: now,
        inShelf: true,
        sortOrder: 0,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelfBooksProvider.overrideWith((ref) => Stream.value(books)),
        ],
        child: const MaterialApp(
          home: BookshelfLibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shelf-book-local-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除 1 本'));
    await tester.pump();

    expect(find.text('删除本地书籍？'), findsNothing);
  });

  testWidgets('stacks books into three-column shelf rows', (tester) async {
    _useTallViewport(tester);
    final now = DateTime(2026, 6, 2);
    final books = [
      for (var index = 0; index < 7; index++)
        Book(
          id: 'local-$index',
          coverShowText: true,
          title: '书架上的第 ${index + 1} 本书',
          author: '作者 $index',
          localPath: '/books/$index.txt',
          lastChapterIndex: 0,
          lastReadPosition: 0,
          createdAt: now,
          updatedAt: now,
          inShelf: true,
          sortOrder: index,
        ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelfBooksProvider.overrideWith((ref) => Stream.value(books)),
        ],
        child: const MaterialApp(
          home: BookshelfLibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Seven books fill three rows: 3 + 3 + 1.
    expect(find.byKey(const ValueKey('shelf-plank-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('shelf-plank-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('shelf-plank-6')), findsOneWidget);
    expect(find.byKey(const ValueKey('shelf-plank-9')), findsNothing);
    expect(find.byKey(const ValueKey('shelf-book-local-6')), findsOneWidget);
  });

  testWidgets('long-press drag reorders the shelf and saves the order',
      (tester) async {
    final now = DateTime(2026, 6, 2);
    final books = [
      for (var index = 0; index < 3; index++)
        Book(
          id: 'local-${index + 1}',
          coverShowText: true,
          title: '书架第 ${index + 1} 本',
          author: '作者 $index',
          localPath: '/books/$index.txt',
          lastChapterIndex: 0,
          lastReadPosition: 0,
          createdAt: now,
          updatedAt: now,
          inShelf: true,
          sortOrder: index,
        ),
    ];
    final repository = _RecordingBookshelfRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelfBooksProvider.overrideWith((ref) => Stream.value(books)),
          bookshelfRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: BookshelfLibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = find.byKey(const ValueKey('shelf-book-local-1'));
    final second = find.byKey(const ValueKey('shelf-book-local-2'));

    final gesture = await tester.startGesture(tester.getCenter(first));
    await tester.pump(const Duration(milliseconds: 650));
    await gesture.moveTo(tester.getCenter(second));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repository.orders, [
      ['local-2', 'local-1', 'local-3'],
    ]);

    final firstX =
        tester.getTopLeft(find.byKey(const ValueKey('shelf-book-local-1'))).dx;
    final secondX =
        tester.getTopLeft(find.byKey(const ValueKey('shelf-book-local-2'))).dx;
    expect(secondX, lessThan(firstX));
  });

  testWidgets('renders the Pencil A2 empty bookshelf design', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelfBooksProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(
          home: BookshelfLibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DudoColors.paperBackground);

    expect(find.text('晚上好，Ban'), findsOneWidget);
    expect(find.text('我的书架'), findsOneWidget);
    expect(find.text('书架还是空的'), findsOneWidget);
    expect(
      find.text('把喜欢的作品加入书架后，阅读进度、收藏和缓存都会在这里安静地整理好。'),
      findsOneWidget,
    );
    expect(find.text('去找书'), findsOneWidget);
    expect(find.text('导入本地'), findsOneWidget);
    expect(find.text('可以从这里开始'), findsOneWidget);
    expect(find.text('稍后再说'), findsOneWidget);
    expect(find.text('去搜索发现书籍'), findsOneWidget);
    expect(find.text('从全站书源中找到想读的作品'), findsOneWidget);
    expect(find.text('导入本地文件'), findsOneWidget);
    expect(find.text('把已有的 txt、epub 放进书架'), findsOneWidget);
    expect(find.text('收藏推荐作品'), findsOneWidget);
    expect(find.text('遇到感兴趣的书，先加入待读清单'), findsOneWidget);

    final greeting = tester.widget<Text>(find.text('晚上好，Ban'));
    expect(greeting.style?.color, DudoColors.textSecondary);
    expect(greeting.style?.fontSize, 13);

    final title = tester.widget<Text>(find.text('我的书架'));
    expect(title.style?.color, DudoColors.textPrimary);
    expect(title.style?.fontSize, 26);

    final emptyCard = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('书架还是空的'),
            matching: find.byType(Container),
          )
          .last,
    );
    final emptyCardDecoration = emptyCard.decoration! as BoxDecoration;
    expect(emptyCard.constraints?.maxHeight, 270);
    expect(emptyCard.padding, const EdgeInsets.all(18));
    expect(emptyCardDecoration.color, DudoColors.primaryContainer);
    expect(emptyCardDecoration.borderRadius, BorderRadius.circular(26));

    final findBooksButton = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('去找书'),
            matching: find.byType(Container),
          )
          .first,
    );
    final findBooksDecoration = findBooksButton.decoration! as BoxDecoration;
    expect(findBooksButton.constraints?.maxHeight, 36);
    expect(findBooksButton.padding, const EdgeInsets.symmetric(horizontal: 16));
    expect(findBooksDecoration.color, DudoColors.textPrimary);
    expect(findBooksDecoration.borderRadius, BorderRadius.circular(18));

    final importLocalLabel = tester.widget<Text>(find.text('导入本地'));
    expect(importLocalLabel.style?.color, DudoColors.primary);

    final skipAction = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('稍后再说'),
        matching: find.byType(TextButton),
      ),
    );
    expect(
        skipAction.style?.foregroundColor?.resolve({}), DudoColors.secondary);
    expect(
        skipAction.style?.textStyle?.resolve({})?.fontWeight, FontWeight.w400);

    final firstTip = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('去搜索发现书籍'),
            matching: find.byType(Container),
          )
          .first,
    );
    final tipDecoration = firstTip.decoration! as BoxDecoration;
    expect(firstTip.constraints?.maxHeight, 62);
    expect(firstTip.padding, const EdgeInsets.all(10));
    expect(tipDecoration.color, DudoColors.surface);
    expect(tipDecoration.borderRadius, BorderRadius.circular(18));
    expect(tipDecoration.border?.top.color, DudoColors.outlineVariant);

    final firstTipDescription = tester.widget<Text>(
      find.text('从全站书源中找到想读的作品'),
    );
    expect(firstTipDescription.style?.color, DudoColors.secondary);
  });

  testWidgets('hides starter tips for the current app session', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shelfBooksProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(
          home: BookshelfLibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('可以从这里开始'), findsOneWidget);
    expect(find.text('去搜索发现书籍'), findsOneWidget);

    await tester.tap(find.text('稍后再说'));
    await tester.pump();

    expect(find.text('可以从这里开始'), findsNothing);
    expect(find.text('去搜索发现书籍'), findsNothing);
    expect(find.text('书架还是空的'), findsOneWidget);
  });
}

class _RecordingBookshelfRepository implements BookshelfRepository {
  final orders = <List<String>>[];

  @override
  Future<void> reorderShelfBooks(List<String> orderedIds) async {
    orders.add(List.of(orderedIds));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
