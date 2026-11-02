import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/bookshelf/data/bookshelf_repository.dart';
import 'package:dudo/features/bookshelf/presentation/book_edit_page.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('renders the editable book profile', (tester) async {
    final book = _book();
    await tester.pumpWidget(_wrap(book));
    await tester.pumpAndSettle();

    expect(find.text('编辑书籍资料'), findsOneWidget);
    expect(find.text('野生的人生赢家'), findsOneWidget);
    expect(find.text('二点就且歌且行'), findsWidgets);
    expect(find.text('更换封面'), findsOneWidget);
    expect(find.text('保存修改'), findsOneWidget);
    expect(find.text('在线书源'), findsOneWidget);
  });

  testWidgets('saves title, author and intro changes', (tester) async {
    final book = _book();
    final repository = _FakeBookshelfRepository();
    final messages = _FakeMessageService();
    await tester.pumpWidget(
      _wrap(book, repository: repository, messages: messages),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '新书名');
    await tester.enterText(fields.at(1), '新作者');
    await tester.enterText(fields.at(2), '新的简介');
    await tester.pump();
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();

    expect(repository.savedTitle, '新书名');
    expect(repository.savedAuthor, '新作者');
    expect(repository.savedIntro, '新的简介');
    expect(messages.successes, contains('书籍资料已保存'));
  });

  testWidgets('asks before leaving with unsaved changes', (tester) async {
    final book = _book();
    await tester.pumpWidget(_wrap(book));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '改过的书名');
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    expect(find.text('离开编辑？'), findsOneWidget);
    expect(find.text('直接离开'), findsOneWidget);
    expect(find.text('保存并离开'), findsOneWidget);
    expect(find.text('继续编辑'), findsOneWidget);
  });

  testWidgets('confirms before restoring the generated cover', (tester) async {
    final book = _book(customCoverPath: '/tmp/dudo-cover.png');
    await tester.pumpWidget(_wrap(book));
    await tester.pumpAndSettle();

    expect(find.text('恢复默认'), findsOneWidget);
    await tester.tap(find.text('恢复默认'));
    await tester.pumpAndSettle();

    expect(find.text('恢复默认封面？'), findsOneWidget);
    await tester.tap(find.text('恢复默认').last);
    await tester.pumpAndSettle();

    expect(find.text('使用书源封面或自动生成的封面。'), findsOneWidget);
    expect(find.text('恢复默认'), findsNothing);
  });
}

Widget _wrap(
  Book book, {
  _FakeBookshelfRepository? repository,
  _FakeMessageService? messages,
}) {
  return ProviderScope(
    overrides: [
      bookshelfRepositoryProvider
          .overrideWithValue(repository ?? _FakeBookshelfRepository()),
      appMessageServiceProvider
          .overrideWithValue(messages ?? _FakeMessageService()),
      bookByIdProvider(book.id).overrideWith((ref) => Stream.value(book)),
    ],
    child: MaterialApp(home: BookEditPage(bookId: book.id)),
  );
}

Book _book({String? customCoverPath}) {
  final now = DateTime(2026, 11, 1);
  return Book(
    id: 'book-edit',
    title: '野生的人生赢家',
    author: '二点就且歌且行',
    intro: '一只野生的人生赢家的快乐。',
    lastChapterIndex: 25,
    lastReadPosition: 100,
    createdAt: now,
    updatedAt: now,
    inShelf: true,
    sortOrder: 1,
    customCoverPath: customCoverPath,
  );
}

class _FakeBookshelfRepository implements BookshelfRepository {
  String? savedTitle;
  String? savedAuthor;
  String? savedIntro;

  @override
  Future<void> updateBookProfile({
    required String bookId,
    required String title,
    required String? author,
    required String? intro,
    required String? customCoverPath,
    required String? customWrapPath,
    required int? coverSpineColor,
    required String? coverSpineWidth,
    required String? coverBackStyle,
  }) async {
    savedTitle = title;
    savedAuthor = author;
    savedIntro = intro;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMessageService implements AppMessageService {
  final successes = <String>[];
  final errors = <String>[];
  final infos = <String>[];

  @override
  void success(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.bottom,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {
    successes.add(message);
  }

  @override
  void error(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {
    errors.add(message);
  }

  @override
  void info(
    String message, {
    String? title,
    AppMessagePosition position = AppMessagePosition.top,
    String? dedupeKey,
    AppMessageVisualStyle visualStyle = AppMessageVisualStyle.paper,
    String? actionLabel,
    void Function()? onAction,
  }) {
    infos.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
