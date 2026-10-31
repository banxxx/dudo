import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/offline_cache/application/offline_cache_provider.dart';
import 'package:dudo/features/offline_cache/data/offline_cache_repository.dart';
import 'package:dudo/features/offline_cache/domain/offline_cache.dart';
import 'package:dudo/features/offline_cache/presentation/offline_cache_page.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('renders the offline cache summary and books', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());

    await tester.pumpWidget(_wrap(repository, _RecordingMessageService()));
    await tester.pumpAndSettle();

    expect(find.text('离线缓存'), findsOneWidget);
    expect(find.text('离线缓存占用'), findsOneWidget);
    expect(find.text('11MB'), findsOneWidget);
    expect(find.text('3 章 · 2 本书'), findsOneWidget);
    expect(find.text('已缓存书籍'), findsOneWidget);
    expect(find.text('三体'), findsOneWidget);
    expect(find.text('三体 2 · 黑暗森林'), findsOneWidget);
    expect(find.text('6MB'), findsOneWidget);
    expect(find.text('5MB'), findsOneWidget);
    expect(find.textContaining('清除只删除下载的章节内容'), findsOneWidget);
  });

  testWidgets('clears one book after confirmation', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());
    final messages = _RecordingMessageService();

    await tester.pumpWidget(_wrap(repository, messages));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('offline-clear-book-3body')));
    await tester.pumpAndSettle();

    expect(find.text('清除「三体」的缓存？'), findsOneWidget);
    expect(find.textContaining('删除 2 个已下载章节'), findsOneWidget);

    await tester.tap(find.text('清除').last);
    await tester.pumpAndSettle();

    expect(repository.clearedBooks, ['book-3body']);
    expect(messages.successes, ['已清除「三体」的缓存']);
    expect(find.text('三体'), findsNothing);
    expect(find.text('6MB'), findsNothing);
    expect(find.text('5MB'), findsNWidgets(2)); // hero total + remaining row
  });

  testWidgets('clears everything after confirmation', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());
    final messages = _RecordingMessageService();

    await tester.pumpWidget(_wrap(repository, messages));
    await tester.pumpAndSettle();

    await tester.tap(find.text('全部清除'));
    await tester.pumpAndSettle();

    expect(find.text('清除全部离线缓存？'), findsOneWidget);
    expect(find.textContaining('删除 3 个已下载章节'), findsOneWidget);

    await tester.tap(find.text('清除').last);
    await tester.pumpAndSettle();

    expect(repository.clearedAll, isTrue);
    expect(messages.successes, ['已清除全部离线缓存']);
    expect(find.text('还没有离线章节'), findsOneWidget);
  });

  testWidgets('shows an empty state when nothing is cached', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(const OfflineCache(books: []));

    await tester.pumpWidget(_wrap(repository, _RecordingMessageService()));
    await tester.pumpAndSettle();

    expect(find.text('还没有离线章节'), findsOneWidget);
    expect(find.text('全部清除'), findsNothing);
  });
}

Widget _wrap(
  OfflineCacheRepository repository,
  AppMessageService messages,
) {
  return ProviderScope(
    overrides: [
      offlineCacheRepositoryProvider.overrideWithValue(repository),
      appMessageServiceProvider.overrideWithValue(messages),
    ],
    child: const MaterialApp(home: OfflineCachePage()),
  );
}

OfflineCache _cache() {
  return const OfflineCache(
    books: [
      OfflineCacheBook(
        bookId: 'book-3body',
        title: '三体',
        author: '刘慈欣',
        chapterCount: 2,
        bytes: 6291456,
      ),
      OfflineCacheBook(
        bookId: 'book-darkforest',
        title: '三体 2 · 黑暗森林',
        author: '刘慈欣',
        chapterCount: 1,
        bytes: 5242880,
      ),
    ],
  );
}

class _FakeOfflineCacheRepository implements OfflineCacheRepository {
  _FakeOfflineCacheRepository(this._cache);

  OfflineCache _cache;
  final List<String> clearedBooks = [];
  bool clearedAll = false;

  @override
  AppDatabase get database => throw UnimplementedError();

  @override
  Future<OfflineCache> measure() async => _cache;

  @override
  Future<void> clearBook(String bookId) async {
    clearedBooks.add(bookId);
    _cache = OfflineCache(
      books: _cache.books.where((book) => book.bookId != bookId).toList(),
    );
  }

  @override
  Future<void> clearAll() async {
    clearedAll = true;
    _cache = const OfflineCache(books: []);
  }
}

class _RecordingMessageService implements AppMessageService {
  final successes = <String>[];
  final errors = <String>[];

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
  dynamic noSuchMethod(Invocation invocation) => null;
}
