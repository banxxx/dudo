import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookmarks/application/bookmarks_providers.dart';
import 'package:dudo/features/bookmarks/domain/bookmark_entry.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/settings/data_sync_settings/application/data_sync_settings_provider.dart';
import 'package:dudo/features/settings/data_sync_settings/data/data_sync_settings_repository.dart';
import 'package:dudo/features/settings/data_sync_settings/domain/data_sync_settings.dart';
import 'package:dudo/features/settings/data_sync_settings/presentation/data_sync_settings_page.dart';
import 'package:dudo/features/settings/shared/widgets/settings_detail_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The page is taller than the default 800x600 test surface.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('renders the honest cloud state and the sync scope counts',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeDataSyncSettingsRepository(
      DataSyncSettings.defaults(),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('数据同步'), findsOneWidget);
    expect(find.text('云端状态'), findsOneWidget);
    expect(find.text('未连接云端'), findsOneWidget);
    expect(find.textContaining('尚未连接云端账号'), findsOneWidget);
    expect(find.text('同步范围'), findsOneWidget);
    expect(find.text('阅读进度'), findsOneWidget);
    expect(find.text('1 本有阅读进度'), findsOneWidget);
    expect(find.text('书签与笔记'), findsOneWidget);
    expect(find.text('3 条'), findsOneWidget);
    expect(find.text('高亮'), findsOneWidget);
    expect(find.text('1 处'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('主题、字体与朗读偏好'), findsOneWidget);
    expect(find.textContaining('同步范围只决定'), findsOneWidget);
  });

  testWidgets('turning the master switch off persists and dims the scope',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeDataSyncSettingsRepository(
      DataSyncSettings.defaults(),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('data-sync-master-switch')));
    await tester.pump();

    expect(repository.saved.last.enabled, isFalse);
    expect(find.text('同步已关闭，开启后才会在连接云端时同步。'), findsOneWidget);

    final scopeSwitch = tester.widget<SettingsDudoSwitch>(
      find.byKey(const ValueKey('data-sync-progress-switch')),
    );
    expect(scopeSwitch.on, isTrue);
    expect(scopeSwitch.onTap, isNull);
  });

  testWidgets('scope switches are saved independently', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeDataSyncSettingsRepository(
      DataSyncSettings.defaults(),
    );

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('data-sync-highlights-switch')),
    );
    await tester.pump();
    expect(repository.saved.last.highlights, isFalse);

    await tester.tap(
      find.byKey(const ValueKey('data-sync-settings-switch')),
    );
    await tester.pump();
    expect(repository.saved.last.settings, isFalse);
  });
}

Widget _wrap(DataSyncSettingsRepository repository) {
  return ProviderScope(
    overrides: [
      dataSyncSettingsRepositoryProvider.overrideWithValue(repository),
      shelfBooksProvider.overrideWith(
        (ref) => Stream.value(_books()),
      ),
      bookmarkEntriesProvider.overrideWith(
        (ref) => Stream.value(_entries()),
      ),
    ],
    child: const MaterialApp(home: DataSyncSettingsPage()),
  );
}

List<Book> _books() {
  final now = DateTime(2026, 6, 2);
  return [
    Book(
      id: 'book-1',
      title: '云边有个小卖部',
      author: '张嘉佳',
      localPath: '/books/cloud.txt',
      lastChapterIndex: 3,
      lastReadPosition: 120,
      createdAt: now,
      updatedAt: now,
      inShelf: true,
      sortOrder: 0,
    ),
    Book(
      id: 'book-2',
      title: '未开始的书',
      author: '作者',
      localPath: '/books/idle.txt',
      lastChapterIndex: 0,
      lastReadPosition: 0,
      createdAt: now,
      updatedAt: now,
      inShelf: true,
      sortOrder: 1,
    ),
  ];
}

List<BookmarkEntry> _entries() {
  final now = DateTime(2026, 6, 2);
  return [
    BookmarkEntry(
      id: 'bm-1',
      type: BookmarkEntryType.bookmark,
      bookId: 'book-1',
      bookTitle: '云边有个小卖部',
      chapterIndex: 1,
      chapterTitle: '第一章',
      offset: 10,
      preview: '云边',
      note: null,
      createdAt: now,
    ),
    BookmarkEntry(
      id: 'bm-2',
      type: BookmarkEntryType.bookmark,
      bookId: 'book-1',
      bookTitle: '云边有个小卖部',
      chapterIndex: 2,
      chapterTitle: '第二章',
      offset: 20,
      preview: '小镇',
      note: null,
      createdAt: now,
    ),
    BookmarkEntry(
      id: 'note-1',
      type: BookmarkEntryType.note,
      bookId: 'book-1',
      bookTitle: '云边有个小卖部',
      chapterIndex: 1,
      chapterTitle: '第一章',
      offset: 30,
      preview: '',
      note: '这里写得很好',
      createdAt: now,
    ),
    BookmarkEntry(
      id: 'hl-1',
      type: BookmarkEntryType.highlight,
      bookId: 'book-1',
      bookTitle: '云边有个小卖部',
      chapterIndex: 1,
      chapterTitle: '第一章',
      offset: 40,
      preview: '高亮段落',
      note: null,
      createdAt: now,
    ),
  ];
}

class _FakeDataSyncSettingsRepository implements DataSyncSettingsRepository {
  _FakeDataSyncSettingsRepository(this._settings);

  DataSyncSettings _settings;
  final List<DataSyncSettings> saved = [];

  @override
  Future<DataSyncSettings> load() async => _settings;

  @override
  Future<void> save(DataSyncSettings settings) async {
    _settings = settings;
    saved.add(settings);
  }

  @override
  Stream<DataSyncSettings> watch() => Stream.value(_settings);
}
