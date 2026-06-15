import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/bookshelf/data/bookshelf_repository.dart';
import 'package:dudo/features/bookshelf/presentation/book_detail_page.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders book detail progress state and more menu',
      (tester) async {
    final now = DateTime(2026, 6, 3);
    final book = Book(
      id: 'book-1',
      title: '三体',
      author: '刘慈欣',
      intro: '文化大革命如火如荼进行的同时，红岸工程取得突破。',
      localPath: '/books/three-body.txt',
      lastChapterIndex: 1,
      lastReadPosition: 120,
      createdAt: now,
      updatedAt: now,
      inShelf: true,
      sortOrder: 1,
    );
    final chapters = [
      Chapter(
        id: 'chapter-1',
        bookId: 'book-1',
        chapterIndex: 0,
        title: '第 1 章 · 科学边界',
        content: '第一章内容',
        normalizedContentLength: 5,
        isCached: true,
        fetchedAt: now,
      ),
      Chapter(
        id: 'chapter-2',
        bookId: 'book-1',
        chapterIndex: 1,
        title: '第 2 章 · 射手和农场主',
        content: '  第二章内容  \n\n\n第二章内容' * 50,
        normalizedContentLength: 699,
        isCached: true,
        fetchedAt: now,
      ),
    ];
    final repository = _FakeBookshelfRepository(chapters);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookshelfRepositoryProvider.overrideWithValue(repository),
          bookByIdProvider('book-1').overrideWith((ref) => Stream.value(book)),
          bookChapterCountProvider('book-1')
              .overrideWith((ref) => Stream.value(chapters.length)),
          currentBookChapterMetaProvider(
            const CurrentBookChapterKey(bookId: 'book-1', chapterIndex: 1),
          ).overrideWith((ref) => Stream.value(chapters[1])),
          initialBookChapterMetasProvider('book-1')
              .overrideWith((ref) => Stream.value(chapters)),
          bookChapterMetasProvider('book-1')
              .overrideWith((ref) => Stream.value(chapters)),
        ],
        child: const MaterialApp(
          home: BookDetailPage(bookId: 'book-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('三体'), findsWidgets);
    expect(find.text('刘慈欣 · 本地文件'), findsOneWidget);
    expect(find.text('继续阅读'), findsOneWidget);
    expect(find.text('已在书架'), findsOneWidget);
    expect(find.text('上次阅读'), findsOneWidget);
    expect(find.text('已读到 第 2 章 · 射手和农场主'), findsOneWidget);
    expect(find.text('17%'), findsOneWidget);
    expect(find.text('59%'), findsOneWidget);
    expect(find.text('简介'), findsOneWidget);
    expect(find.textContaining('红岸工程'), findsOneWidget);
  });
  testWidgets('renders not-started state without progress card',
      (tester) async {
    final now = DateTime(2026, 6, 3);
    final book = Book(
      id: 'book-2',
      title: '本地书',
      author: '作者',
      intro: '一本尚未开始阅读的书。',
      localPath: '/books/local.txt',
      lastChapterIndex: 0,
      lastReadPosition: 0,
      createdAt: now,
      updatedAt: now,
      inShelf: true,
      sortOrder: 1,
    );
    final chapters = [
      Chapter(
        id: 'chapter-full',
        bookId: 'book-2',
        chapterIndex: 0,
        title: '全文',
        content: '全文内容',
        normalizedContentLength: 4,
        isCached: true,
        fetchedAt: now,
      ),
    ];
    final repository = _FakeBookshelfRepository(chapters);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookshelfRepositoryProvider.overrideWithValue(repository),
          bookByIdProvider('book-2').overrideWith((ref) => Stream.value(book)),
          bookChapterCountProvider('book-2')
              .overrideWith((ref) => Stream.value(chapters.length)),
          currentBookChapterMetaProvider(
            const CurrentBookChapterKey(bookId: 'book-2', chapterIndex: 0),
          ).overrideWith((ref) => Stream.value(chapters[0])),
          initialBookChapterMetasProvider('book-2')
              .overrideWith((ref) => Stream.value(chapters)),
          bookChapterMetasProvider('book-2')
              .overrideWith((ref) => Stream.value(chapters)),
        ],
        child: const MaterialApp(
          home: BookDetailPage(bookId: 'book-2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('开始阅读'), findsOneWidget);
    expect(find.text('已在书架'), findsOneWidget);
    expect(find.text('还未开始阅读'), findsOneWidget);
    expect(find.text('上次阅读'), findsNothing);
    expect(find.text('已读到 全文'), findsNothing);
    await tester.scrollUntilVisible(find.text('全文'), 300);
    expect(find.text('全文'), findsOneWidget);
  });

  testWidgets('shows add shelf action and collapses long intro',
      (tester) async {
    final now = DateTime(2026, 6, 3);
    final longIntro = List.filled(
      12,
      '这是一段很长的作品简介，用来描述人物关系、世界设定、剧情走向和阅读提示。',
    ).join();
    final book = Book(
      id: 'remote-book',
      title: '远程书',
      author: '作者',
      intro: longIntro,
      sourceId: 'source',
      sourceBookUrl: 'https://source.example/book/1',
      lastChapterIndex: 0,
      lastReadPosition: 0,
      createdAt: now,
      updatedAt: now,
      inShelf: false,
      sortOrder: 0,
    );
    final chapters = [
      const Chapter(
        id: 'remote-book:0',
        bookId: 'remote-book',
        chapterIndex: 0,
        title: '第一章',
        normalizedContentLength: 0,
        isCached: false,
      ),
    ];
    final repository = _FakeBookshelfRepository(chapters);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookshelfRepositoryProvider.overrideWithValue(repository),
          appMessageServiceProvider.overrideWithValue(_FakeAppMessageService()),
          bookByIdProvider('remote-book')
              .overrideWith((ref) => Stream.value(book)),
          bookChapterCountProvider('remote-book')
              .overrideWith((ref) => Stream.value(chapters.length)),
          currentBookChapterMetaProvider(
            const CurrentBookChapterKey(
              bookId: 'remote-book',
              chapterIndex: 0,
            ),
          ).overrideWith((ref) => Stream.value(chapters[0])),
          initialBookChapterMetasProvider('remote-book')
              .overrideWith((ref) => Stream.value(chapters)),
          bookChapterMetasProvider('remote-book')
              .overrideWith((ref) => Stream.value(chapters)),
        ],
        child: const MaterialApp(
          home: BookDetailPage(bookId: 'remote-book'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('书架'), findsOneWidget);
    expect(find.text('已在书架'), findsNothing);

    await tester.tap(find.text('书架'));
    await tester.pump();

    expect(repository.addedBookIds, ['remote-book']);

    final introText = tester.widget<Text>(find.text(longIntro));
    expect(introText.maxLines, 5);
    expect(find.text('展开'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('展开'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.text('展开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('展开'));
    await tester.pump();

    final expandedIntroText = tester.widget<Text>(find.text(longIntro));
    expect(expandedIntroText.maxLines, isNull);
    expect(find.text('收起'), findsOneWidget);
  });
}

class _FakeBookshelfRepository implements BookshelfRepository {
  _FakeBookshelfRepository(this.chapters);

  final List<Chapter> chapters;
  final List<String> addedBookIds = [];

  @override
  Future<List<Chapter>> fetchChapterMetasPage({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    return chapters.skip(offset).take(limit).toList();
  }

  @override
  Future<void> backfillNormalizedContentLengths(String bookId) async {}

  @override
  Future<void> addBookToShelf(String bookId) async {
    addedBookIds.add(bookId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAppMessageService implements AppMessageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
