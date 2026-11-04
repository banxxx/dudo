import 'package:dudo/app/router/app_router.dart';
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/reading_history/application/reading_history_provider.dart';
import 'package:dudo/features/reading_history/data/reading_history_repository.dart';
import 'package:dudo/features/reading_history/domain/reading_history_entry.dart';
import 'package:dudo/features/reading_history/presentation/reading_history_page.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('lists recently opened books with their position and time',
      (tester) async {
    final now = DateTime.now();
    final entries = [
      _entry(
        id: 'a',
        title: '云边有个小卖部',
        author: '张嘉佳',
        updatedAt: now,
        percent: 36,
        chapterIndex: 11,
        chapterTitle: '海边的风',
      ),
      _entry(
        id: 'b',
        title: '可能性的艺术',
        author: '刘瑜',
        updatedAt: now.subtract(const Duration(days: 1)),
        percent: 18,
        chapterIndex: 2,
        chapterTitle: '制度的想象力',
      ),
      _entry(
        id: 'c',
        title: '三体全集',
        author: '刘慈欣',
        updatedAt: now.subtract(const Duration(days: 40)),
        percent: 62,
        chapterIndex: 20,
        chapterTitle: '红岸基地',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingHistoryProvider.overrideWith((_) async => entries),
        ],
        child: const MaterialApp(home: ReadingHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('阅读记录'), findsOneWidget);
    expect(find.text('最近点开阅读过的书，会按时间整理在这里'), findsOneWidget);
    expect(find.text('最近'), findsOneWidget);
    expect(find.text('本周'), findsOneWidget);
    expect(find.text('本月'), findsOneWidget);
    expect(find.text('清空'), findsOneWidget);

    expect(find.text('云边有个小卖部'), findsOneWidget);
    expect(find.text('张嘉佳'), findsOneWidget);
    expect(find.text('读到 第 12 章 · 海边的风'), findsOneWidget);
    expect(find.text('已读 36%'), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);

    expect(find.text('可能性的艺术'), findsOneWidget);
    expect(find.text('已读 18%'), findsOneWidget);
    expect(find.text('昨天'), findsOneWidget);

    // Only today's pill is tinted pine; older days stay on the paper fill.
    Color pillColor(String bookId) {
      final pill = tester.widget<Container>(
        find.descendant(
          of: find.byKey(ValueKey('reading-history-time-$bookId')),
          matching: find.byType(Container),
        ),
      );
      return (pill.decoration! as BoxDecoration).color!;
    }

    expect(pillColor('a'), DudoColors.primaryContainer);
    expect(pillColor('b'), DudoColors.surfaceLow);
    expect(pillColor('c'), DudoColors.surfaceLow);

    expect(find.text('三体全集'), findsOneWidget);
    expect(find.text('已读 62%'), findsOneWidget);

    // Newest first, matching the reader's actual last activity.
    expect(
      tester.getTopLeft(find.text('云边有个小卖部')).dy,
      lessThan(tester.getTopLeft(find.text('可能性的艺术')).dy),
    );
    expect(
      tester.getTopLeft(find.text('可能性的艺术')).dy,
      lessThan(tester.getTopLeft(find.text('三体全集')).dy),
    );

    await tester.tap(
      find.byKey(const ValueKey('reading-history-filter-week')),
    );
    await tester.pumpAndSettle();

    expect(find.text('三体全集'), findsNothing);
    expect(find.text('云边有个小卖部'), findsOneWidget);
    expect(find.text('可能性的艺术'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('reading-history-filter-month')),
    );
    await tester.pumpAndSettle();
    expect(find.text('三体全集'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('reading-history-filter-recent')),
    );
    await tester.pumpAndSettle();
    expect(find.text('三体全集'), findsOneWidget);
  });

  testWidgets('继续读 opens the reader at the saved position', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.readingHistory,
      routes: [
        GoRoute(
          path: AppRoutes.readingHistory,
          builder: (_, __) => const ReadingHistoryPage(),
        ),
        GoRoute(
          path: '${AppRoutes.reader}/:bookId',
          builder: (_, state) =>
              Text('reader-${state.pathParameters['bookId']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingHistoryProvider.overrideWith(
            (_) async => [
              _entry(id: 'book-a', title: '云边有个小卖部', updatedAt: DateTime.now()),
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('reading-history-continue-book-a')),
    );
    await tester.pumpAndSettle();

    expect(find.text('reader-book-a'), findsOneWidget);
  });

  testWidgets('clearing asks first and only hides the history',
      (tester) async {
    final repository = _FakeHistoryRepository();
    final messages = _RecordingMessageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingHistoryProvider.overrideWith(
            (_) async => [
              _entry(id: 'book-a', title: '云边有个小卖部', updatedAt: DateTime.now()),
            ],
          ),
          readingHistoryRepositoryProvider.overrideWithValue(repository),
          appMessageServiceProvider.overrideWithValue(messages),
        ],
        child: const MaterialApp(home: ReadingHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();

    expect(find.text('清空阅读记录？'), findsOneWidget);
    expect(find.text('只会清空“最近打开”列表，书籍和阅读进度都会保留。'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('清空'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.clearedAt, isNotNull);
    expect(messages.successes, contains('已清空阅读记录'));
  });

  testWidgets('the empty state explains the selected window', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingHistoryProvider.overrideWith((_) async => const []),
        ],
        child: const MaterialApp(home: ReadingHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('还没有最近打开的书'), findsOneWidget);
    expect(find.text('清空'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('reading-history-filter-week')),
    );
    await tester.pumpAndSettle();

    expect(find.text('本周还没有打开过书'), findsOneWidget);
  });
}

ReadingHistoryEntry _entry({
  required String id,
  required String title,
  required DateTime updatedAt,
  String? author = '作者',
  int percent = 20,
  int chapterIndex = 0,
  String? chapterTitle,
}) {
  return ReadingHistoryEntry(
    book: Book(
      id: id,
      title: title,
      author: author,
      lastChapterIndex: chapterIndex,
      lastReadPosition: 120,
      createdAt: updatedAt,
      updatedAt: updatedAt,
      inShelf: true,
      sortOrder: 0,
      coverShowText: true,
    ),
    chapterCount: 24,
    chapterTitle: chapterTitle,
    percent: percent,
  );
}

class _FakeHistoryRepository implements ReadingHistoryRepository {
  DateTime? clearedAt;

  @override
  Future<void> clear(DateTime now) async {
    clearedAt = now;
  }

  @override
  Future<DateTime?> loadClearedAt() async => clearedAt;
}

class _RecordingMessageService implements AppMessageService {
  final successes = <String>[];

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
  dynamic noSuchMethod(Invocation invocation) => null;
}
