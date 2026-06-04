import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/bookshelf/presentation/book_detail_page.dart';
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
        isCached: true,
        fetchedAt: now,
      ),
      Chapter(
        id: 'chapter-2',
        bookId: 'book-1',
        chapterIndex: 1,
        title: '第 2 章 · 射手和农场主',
        content: '  第二章内容  \n\n\n第二章内容' * 50,
        isCached: true,
        fetchedAt: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookByIdProvider('book-1').overrideWith((ref) => Stream.value(book)),
          bookChaptersProvider('book-1')
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
        isCached: true,
        fetchedAt: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookByIdProvider('book-2').overrideWith((ref) => Stream.value(book)),
          bookChaptersProvider('book-2')
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
    expect(find.text('全文'), findsOneWidget);
  });
}
