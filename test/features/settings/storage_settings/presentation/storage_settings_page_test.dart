import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/offline_cache/application/offline_cache_provider.dart';
import 'package:dudo/features/offline_cache/data/offline_cache_repository.dart';
import 'package:dudo/features/offline_cache/domain/offline_cache.dart';
import 'package:dudo/features/settings/storage_settings/application/storage_usage_provider.dart';
import 'package:dudo/features/settings/storage_settings/data/storage_usage_repository.dart';
import 'package:dudo/features/settings/storage_settings/domain/storage_usage.dart';
import 'package:dudo/features/settings/storage_settings/presentation/storage_settings_page.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The five rows plus the hero and the note do not fit the default surface.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('renders the measured storage breakdown', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeStorageUsageRepository(_usage());
    var offline = _offlineCache();

    await tester.pumpWidget(
      _wrap(
        repository,
        _RecordingMessageService(),
        offline: () => offline,
        offlineRepository: _FakeOfflineCacheRepository(
          onCleared: () => offline = const OfflineCache(books: []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('缓存与存储'), findsOneWidget);
    expect(find.text('本机存储占用'), findsOneWidget);
    expect(find.text('24.7MB'), findsOneWidget);
    expect(find.text('可清理 20.6MB'), findsOneWidget);

    expect(find.text('封面缓存'), findsOneWidget);
    expect(find.text('12.4MB'), findsOneWidget);
    expect(find.text('语音临时文件'), findsOneWidget);
    expect(find.text('8.2MB'), findsOneWidget);
    expect(find.text('离线章节'), findsOneWidget);
    expect(find.text('12KB'), findsOneWidget);
    expect(find.text('数据库记录'), findsOneWidget);
    expect(find.text('76KB'), findsOneWidget);
    expect(find.text('导入字体'), findsOneWidget);
    expect(find.text('4MB'), findsOneWidget);

    // The database row reports the records, not the whole SQLite file.
    expect(find.text('88KB'), findsNothing);
    expect(find.text('阅读数据库'), findsNothing);
    expect(find.textContaining('清理只删除可再生成的缓存与已下载章节'), findsOneWidget);

    // Without an action pill the amount runs out to the row's right padding
    // (12px padding + 1px border) instead of reserving an empty 44px slot.
    final recordsRowRight = tester
        .getTopRight(
          find.byKey(const ValueKey('storage-row-databaseRecords')),
        )
        .dx;
    expect(
      tester.getTopRight(find.text('76KB')).dx,
      closeTo(recordsRowRight - 13, 0.5),
    );

    final coverRowRight =
        tester.getTopRight(find.byKey(const ValueKey('storage-row-coverCache'))).dx;
    expect(
      tester.getTopRight(find.text('12.4MB')).dx,
      closeTo(coverRowRight - 13 - 44 - 8, 0.5),
    );
  });

  testWidgets('clearing the cover cache asks first and refreshes sizes',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeStorageUsageRepository(_usage());
    final messages = _RecordingMessageService();
    var offline = _offlineCache();

    await tester.pumpWidget(
      _wrap(
        repository,
        messages,
        offline: () => offline,
        offlineRepository: _FakeOfflineCacheRepository(
          onCleared: () => offline = const OfflineCache(books: []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('storage-clear-coverCache')),
    );
    await tester.pumpAndSettle();

    expect(find.text('清理封面缓存？'), findsOneWidget);
    expect(find.text('预计释放'), findsOneWidget);
    // Once in the row, once in the dialog's amount box.
    expect(find.text('12.4MB'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('storage-clear-confirm')));
    await tester.pumpAndSettle();

    expect(repository.cleared, [StorageCategory.coverCache]);
    expect(messages.successes, ['已清理封面缓存']);
    expect(find.text('12.4MB'), findsNothing);
    expect(find.text('0B'), findsOneWidget);
    expect(find.text('12.3MB'), findsOneWidget);
    expect(find.text('可清理 8.2MB'), findsOneWidget);

    // With nothing left to clear the pill is gone, so the amount takes the
    // freed space and aligns with the row's right padding.
    final coverRowRight =
        tester.getTopRight(find.byKey(const ValueKey('storage-row-coverCache'))).dx;
    expect(
      tester.getTopRight(find.text('0B')).dx,
      closeTo(coverRowRight - 13, 0.5),
    );
  });

  testWidgets('clearing offline chapters compacts the database',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeStorageUsageRepository(_usage());
    final messages = _RecordingMessageService();
    var offline = _offlineCache();
    final offlineRepository = _FakeOfflineCacheRepository(
      onCleared: () => offline = const OfflineCache(books: []),
    );

    await tester.pumpWidget(
      _wrap(
        repository,
        messages,
        offline: () => offline,
        offlineRepository: offlineRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('storage-clear-offlineChapters')),
    );
    await tester.pumpAndSettle();

    expect(find.text('清理离线章节？'), findsOneWidget);
    expect(find.text('预计释放'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('storage-clear-confirm')));
    await tester.pumpAndSettle();

    expect(offlineRepository.clearAllCalls, 1);
    expect(repository.cleared, isEmpty);
    expect(messages.successes, ['已清理离线章节']);
    expect(find.text('0B'), findsOneWidget);
    // The records the database still holds are reported on their own row.
    expect(find.text('88KB'), findsOneWidget);
    expect(find.text('76KB'), findsNothing);
  });

  testWidgets('records and fonts cannot be cleared from this page',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeStorageUsageRepository(_usage());
    var offline = _offlineCache();

    await tester.pumpWidget(
      _wrap(
        repository,
        _RecordingMessageService(),
        offline: () => offline,
        offlineRepository: _FakeOfflineCacheRepository(
          onCleared: () => offline = const OfflineCache(books: []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('storage-clear-databaseRecords')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('storage-clear-fonts')), findsNothing);
    expect(
      find.byKey(const ValueKey('storage-clear-offlineChapters')),
      findsOneWidget,
    );
  });
}

Widget _wrap(
  StorageUsageRepository repository,
  AppMessageService messages, {
  required OfflineCache Function() offline,
  required OfflineCacheRepository offlineRepository,
}) {
  return ProviderScope(
    overrides: [
      storageUsageRepositoryProvider.overrideWithValue(repository),
      appMessageServiceProvider.overrideWithValue(messages),
      offlineCacheRepositoryProvider.overrideWithValue(offlineRepository),
      offlineCacheProvider.overrideWith((_) async => offline()),
    ],
    child: const MaterialApp(home: StorageSettingsPage()),
  );
}

OfflineCache _offlineCache() {
  return const OfflineCache(
    books: [
      OfflineCacheBook(
        bookId: 'book-1',
        title: '纸上旅居',
        author: '旅人',
        chapterCount: 12,
        bytes: 12288,
      ),
    ],
  );
}

StorageUsage _usage() {
  return const StorageUsage(
    items: [
      StorageUsageItem(
        category: StorageCategory.coverCache,
        title: '封面缓存',
        description: '书籍封面与远程图片',
        bytes: 13002342,
        fileCount: 12,
        clearable: true,
      ),
      StorageUsageItem(
        category: StorageCategory.speechCache,
        title: '语音临时文件',
        description: '朗读试听生成的音频',
        bytes: 8597964,
        fileCount: 3,
        clearable: true,
      ),
      StorageUsageItem(
        category: StorageCategory.database,
        title: '阅读数据库',
        description: '书籍、章节、书签与阅读记录',
        bytes: 90112,
        fileCount: 1,
      ),
      StorageUsageItem(
        category: StorageCategory.fonts,
        title: '导入字体',
        description: '自定义阅读字体',
        bytes: 4194304,
        fileCount: 1,
      ),
    ],
  );
}

class _FakeStorageUsageRepository implements StorageUsageRepository {
  _FakeStorageUsageRepository(this._usage);

  StorageUsage _usage;
  final List<StorageCategory> cleared = [];

  @override
  Future<StorageUsage> measure() async => _usage;

  @override
  Future<int> clearCache(StorageCategory category) async {
    cleared.add(category);
    final item = _usage.itemFor(category);
    if (item == null) return 0;
    _usage = StorageUsage(
      items: [
        for (final entry in _usage.items)
          if (entry.category == category)
            StorageUsageItem(
              category: entry.category,
              title: entry.title,
              description: entry.description,
              bytes: 0,
              clearable: entry.clearable,
            )
          else
            entry,
      ],
    );
    return item.bytes;
  }
}

class _FakeOfflineCacheRepository implements OfflineCacheRepository {
  _FakeOfflineCacheRepository({required this.onCleared});

  final void Function() onCleared;
  int clearAllCalls = 0;

  @override
  AppDatabase get database => throw UnimplementedError();

  @override
  Future<OfflineCache> measure() async => const OfflineCache(books: []);

  @override
  Future<void> clearBook(String bookId) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearAllAndCompact() async {
    clearAllCalls++;
    onCleared();
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
