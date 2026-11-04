import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/offline_cache/application/offline_cache_download_controller.dart';
import 'package:dudo/features/offline_cache/application/offline_cache_download_provider.dart';
import 'package:dudo/features/offline_cache/application/offline_cache_provider.dart';
import 'package:dudo/features/offline_cache/application/offline_cache_settings_provider.dart';
import 'package:dudo/features/offline_cache/data/offline_cache_repository.dart';
import 'package:dudo/features/offline_cache/data/offline_cache_settings_repository.dart';
import 'package:dudo/features/offline_cache/domain/offline_cache.dart';
import 'package:dudo/features/offline_cache/domain/offline_cache_settings.dart';
import 'package:dudo/features/offline_cache/domain/offline_cache_task.dart';
import 'package:dudo/features/offline_cache/presentation/offline_cache_page.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:dudo/shared/theme/app_tokens.dart';
import 'package:dudo/shared/theme/dudo_palette.dart';
import 'package:dudo/shared/widgets/dudo_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The header action is an icon button; scope the lookup to the pinned header
/// so the selection checkboxes elsewhere on the page cannot match it.
Finder _headerAction(IconData icon) => find.descendant(
      of: find.byType(DudoPageHeader),
      matching: find.byIcon(icon),
    );

void main() {
  testWidgets('renders download settings and cached books', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());

    await tester.pumpWidget(_wrap(repository, _RecordingMessageService()));
    await tester.pumpAndSettle();

    expect(find.text('离线缓存'), findsOneWidget);
    expect(find.text('同时下载数量'), findsOneWidget);
    expect(
      find.text('当前允许 3 本书同时下载，网络慢时可调低。'),
      findsOneWidget,
    );
    expect(find.text('建议移动网络下使用 1–2 个任务。'), findsOneWidget);
    expect(find.text('已缓存书籍'), findsOneWidget);
    expect(find.text('2 本 · 3 章 · 11MB'), findsOneWidget);
    expect(find.text('三体'), findsOneWidget);
    expect(find.text('三体 2 · 黑暗森林'), findsOneWidget);
    expect(find.text('2 章 · 6MB'), findsOneWidget);
    expect(find.text('1 章 · 5MB'), findsOneWidget);
    expect(_headerAction(LucideIcons.listChecks), findsOneWidget);
    expect(find.textContaining('清除缓存只删除已下载的章节正文'), findsOneWidget);
  });

  testWidgets('saves the selected download concurrency', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());
    final settingsRepository = _FakeOfflineCacheSettingsRepository();

    await tester.pumpWidget(
      _wrap(
        repository,
        _RecordingMessageService(),
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('offline-concurrency-5')));
    await tester.pumpAndSettle();

    expect(settingsRepository.settings.concurrency, 5);
    expect(
      find.text('当前允许 5 本书同时下载，网络慢时可调低。'),
      findsOneWidget,
    );
  });

  testWidgets('bulk clears the selected book after confirmation',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());
    final messages = _RecordingMessageService();

    await tester.pumpWidget(_wrap(repository, messages));
    await tester.pumpAndSettle();

    await tester.tap(_headerAction(LucideIcons.listChecks));
    await tester.pumpAndSettle();

    expect(find.text('管理离线缓存'), findsOneWidget);
    expect(find.text('已选择 0 项'), findsOneWidget);
    expect(find.text('清除'), findsOneWidget);

    await tester.tap(find.text('三体'));
    await tester.pump();

    expect(find.text('已选择 1 项'), findsOneWidget);
    expect(find.text('预计释放 6MB'), findsOneWidget);
    expect(find.text('清除 1 项'), findsOneWidget);

    await tester.tap(find.text('清除 1 项'));
    await tester.pumpAndSettle();

    expect(find.text('清除「三体」的缓存？'), findsOneWidget);
    expect(find.textContaining('将清除 2 个已下载章节（6MB）'), findsOneWidget);

    await tester.tap(find.text('清除').last);
    await tester.pumpAndSettle();

    expect(repository.clearedBatches, [
      ['book-3body'],
    ]);
    expect(messages.successes, ['已清除「三体」的缓存']);
    expect(find.text('三体'), findsNothing);
    expect(find.text('三体 2 · 黑暗森林'), findsOneWidget);
    expect(_headerAction(LucideIcons.listChecks), findsOneWidget);
  });

  testWidgets('selects all cached books and clears them together',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());
    final messages = _RecordingMessageService();

    await tester.pumpWidget(_wrap(repository, messages));
    await tester.pumpAndSettle();

    await tester.tap(_headerAction(LucideIcons.listChecks));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('offline-select-all')));
    await tester.pump();

    expect(find.text('已选择 2 项'), findsOneWidget);
    expect(find.text('预计释放 11MB'), findsOneWidget);
    expect(find.text('清除 2 项'), findsOneWidget);

    await tester.tap(find.text('清除 2 项'));
    await tester.pumpAndSettle();

    expect(find.text('清除 2 本书的缓存？'), findsOneWidget);
    expect(find.textContaining('将清除 3 个已下载章节（11MB）'), findsOneWidget);

    await tester.tap(find.text('清除').last);
    await tester.pumpAndSettle();

    expect(repository.clearedBatches, [
      ['book-3body', 'book-darkforest'],
    ]);
    expect(messages.successes, ['已清除 2 本书的缓存']);
    expect(find.text('还没有离线章节'), findsOneWidget);
  });

  testWidgets('opens the book detail when a cached book is tapped',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());

    await tester.pumpWidget(_wrapRouter(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('三体 2 · 黑暗森林'));
    await tester.pumpAndSettle();

    expect(find.text('书详情：book-darkforest'), findsOneWidget);
  });

  testWidgets('shows the empty state with cache tips', (tester) async {
    _useTallViewport(tester);
    final repository =
        _FakeOfflineCacheRepository(const OfflineCache(books: []));

    await tester.pumpWidget(_wrap(repository, _RecordingMessageService()));
    await tester.pumpAndSettle();

    expect(find.text('还没有离线章节'), findsOneWidget);
    expect(find.text('去书架阅读'), findsOneWidget);
    expect(find.text('离线缓存会保留什么？'), findsOneWidget);
    expect(find.text('只存正文'), findsOneWidget);
    expect(find.text('随时清除'), findsOneWidget);
    expect(find.text('同时下载数量'), findsOneWidget);
    expect(_headerAction(LucideIcons.listChecks), findsNothing);
    expect(find.text('全部清除'), findsNothing);
  });

  testWidgets('keeps the empty-state call to action visible in dark mode',
      (tester) async {
    final dark = DudoPalette.dark(DudoAccent.pine);
    DudoColors.use(dark);
    addTearDown(() => DudoColors.use(DudoPalette.light(DudoAccent.pine)));
    _useTallViewport(tester);
    final repository =
        _FakeOfflineCacheRepository(const OfflineCache(books: []));

    await tester.pumpWidget(_wrap(repository, _RecordingMessageService()));
    await tester.pumpAndSettle();

    final button = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('去书架阅读'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(button.color, dark.textPrimary);

    final label = tester.widget<Text>(find.text('去书架阅读'));
    expect(label.style?.color, dark.surface);
  });

  testWidgets('shows task cards with chapter progress when available',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());
    final messages = _RecordingMessageService();

    await tester.pumpWidget(
      _wrap(
        repository,
        messages,
        tasks: [
          _task(
            bookId: 'task-active',
            title: '云边有个小卖部',
            author: '张嘉佳',
            status: OfflineCacheTaskStatus.downloading,
            progress: 0.63,
            downloadedChapters: 80,
            totalChapters: 196,
          ),
          _task(
            bookId: 'task-failed',
            title: '三体',
            author: '刘慈欣',
            status: OfflineCacheTaskStatus.failed,
            progress: 0.3,
            downloadedChapters: 28,
            totalChapters: 93,
            message: '连接中断，已保留已下载章节',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('缓存任务'), findsOneWidget);
    expect(find.text('1 个进行中 · 1 个失败'), findsOneWidget);
    expect(find.text('80 / 196 章 · 63%'), findsOneWidget);
    expect(find.text('已下载 28 / 93 章 · 30%'), findsOneWidget);
    expect(find.text('连接中断，已保留已下载章节'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('offline-task-pause-task-active')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('offline-task-retry-task-failed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('offline-task-remove-task-failed')),
      findsOneWidget,
    );
  });

  testWidgets('shows only overall progress when chapter counts are unavailable',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());

    await tester.pumpWidget(
      _wrap(
        repository,
        _RecordingMessageService(),
        tasks: [
          _task(
            bookId: 'task-percent',
            title: '可能性的艺术',
            status: OfflineCacheTaskStatus.downloading,
            progress: 0.63,
          ),
          _task(
            bookId: 'task-preparing',
            title: '献给阿尔吉侬的花束',
            status: OfflineCacheTaskStatus.downloading,
          ),
        ],
      ),
    );
    // The task without a total renders an indeterminate progress bar, so the
    // tree never settles; pump a couple of frames instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final percentCard =
        find.byKey(const ValueKey('offline-task-card-task-percent'));
    expect(
      find.descendant(of: percentCard, matching: find.text('63%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: percentCard, matching: find.textContaining('章')),
      findsNothing,
    );

    final preparingCard =
        find.byKey(const ValueKey('offline-task-card-task-preparing'));
    expect(
      find.descendant(of: preparingCard, matching: find.text('正在获取目录…')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: preparingCard,
        matching: find.byType(LinearProgressIndicator),
      ),
      findsOneWidget,
    );
  });

  testWidgets('lays out task cards and manage mode at phone width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final repository = _FakeOfflineCacheRepository(_cache());

    await tester.pumpWidget(
      _wrap(
        repository,
        _RecordingMessageService(),
        tasks: [
          _task(
            bookId: 'task-long',
            title: '献给阿尔吉侬的花束（纪念版）',
            author: 'Daniel Keyes',
            status: OfflineCacheTaskStatus.downloading,
            progress: 0.63,
            downloadedChapters: 80,
            totalChapters: 196,
          ),
          _task(
            bookId: 'task-failed-long',
            title: '一个很长很长很长的书名用来测试布局是否会被挤坏',
            status: OfflineCacheTaskStatus.failed,
            progress: 0.3,
            downloadedChapters: 28,
            totalChapters: 93,
            message: '连接中断，已保留已下载章节，可以稍后重试',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(_headerAction(LucideIcons.listChecks));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps a queued task visually idle until it starts',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());

    await tester.pumpWidget(
      _wrap(
        repository,
        _RecordingMessageService(),
        tasks: [
          _task(
            bookId: 'task-queued',
            title: '云边有个小卖部',
            status: OfflineCacheTaskStatus.queued,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('offline-task-card-task-queued'));
    expect(
      find.descendant(of: card, matching: find.text('等待中')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('等待开始')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.byType(LinearProgressIndicator),
      ),
      findsNothing,
    );
  });

  testWidgets('pauses an active cache task', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeOfflineCacheRepository(_cache());

    await tester.pumpWidget(
      _wrap(
        repository,
        _RecordingMessageService(),
        tasks: [
          _task(
            bookId: 'task-active',
            title: '云边有个小卖部',
            status: OfflineCacheTaskStatus.downloading,
            progress: 0.63,
            downloadedChapters: 80,
            totalChapters: 196,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('offline-task-pause-task-active')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('offline-task-resume-task-active')),
      findsOneWidget,
    );
    expect(find.text('已暂停'), findsWidgets);
  });
}

Widget _wrap(
  OfflineCacheRepository repository,
  AppMessageService messages, {
  _FakeOfflineCacheSettingsRepository? settingsRepository,
  List<OfflineCacheTask> tasks = const [],
}) {
  final settings = settingsRepository ?? _FakeOfflineCacheSettingsRepository();
  return ProviderScope(
    overrides: [
      offlineCacheRepositoryProvider.overrideWithValue(repository),
      appMessageServiceProvider.overrideWithValue(messages),
      offlineCacheSettingsRepositoryProvider.overrideWithValue(settings),
      if (tasks.isNotEmpty)
        offlineCacheDownloadControllerProvider.overrideWith(
          (ref) => OfflineCacheDownloadController(
            documentSource: () => throw UnimplementedError(),
            concurrency: () => 1,
            onCacheChanged: () {},
            messageService: messages,
            initialTasks: tasks,
          ),
        ),
    ],
    child: const MaterialApp(home: OfflineCachePage()),
  );
}

Widget _wrapRouter(OfflineCacheRepository repository) {
  return ProviderScope(
    overrides: [
      offlineCacheRepositoryProvider.overrideWithValue(repository),
      appMessageServiceProvider.overrideWithValue(_RecordingMessageService()),
      offlineCacheSettingsRepositoryProvider
          .overrideWithValue(_FakeOfflineCacheSettingsRepository()),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/offline-cache',
        routes: [
          GoRoute(
            path: '/offline-cache',
            builder: (_, __) => const OfflineCachePage(),
          ),
          GoRoute(
            path: '/books/:bookId',
            builder: (_, state) => Scaffold(
              body: Text('书详情：${state.pathParameters['bookId']}'),
            ),
          ),
        ],
      ),
    ),
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

OfflineCacheTask _task({
  required String bookId,
  required String title,
  String? author,
  required OfflineCacheTaskStatus status,
  double? progress,
  int? downloadedChapters,
  int? totalChapters,
  String? message,
}) {
  return OfflineCacheTask(
    bookId: bookId,
    title: title,
    author: author,
    status: status,
    progress: progress,
    downloadedChapters: downloadedChapters,
    totalChapters: totalChapters,
    message: message,
    updatedAt: DateTime(2026, 11, 1),
  );
}

class _FakeOfflineCacheRepository implements OfflineCacheRepository {
  _FakeOfflineCacheRepository(this._cache);

  OfflineCache _cache;
  final List<String> clearedBooks = [];
  final List<List<String>> clearedBatches = [];
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

  @override
  Future<void> clearBooksAndCompact(Iterable<String> bookIds) async {
    final ids = bookIds.toList(growable: false);
    clearedBatches.add(ids);
    _cache = OfflineCache(
      books: _cache.books.where((book) => !ids.contains(book.bookId)).toList(),
    );
  }

  @override
  Future<void> clearAllAndCompact() async {
    await clearAll();
  }
}

class _FakeOfflineCacheSettingsRepository
    implements OfflineCacheSettingsRepository {
  OfflineCacheSettings settings = const OfflineCacheSettings();

  @override
  Stream<OfflineCacheSettings> watch() => Stream.value(settings);

  @override
  Future<OfflineCacheSettings> load() async => settings;

  @override
  Future<void> save(OfflineCacheSettings value) async {
    settings = value;
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
