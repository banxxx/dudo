import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/features/bookmarks/application/bookmarks_providers.dart';
import 'package:dudo/features/bookmarks/domain/bookmark_entry.dart';
import 'package:dudo/features/bookshelf/application/bookshelf_providers.dart';
import 'package:dudo/features/settings/data_sync_settings/application/data_sync_settings_provider.dart';
import 'package:dudo/features/settings/data_sync_settings/data/data_sync_api.dart';
import 'package:dudo/features/settings/data_sync_settings/data/data_sync_settings_repository.dart';
import 'package:dudo/features/settings/data_sync_settings/data/sync_snapshot_repository.dart';
import 'package:dudo/features/settings/data_sync_settings/domain/data_sync_settings.dart';
import 'package:dudo/features/settings/data_sync_settings/domain/sync_snapshot.dart';
import 'package:dudo/features/settings/data_sync_settings/presentation/data_sync_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The page is taller than the default 800x600 test surface.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('renders the disconnected state, the counts and the form',
      (tester) async {
    _useTallViewport(tester);
    final harness = _Harness();

    await tester.pumpWidget(harness.wrap());
    await tester.pumpAndSettle();

    expect(find.text('数据同步'), findsOneWidget);
    expect(find.text('连接你的后端服务器，掌控自己的阅读数据'), findsOneWidget);
    expect(find.text('尚未连接服务器'), findsOneWidget);
    expect(find.text('本地模式'), findsOneWidget);
    expect(find.textContaining('配置 HTTPS 地址与访问令牌后'), findsOneWidget);
    expect(find.text('书架'), findsOneWidget);
    expect(find.text('书签'), findsOneWidget);
    expect(find.text('标注'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(3));

    expect(find.text('后端服务器'), findsOneWidget);
    expect(find.text('支持自建 Dudo Sync API'), findsOneWidget);
    expect(find.text('HTTPS'), findsOneWidget);
    expect(find.byKey(const ValueKey('data-sync-server-url')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('data-sync-access-token')), findsOneWidget);
    expect(find.text('测试连接'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);

    expect(find.text('同步内容'), findsOneWidget);
    expect(find.text('书架与阅读进度'), findsOneWidget);
    expect(find.text('书签与标注'), findsOneWidget);
    expect(find.text('阅读设置'), findsOneWidget);

    expect(find.text('自动同步'), findsOneWidget);
    expect(find.text('保存服务器配置后生效'), findsOneWidget);
    expect(find.text('上次同步：尚未同步'), findsOneWidget);
    expect(find.text('先保存服务器配置'), findsOneWidget);
    expect(find.textContaining('Dudo 不保存副本'), findsOneWidget);
  });

  testWidgets('saving the connection persists it and switches to connected',
      (tester) async {
    _useTallViewport(tester);
    final harness = _Harness();

    await tester.pumpWidget(harness.wrap());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('data-sync-server-url')),
      'https://sync.example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('data-sync-access-token')),
      'token-123',
    );
    await tester.tap(find.byKey(const ValueKey('data-sync-save')));
    await tester.pumpAndSettle();

    final saved = harness.repository.saved.first;
    expect(saved.serverUrl, 'https://sync.example.com');
    expect(saved.accessToken, 'token-123');
    expect(find.text('服务器配置已保存'), findsOneWidget);
    expect(find.text('已连接服务器'), findsOneWidget);
    expect(find.text('云端同步'), findsOneWidget);
    expect(find.textContaining('sync.example.com'), findsWidgets);
  });

  testWidgets('an insecure server address is rejected before saving',
      (tester) async {
    _useTallViewport(tester);
    final harness = _Harness();

    await tester.pumpWidget(harness.wrap());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('data-sync-server-url')),
      'http://sync.example.com',
    );
    await tester.tap(find.byKey(const ValueKey('data-sync-save')));
    await tester.pumpAndSettle();

    expect(harness.repository.saved, isEmpty);
    expect(find.text('同步服务需要使用 HTTPS 地址'), findsOneWidget);
  });

  testWidgets('testing the connection reports success and failure',
      (tester) async {
    _useTallViewport(tester);
    final harness = _Harness();

    await tester.pumpWidget(harness.wrap());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('data-sync-server-url')),
      'https://sync.example.com',
    );
    await tester.tap(find.byKey(const ValueKey('data-sync-test')));
    await tester.pumpAndSettle();

    expect(harness.api.pingCalls, 1);
    expect(harness.api.lastServerUrl, 'https://sync.example.com');
    expect(find.text('连接成功，服务器可用'), findsOneWidget);

    harness.api.pingError = const DataSyncException('访问令牌无效或已过期');
    await tester.tap(find.byKey(const ValueKey('data-sync-test')));
    await tester.pumpAndSettle();

    expect(find.text('连接失败：访问令牌无效或已过期'), findsOneWidget);
  });

  testWidgets('scope switches are saved independently', (tester) async {
    _useTallViewport(tester);
    final harness = _Harness();

    await tester.pumpWidget(harness.wrap());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('data-sync-annotations-switch')),
    );
    await tester.pump();
    expect(harness.repository.saved.last.annotations, isFalse);

    await tester.tap(
      find.byKey(const ValueKey('data-sync-settings-switch')),
    );
    await tester.pump();
    expect(harness.repository.saved.last.settings, isFalse);
    expect(harness.repository.saved.last.progress, isTrue);
  });

  testWidgets('the auto-sync switch updates the description', (tester) async {
    _useTallViewport(tester);
    final harness = _Harness(settings: _connected());

    await tester.pumpWidget(harness.wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('data-sync-auto-switch')));
    await tester.pumpAndSettle();

    expect(harness.repository.saved.last.enabled, isFalse);
    expect(find.text('自动同步已关闭'), findsOneWidget);
  });

  testWidgets('manual sync uploads, applies the response and records the time',
      (tester) async {
    _useTallViewport(tester);
    final response = SyncSnapshot(
      notes: [
        SyncNote(
          id: 'note-remote',
          bookId: 'book-1',
          chapterId: 'chapter-1',
          chapterIndex: 1,
          startOffset: 4,
          endOffset: 12,
          content: '云端段落',
          note: '来自另一台设备',
          color: null,
          createdAt: DateTime(2026, 6, 2),
        ),
      ],
      generatedAt: DateTime(2026, 6, 2),
    );
    final harness = _Harness(
      settings: _connected(),
      api: _FakeApi()..response = response,
    );

    await tester.pumpWidget(harness.wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('data-sync-sync-now')));
    await tester.pumpAndSettle();

    expect(harness.api.syncCalls, 1);
    expect(harness.api.lastServerUrl, 'https://sync.example.com');
    expect(harness.api.lastAccessToken, 'token-123');
    expect(harness.snapshots.includeBooks, isTrue);
    expect(harness.snapshots.includeAnnotations, isTrue);
    expect(harness.snapshots.includeSettings, isTrue);
    expect(harness.snapshots.applied, same(response));
    expect(harness.repository.saved.last.lastSyncedAt, isNotNull);
    expect(find.text('同步完成'), findsOneWidget);
    expect(find.textContaining('上次同步：今天'), findsOneWidget);
  });

  testWidgets('the sync button explains missing scopes instead of uploading',
      (tester) async {
    _useTallViewport(tester);
    final harness = _Harness(
      settings: _connected().copyWith(
        progress: false,
        annotations: false,
        settings: false,
      ),
    );

    await tester.pumpWidget(harness.wrap());
    await tester.pumpAndSettle();

    expect(find.text('请至少选择一项同步内容'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('data-sync-sync-now')));
    await tester.pumpAndSettle();

    expect(harness.api.syncCalls, 0);
  });

  testWidgets('sync saves edited connection fields before uploading',
      (tester) async {
    _useTallViewport(tester);
    final harness = _Harness(settings: _connected());

    await tester.pumpWidget(harness.wrap());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('data-sync-server-url')),
      'https://new.example.com',
    );
    await tester.tap(find.byKey(const ValueKey('data-sync-sync-now')));
    await tester.pumpAndSettle();

    expect(harness.repository.saved.first.serverUrl, 'https://new.example.com');
    expect(harness.api.lastServerUrl, 'https://new.example.com');
    expect(harness.api.syncCalls, 1);
    expect(find.text('同步完成'), findsOneWidget);
  });
}

