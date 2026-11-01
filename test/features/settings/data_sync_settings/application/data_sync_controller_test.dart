import 'package:dudo/features/settings/data_sync_settings/application/data_sync_controller.dart';
import 'package:dudo/features/settings/data_sync_settings/data/data_sync_api.dart';
import 'package:dudo/features/settings/data_sync_settings/data/data_sync_settings_repository.dart';
import 'package:dudo/features/settings/data_sync_settings/data/sync_snapshot_repository.dart';
import 'package:dudo/features/settings/data_sync_settings/domain/data_sync_settings.dart';
import 'package:dudo/features/settings/data_sync_settings/domain/sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeSettingsRepository repository;
  late _FakeApi api;
  late _FakeSnapshots snapshots;

  setUp(() {
    repository = _FakeSettingsRepository(DataSyncSettings.defaults());
    api = _FakeApi();
    snapshots = _FakeSnapshots();
  });

  DataSyncController build() {
    final controller = DataSyncController(
      repository: repository,
      api: api,
      snapshots: snapshots,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('loads the saved settings and stays idle when disconnected', () async {
    repository.settings = DataSyncSettings.defaults().copyWith(
      annotations: false,
    );
    final controller = build();

    final state = await controller.stream
        .firstWhere((state) => state.initialized)
        .timeout(const Duration(seconds: 2));

    expect(state.settings.annotations, isFalse);
    expect(state.phase, DataSyncPhase.idle);
    expect(api.syncCalls, 0);
    expect(snapshots.buildCalls, 0);
  });

  test('saving a connection persists it and clears stale sync metadata',
      () async {
    repository.settings = DataSyncSettings.defaults().copyWith(
      enabled: false,
      serverUrl: 'https://old.example.com',
      accessToken: 'old-token',
      lastSyncedAt: DateTime(2026, 6, 1),
    );
    final controller = build();
    await controller.stream
        .firstWhere((state) => state.initialized)
        .timeout(const Duration(seconds: 2));

    await controller.saveConnection(
      serverUrl: ' https://new.example.com ',
      accessToken: ' new-token ',
    );

    expect(repository.saved.first.serverUrl, 'https://new.example.com');
    expect(repository.saved.first.accessToken, 'new-token');
    expect(repository.saved.first.lastSyncedAt, isNull);
    expect(controller.state.testMessage, '服务器配置已保存');
    expect(controller.state.settings.entryLabel, '手动同步');
  });

  test('clearing the address disconnects the server', () async {
    repository.settings = DataSyncSettings.defaults().copyWith(
      enabled: false,
      serverUrl: 'https://sync.example.com',
      accessToken: 'token-123',
      lastSyncedAt: DateTime(2026, 6, 1),
    );
    final controller = build();
    await controller.stream
        .firstWhere((state) => state.initialized)
        .timeout(const Duration(seconds: 2));

    await controller.saveConnection(serverUrl: '  ', accessToken: '');

    expect(repository.saved.first.serverUrl, isNull);
    expect(repository.saved.first.accessToken, isNull);
    expect(controller.state.testMessage, '已断开服务器');
    expect(controller.state.settings.entryLabel, '未连接');
  });

  test('testConnection reports success and maps API errors', () async {
    final controller = build();
    await controller.stream
        .firstWhere((state) => state.initialized)
        .timeout(const Duration(seconds: 2));

    await controller.testConnection(
      serverUrl: 'https://sync.example.com',
      accessToken: 'token-123',
    );
    expect(api.pingCalls, 1);
    expect(api.lastAccessToken, 'token-123');
    expect(controller.state.testOk, isTrue);
    expect(controller.state.testMessage, '连接成功，服务器可用');

    api.pingError = const DataSyncException('访问令牌无效或已过期');
    await controller.testConnection(
      serverUrl: 'https://sync.example.com',
      accessToken: '',
    );
    expect(controller.state.testOk, isFalse);
    expect(controller.state.testMessage, '连接失败：访问令牌无效或已过期');
  });

  test('testConnection validates the URL without calling the server', () async {
    final controller = build();
    await controller.stream
        .firstWhere((state) => state.initialized)
        .timeout(const Duration(seconds: 2));

    await controller.testConnection(
      serverUrl: 'http://sync.example.com',
      accessToken: '',
    );

    expect(api.pingCalls, 0);
    expect(controller.state.testOk, isFalse);
    expect(controller.state.testMessage, '同步服务需要使用 HTTPS 地址');
  });

  test('syncNow refuses to run without a server or a scope', () async {
    final controller = build();
    await controller.stream
        .firstWhere((state) => state.initialized)
        .timeout(const Duration(seconds: 2));

    await controller.syncNow();
    expect(controller.state.syncMessage, '请先保存服务器配置');
    expect(api.syncCalls, 0);

    repository.settings = DataSyncSettings.defaults().copyWith(
      serverUrl: 'https://sync.example.com',
      lastSyncedAt: DateTime.now(),
      progress: false,
      annotations: false,
      settings: false,
    );
    final scoped = build();
    await scoped.stream
        .firstWhere((state) => state.initialized)
        .timeout(const Duration(seconds: 2));

    await scoped.syncNow();
    expect(scoped.state.syncMessage, '请至少选择一项同步内容');
    expect(api.syncCalls, 0);
  });

  test('syncNow uploads the selected scopes, applies and records the time',
      () async {
    repository.settings = DataSyncSettings.defaults().copyWith(
      serverUrl: 'https://sync.example.com',
      accessToken: 'token-123',
      lastSyncedAt: DateTime.now(),
      settings: false,
    );
    final response = SyncSnapshot(
      notes: [
        SyncNote(
          id: 'note-1',
          bookId: 'book-1',
          chapterId: 'book-1:1',
          chapterIndex: 1,
          startOffset: 0,
          endOffset: 4,
          content: '摘录',
          createdAt: DateTime(2026, 6, 2),
        ),
      ],
      generatedAt: DateTime(2026, 6, 2),
    );
    api.response = response;
    final controller = build();
    await controller.stream
        .firstWhere((state) => state.initialized)
        .timeout(const Duration(seconds: 2));

    await controller.syncNow();

    expect(snapshots.includeBooks, isTrue);
    expect(snapshots.includeAnnotations, isTrue);
    expect(snapshots.includeSettings, isFalse);
    expect(api.syncCalls, 1);
    expect(api.lastServerUrl, 'https://sync.example.com');
    expect(api.lastAccessToken, 'token-123');
    expect(snapshots.applied, same(response));
    expect(controller.state.phase, DataSyncPhase.idle);
    expect(controller.state.syncOk, isTrue);
    expect(controller.state.syncMessage, '同步完成');
    expect(controller.state.settings.lastSyncedAt, isNotNull);
    expect(repository.saved.last.lastSyncedAt, isNotNull);
  });

  test('a failed sync keeps the local data and reports the error', () async {
    repository.settings = DataSyncSettings.defaults().copyWith(
      serverUrl: 'https://sync.example.com',
      lastSyncedAt: DateTime.now(),
    );
    api.syncError = const DataSyncException('服务器暂时不可用（HTTP 503）');
    final controller = build();
    await controller.stream
        .firstWhere((state) => state.initialized)
        .timeout(const Duration(seconds: 2));

    await controller.syncNow();

    expect(controller.state.syncOk, isFalse);
    expect(controller.state.syncMessage, '同步失败：服务器暂时不可用（HTTP 503）');
    expect(snapshots.applied, isNull);
    expect(controller.state.settings.lastSyncedAt, isNotNull);
  });

  test('a due automatic sync runs once the settings load', () async {
    repository.settings = DataSyncSettings.defaults().copyWith(
      serverUrl: 'https://sync.example.com',
      lastSyncedAt: DateTime.now().subtract(
        DataSyncController.autoSyncInterval + const Duration(minutes: 1),
      ),
    );
    final controller = build();

    final state = await controller.stream
        .firstWhere((state) => state.syncMessage != null)
        .timeout(const Duration(seconds: 2));

    expect(api.syncCalls, 1);
    expect(state.syncMessage, '已自动同步');
  });

  test('auto sync does not run when it is not due or not configured', () async {
    repository.settings = DataSyncSettings.defaults().copyWith(
      serverUrl: 'https://sync.example.com',
      lastSyncedAt: DateTime.now(),
    );
    final controller = build();
    await controller.stream
        .firstWhere((state) => state.initialized)
        .timeout(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(api.syncCalls, 0);
  });
}

class _FakeSettingsRepository implements DataSyncSettingsRepository {
  _FakeSettingsRepository(this.settings);

  DataSyncSettings settings;
  final List<DataSyncSettings> saved = [];

  @override
  Future<DataSyncSettings> load() async => settings;

  @override
  Future<void> save(DataSyncSettings next) async {
    settings = next;
    saved.add(next);
  }

  @override
  Stream<DataSyncSettings> watch() => Stream.value(settings);
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
  int buildCalls = 0;
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
    buildCalls++;
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
