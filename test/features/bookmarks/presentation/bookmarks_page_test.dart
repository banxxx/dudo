import 'package:dudo/features/bookmarks/application/bookmarks_providers.dart';
import 'package:dudo/features/bookmarks/domain/bookmark_entry.dart';
import 'package:dudo/features/bookmarks/presentation/bookmarks_page.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Pencil G1 empty bookmarks design', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, DudoColors.paperBackground);

    expect(find.text('阅读标记'), findsOneWidget);
    expect(find.text('书签'), findsOneWidget);
    expect(find.byKey(const ValueKey('bookmarks-back-button')), findsOneWidget);
    expect(find.text('暂无书签和高亮'), findsOneWidget);
    expect(find.text('阅读时点击书签或划线，高亮摘录会自动收集在这里。'), findsOneWidget);
    expect(find.text('把喜欢的句子留在这里'), findsOneWidget);
    expect(
      find.text('进入阅读器后，使用底部工具栏添加书签或高亮，之后可以按书籍、章节和时间回看。'),
      findsOneWidget,
    );
    expect(find.text('去阅读'), findsOneWidget);

    final summary = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('暂无书签和高亮'),
            matching: find.byType(Container),
          )
          .last,
    );
    final summaryDecoration = summary.decoration! as BoxDecoration;
    expect(summary.constraints?.maxHeight, 112);
    expect(summary.padding, const EdgeInsets.all(16));
    expect(summaryDecoration.color, DudoColors.primaryContainer);
    expect(summaryDecoration.borderRadius, BorderRadius.circular(24));

    final emptyState = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('把喜欢的句子留在这里'),
            matching: find.byType(Container),
          )
          .last,
    );
    final emptyDecoration = emptyState.decoration! as BoxDecoration;
    expect(emptyState.constraints?.maxHeight, 314);
    expect(emptyState.padding, const EdgeInsets.all(22));
    expect(emptyDecoration.color, DudoColors.surface);
    expect(emptyDecoration.borderRadius, BorderRadius.circular(26));
    expect(emptyDecoration.border?.top.color, DudoColors.outlineVariant);
  });

  testWidgets('lists stored bookmarks, highlights, and notes', (tester) async {
    await tester.pumpWidget(
      _app(
        entries: [
          BookmarkEntry(
            id: 'bookmark-1',
            type: BookmarkEntryType.bookmark,
            bookId: 'book-1',
            bookTitle: '三体',
            chapterIndex: 2,
            chapterTitle: '第3章 黎明',
            offset: 120,
            preview: '向宇宙深处望去。',
            note: null,
            createdAt: DateTime.now(),
          ),
          BookmarkEntry(
            id: 'note-1',
            type: BookmarkEntryType.note,
            bookId: 'book-1',
            bookTitle: '三体',
            chapterIndex: 4,
            chapterTitle: '',
            offset: 0,
            preview: '黑暗森林法则',
            note: '值得回看',
            createdAt: DateTime.now(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('共 2 条标记 · 1 本书'), findsOneWidget);
    expect(find.text('书签 1 · 笔记 1'), findsOneWidget);
    expect(find.text('三体 · 第3章 黎明'), findsOneWidget);
    expect(find.text('三体 · 第 5 章'), findsOneWidget);
    expect(find.text('向宇宙深处望去。'), findsOneWidget);
    expect(find.text('笔记：值得回看'), findsOneWidget);
    expect(find.byKey(const ValueKey('bookmark-delete-bookmark-1')),
        findsOneWidget);
    expect(find.text('暂无书签和高亮'), findsNothing);
    expect(find.text('把喜欢的句子留在这里'), findsNothing);
  });

  testWidgets('filters entries by type with the chip row', (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_app(entries: _entries()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bookmark-filter-all')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bookmark-filter-bookmark')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('bookmark-filter-highlight')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('bookmark-filter-note')), findsOneWidget);
    expect(find.text('向宇宙深处望去。'), findsOneWidget);
    expect(find.text('黑暗森林法则'), findsOneWidget);
    expect(find.text('面壁计划'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bookmark-filter-highlight')));
    await tester.pumpAndSettle();

    expect(find.text('黑暗森林法则'), findsOneWidget);
    expect(find.text('向宇宙深处望去。'), findsNothing);
    expect(find.text('面壁计划'), findsNothing);
    // The summary keeps counting every entry, not just the visible ones.
    expect(find.text('共 3 条标记 · 1 本书'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bookmark-filter-all')));
    await tester.pumpAndSettle();

    expect(find.text('向宇宙深处望去。'), findsOneWidget);
    expect(find.text('面壁计划'), findsOneWidget);
  });

  testWidgets('opens the options sheet to filter by type', (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_app(entries: _entries()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bookmarks-filter-button')));
    await tester.pumpAndSettle();

    expect(find.text('筛选与排序'), findsOneWidget);
    expect(find.text('标记类型'), findsOneWidget);
    expect(find.text('排序方式'), findsOneWidget);
    expect(find.text('3 条'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bookmark-option-note')));
    await tester.pumpAndSettle();

    expect(find.text('筛选与排序'), findsNothing);
    expect(find.text('面壁计划'), findsOneWidget);
    expect(find.text('向宇宙深处望去。'), findsNothing);
    expect(find.text('黑暗森林法则'), findsNothing);
  });

  testWidgets('keeps an empty active filter visible in the chip row',
      (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_app(entries: [_entries().first]));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('bookmark-filter-highlight')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('bookmarks-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bookmark-option-highlight')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('bookmark-filter-highlight')),
      findsOneWidget,
    );
    expect(find.text('没有符合条件的标记'), findsOneWidget);

    await tester.tap(find.text('清除筛选'));
    await tester.pumpAndSettle();

    expect(find.text('向宇宙深处望去。'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bookmark-filter-highlight')),
      findsNothing,
    );
  });

  testWidgets('sorts entries by time from the options sheet', (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_app(entries: _entries()));
    await tester.pumpAndSettle();

    // Newest first by default.
    expect(
      tester.getTopLeft(find.text('面壁计划')).dy,
      lessThan(tester.getTopLeft(find.text('向宇宙深处望去。')).dy),
    );

    await tester.tap(find.byKey(const ValueKey('bookmarks-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('bookmark-option-sort-oldest')),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('向宇宙深处望去。')).dy,
      lessThan(tester.getTopLeft(find.text('面壁计划')).dy),
    );
  });
}

/// Three entries of each type, oldest bookmark first.
List<BookmarkEntry> _entries() => [
      BookmarkEntry(
        id: 'bookmark-1',
        type: BookmarkEntryType.bookmark,
        bookId: 'book-1',
        bookTitle: '三体',
        chapterIndex: 2,
        chapterTitle: '第3章 黎明',
        offset: 120,
        preview: '向宇宙深处望去。',
        note: null,
        createdAt: DateTime(2024, 5, 20, 10),
      ),
      BookmarkEntry(
        id: 'highlight-1',
        type: BookmarkEntryType.highlight,
        bookId: 'book-1',
        bookTitle: '三体',
        chapterIndex: 3,
        chapterTitle: '',
        offset: 40,
        preview: '黑暗森林法则',
        note: null,
        createdAt: DateTime(2024, 5, 21, 10),
      ),
      BookmarkEntry(
        id: 'note-1',
        type: BookmarkEntryType.note,
        bookId: 'book-1',
        bookTitle: '三体',
        chapterIndex: 4,
        chapterTitle: '第5章 黑暗森林',
        offset: 0,
        preview: '面壁计划',
        note: '值得回看',
        createdAt: DateTime(2024, 5, 22, 10),
      ),
    ];

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _app({List<BookmarkEntry> entries = const []}) {
  return ProviderScope(
    overrides: [
      bookmarkEntriesProvider.overrideWith((ref) => Stream.value(entries)),
    ],
    child: const MaterialApp(home: BookmarksPage()),
  );
}