DataSyncSettings _connected() {
  return DataSyncSettings.defaults().copyWith(
    serverUrl: 'https://sync.example.com',
    accessToken: 'token-123',
    lastSyncedAt: DateTime.now(),
  );
}

class _Harness {
  _Harness({
    DataSyncSettings? settings,
    _FakeApi? api,
    _FakeSnapshots? snapshots,
  })  : repository = _FakeDataSyncSettingsRepository(
          settings ?? DataSyncSettings.defaults(),
        ),
        api = api ?? _FakeApi(),
        snapshots = snapshots ?? _FakeSnapshots();

  final _FakeDataSyncSettingsRepository repository;
  final _FakeApi api;
  final _FakeSnapshots snapshots;

  Widget wrap() {
    return ProviderScope(
      overrides: [
        dataSyncSettingsRepositoryProvider.overrideWithValue(repository),
        dataSyncApiProvider.overrideWithValue(api),
        syncSnapshotRepositoryProvider.overrideWithValue(snapshots),
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
}

List<Book> _books() {
  final now = DateTime(2026, 6, 2);
  return [
    Book(
      id: 'book-1',
      coverShowText: true,
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
      coverShowText: true,
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

class _FakeApi implements DataSyncApi {
  int pingCalls = 0;
  int syncCalls = 0;
  String? lastServerUrl;
  String? lastAccessToken;
  DataSyncException? pingError;
  DataSyncException? syncError;
  SyncSnapshot? response;

  @override
  Future<void> ping({
    required String serverUrl,
    String? accessToken,
  }) async {
    pingCalls++;
    lastServerUrl = serverUrl;
    lastAccessToken = accessToken;
    final error = pingError;
    if (error != null) throw error;
  }

  @override
  Future<SyncSnapshot?> sync({
    required String serverUrl,
    String? accessToken,
    required SyncSnapshot snapshot,
  }) async {
    syncCalls++;
    lastServerUrl = serverUrl;
    lastAccessToken = accessToken;
    final error = syncError;
    if (error != null) throw error;
    return response;
  }
}

class _FakeSnapshots implements SyncSnapshotStore {
  bool? includeBooks;
  bool? includeAnnotations;
  bool? includeSettings;
  SyncSnapshot? applied;

  @override
  Future<SyncSnapshot> build({
    required bool includeBooks,
    required bool includeAnnotations,
    required bool includeSettings,
  }) async {
    this.includeBooks = includeBooks;
    this.includeAnnotations = includeAnnotations;
    this.includeSettings = includeSettings;
    return SyncSnapshot(generatedAt: DateTime.now());
  }

  @override
  Future<void> apply(SyncSnapshot snapshot) async {
    applied = snapshot;
  }
}
