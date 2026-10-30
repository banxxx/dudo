import 'package:dudo/features/settings/storage_settings/application/storage_usage_provider.dart';
import 'package:dudo/features/settings/storage_settings/data/storage_usage_repository.dart';
import 'package:dudo/features/settings/storage_settings/domain/storage_usage.dart';
import 'package:dudo/features/settings/storage_settings/presentation/storage_settings_page.dart';
import 'package:dudo/shared/messages/app_message.dart';
import 'package:dudo/shared/messages/app_message_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The four rows plus the note do not fit the default 800x600 test surface.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('renders the measured storage breakdown', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeStorageUsageRepository(_usage());

    await tester.pumpWidget(_wrap(repository, _RecordingMessageService()));
    await tester.pumpAndSettle();

    expect(find.text('缓存与存储'), findsOneWidget);
    expect(find.text('本机存储占用'), findsOneWidget);
    expect(find.text('24.7MB'), findsOneWidget);
    expect(find.text('封面缓存'), findsOneWidget);
    expect(find.text('12.4MB'), findsOneWidget);
    expect(find.text('语音临时文件'), findsOneWidget);
    expect(find.text('8.2MB'), findsOneWidget);
    expect(find.text('阅读数据库'), findsOneWidget);
    expect(find.text('88KB'), findsOneWidget);
    expect(find.text('导入字体'), findsOneWidget);
    expect(find.text('4MB'), findsOneWidget);
    expect(find.textContaining('清理只删除可再生成的缓存'), findsOneWidget);
  });

  testWidgets('clearing the cover cache asks first and refreshes sizes',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeStorageUsageRepository(_usage());
    final messages = _RecordingMessageService();

    await tester.pumpWidget(_wrap(repository, messages));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('storage-clear-coverCache')),
    );
    await tester.pumpAndSettle();

    expect(find.text('清理封面缓存？'), findsOneWidget);
    expect(find.textContaining('可释放 12.4MB'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('storage-clear-confirm')));
    await tester.pumpAndSettle();

    expect(repository.cleared, [StorageCategory.coverCache]);
    expect(messages.successes, ['已清理封面缓存']);
    expect(find.text('12.4MB'), findsNothing);
    expect(find.text('0B'), findsOneWidget);
    expect(find.text('12.3MB'), findsOneWidget);
  });

  testWidgets('the database cannot be cleared from this page', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeStorageUsageRepository(_usage());

    await tester.pumpWidget(_wrap(repository, _RecordingMessageService()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('storage-clear-database')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('storage-clear-fonts')), findsNothing);
  });
}

Widget _wrap(
  StorageUsageRepository repository,
  AppMessageService messages,
) {
  return ProviderScope(
    overrides: [
      storageUsageRepositoryProvider.overrideWithValue(repository),
      appMessageServiceProvider.overrideWithValue(messages),
    ],
    child: const MaterialApp(home: StorageSettingsPage()),
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
