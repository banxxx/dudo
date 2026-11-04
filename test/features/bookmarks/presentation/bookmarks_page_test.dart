import 'dart:async';

import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookmarks/application/bookmarks_providers.dart';
import 'package:dudo/features/bookmarks/data/bookmarks_repository.dart';
import 'package:dudo/features/bookmarks/domain/bookmark_entry.dart';
import 'package:dudo/features/bookmarks/presentation/bookmarks_page.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:dudo/shared/widgets/dudo_skeleton.dart';
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
    // G1 keeps the filter control visible even with an empty list.
    expect(
        find.byKey(const ValueKey('bookmarks-filter-button')), findsOneWidget);
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

  testWidgets('shows a skeleton instead of the empty state while loading',
      (tester) async {
    final pending = StreamController<List<BookmarkEntry>>();
    addTearDown(pending.close);

    await tester.pumpWidget(_appWithStream(pending.stream));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(DudoSkeleton), findsWidgets);
    expect(find.text('暂无书签和高亮'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('lists stored bookmarks, highlights, and notes', (tester) async {
    final now = DateTime.now();
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
            createdAt: now,
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
            // Keep both entries in "today" so the label assertion does not
            // depend on the wall-clock time the test runs at.
            createdAt: now,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 条标记 · 1 本书'), findsOneWidget);
    expect(find.text('最近摘录来自《三体》，适合继续整理笔记。'), findsOneWidget);
    expect(find.text('三体 · 第3章 黎明'), findsOneWidget);
    expect(find.text('三体 · 第 5 章'), findsOneWidget);
    expect(find.text('向宇宙深处望去。'), findsOneWidget);
    expect(find.text('笔记：值得回看'), findsOneWidget);
    expect(find.textContaining('今天 '), findsNWidgets(2));
    // The card no longer carries a per-entry trash button; deletion moved to
    // the G3 bulk-selection flow.
    expect(
        find.byKey(const ValueKey('bookmark-delete-bookmark-1')), findsNothing);
    expect(find.text('暂无书签和高亮'), findsNothing);
    expect(find.text('把喜欢的句子留在这里'), findsNothing);
  });

  testWidgets('centers the type mark vertically in the entry card',
      (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_app(entries: _entries()));
    await tester.pumpAndSettle();

    final card = tester.getRect(
      find.byKey(const ValueKey('bookmark-entry-note-1')),
    );
    final mark = tester.getRect(
      find.byKey(const ValueKey('bookmark-mark-note-1')),
    );
    expect((mark.center.dy - card.center.dy).abs(), lessThan(1));
  });

  testWidgets('filters entries by type with the chip row', (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_app(entries: _entries()));
    await tester.pumpAndSettle();

    for (final key in [
      'bookmark-filter-all',
      'bookmark-filter-bookmark',
      'bookmark-filter-highlight',
      'bookmark-filter-note',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
    expect(find.text('向宇宙深处望去。'), findsOneWidget);
    expect(find.text('黑暗森林法则'), findsOneWidget);
    expect(find.text('面壁计划'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bookmark-filter-highlight')));
    await tester.pumpAndSettle();

    expect(find.text('黑暗森林法则'), findsOneWidget);
    expect(find.text('向宇宙深处望去。'), findsNothing);
    expect(find.text('面壁计划'), findsNothing);
    // The summary keeps counting every entry, not just the visible ones.
    expect(find.text('3 条标记 · 1 本书'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bookmark-filter-all')));
    await tester.pumpAndSettle();

    expect(find.text('向宇宙深处望去。'), findsOneWidget);
    expect(find.text('面壁计划'), findsOneWidget);
  });

  testWidgets('shows an empty filtered state when a type has no entries',
      (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_app(entries: [_entries().first]));
    await tester.pumpAndSettle();

    // Every chip stays available so an empty type is still discoverable.
    expect(
      find.byKey(const ValueKey('bookmark-filter-highlight')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('bookmark-filter-highlight')));
    await tester.pumpAndSettle();

    expect(find.text('没有符合条件的标记'), findsOneWidget);
    expect(find.text('「高亮」下还没有标记，换个类型看看。'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bookmarks-filtered-empty')),
      findsOneWidget,
    );
    // The G4 empty state fills the space under the chips instead of sitting in
    // a short bordered card.
    expect(
      tester
          .getSize(find.byKey(const ValueKey('bookmarks-filtered-empty')))
          .height,
      greaterThan(300),
    );
    expect(find.text('查看全部标记'), findsNothing);

    // The chips are the way back to the full list.
    await tester.tap(find.byKey(const ValueKey('bookmark-filter-all')));
    await tester.pumpAndSettle();

    expect(find.text('向宇宙深处望去。'), findsOneWidget);
    expect(find.text('没有符合条件的标记'), findsNothing);
  });

  testWidgets('renders entry text without bold weights', (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_app(entries: _entries()));
    await tester.pumpAndSettle();

    final source = tester.widget<Text>(
      find.text('三体 · 第5章 黑暗森林'),
    );
    final quote = tester.widget<Text>(find.text('面壁计划'));
    expect(source.style?.fontWeight ?? FontWeight.normal, FontWeight.normal);
    expect(quote.style?.fontWeight ?? FontWeight.normal, FontWeight.normal);
  });

  testWidgets('sorts entries from the options sheet', (tester) async {
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
    expect(find.text('排序与整理'), findsOneWidget);
    expect(find.text('排序方式'), findsOneWidget);
    expect(find.text('批量管理'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('bookmark-option-sort-oldest')),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('向宇宙深处望去。')).dy,
      lessThan(tester.getTopLeft(find.text('面壁计划')).dy),
    );
  });

  testWidgets('opens bulk selection from the options sheet', (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_app(entries: _entries()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bookmarks-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bookmark-option-manage')));
    await tester.pumpAndSettle();

    expect(find.text('批量选择'), findsOneWidget);
    expect(find.text('已选 0 项'), findsOneWidget);
    expect(find.text('删除 0 项'), findsOneWidget);
    expect(find.text('全选'), findsOneWidget);
  });

  testWidgets('long press starts bulk selection and deletes the selection',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeBookmarksRepository();
    await tester.pumpWidget(
      _app(entries: _entries(), repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('面壁计划'));
    await tester.pumpAndSettle();

    expect(find.text('批量选择'), findsOneWidget);
    expect(find.text('已选 1 项'), findsOneWidget);
    expect(find.text('删除 1 项'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bookmark-select-bookmark-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('bookmarks-select-all')));
    await tester.pumpAndSettle();

    expect(find.text('已选 3 项'), findsOneWidget);
    expect(find.text('取消全选'), findsOneWidget);
    expect(find.text('删除 3 项'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bookmarks-selection-delete')));
    await tester.pumpAndSettle();

    expect(find.text('删除 3 条标记？'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, hasLength(1));
    expect(
      repository.deleteCalls.single,
      {'bookmark-1', 'highlight-1', 'note-1'},
    );
    expect(find.text('批量选择'), findsNothing);
    expect(find.byKey(const ValueKey('bookmarks-bulk-bar')), findsNothing);
  });

  testWidgets('bulk selection fits a compact screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(entries: _entries()));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('面壁计划'));
    await tester.pumpAndSettle();

    expect(find.text('批量选择'), findsOneWidget);
    expect(find.text('已选 1 项'), findsOneWidget);
    expect(find.text('删除 1 项'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exit and cancel leave the selection without deleting',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeBookmarksRepository();
    await tester.pumpWidget(
      _app(entries: _entries(), repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('面壁计划'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bookmarks-selection-exit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bookmarks-bulk-bar')), findsNothing);
    expect(repository.deleteCalls, isEmpty);

    await tester.longPress(find.text('面壁计划'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bookmarks-selection-cancel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bookmarks-bulk-bar')), findsNothing);
    expect(repository.deleteCalls, isEmpty);
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

Widget _app({
  List<BookmarkEntry> entries = const [],
  BookmarksRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      bookmarkEntriesProvider.overrideWith((ref) => Stream.value(entries)),
      if (repository != null)
        bookmarksRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: BookmarksPage()),
  );
}

Widget _appWithStream(Stream<List<BookmarkEntry>> entries) {
  return ProviderScope(
    overrides: [
      bookmarkEntriesProvider.overrideWith((ref) => entries),
    ],
    child: const MaterialApp(home: BookmarksPage()),
  );
}

class _FakeBookmarksRepository implements BookmarksRepository {
  final List<Set<String>> deleteCalls = [];

  @override
  AppDatabase get database => throw UnimplementedError();

  @override
  Stream<List<BookmarkEntry>> watchEntries() => const Stream.empty();

  @override
  Future<void> deleteEntry(BookmarkEntry entry) async {
    await deleteEntries([entry]);
  }

  @override
  Future<void> deleteEntries(Iterable<BookmarkEntry> entries) async {
    deleteCalls.add(entries.map((entry) => entry.id).toSet());
  }
}
