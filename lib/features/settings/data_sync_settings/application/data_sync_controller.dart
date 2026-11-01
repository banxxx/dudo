import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data_sync_api.dart';
import '../data/data_sync_settings_repository.dart';
import '../data/sync_snapshot_repository.dart';
import '../domain/data_sync_settings.dart';

enum DataSyncPhase { idle, testing, syncing }

class DataSyncState {
  const DataSyncState({
    required this.settings,
    this.initialized = false,
    this.phase = DataSyncPhase.idle,
    this.testOk,
    this.testMessage,
    this.syncOk,
    this.syncMessage,
  });

  final DataSyncSettings settings;
  final bool initialized;
  final DataSyncPhase phase;

  /// `null` means no connection test has run yet.
  final bool? testOk;
  final String? testMessage;

  /// `null` means no sync has run yet.
  final bool? syncOk;
  final String? syncMessage;

  DataSyncState copyWith({
    DataSyncSettings? settings,
    bool? initialized,
    DataSyncPhase? phase,
    bool? testOk,
    bool clearTestOk = false,
    String? testMessage,
    bool clearTestMessage = false,
    bool? syncOk,
    bool clearSyncOk = false,
    String? syncMessage,
    bool clearSyncMessage = false,
  }) {
    return DataSyncState(
      settings: settings ?? this.settings,
      initialized: initialized ?? this.initialized,
      phase: phase ?? this.phase,
      testOk: clearTestOk ? null : (testOk ?? this.testOk),
      testMessage: clearTestMessage ? null : (testMessage ?? this.testMessage),
      syncOk: clearSyncOk ? null : (syncOk ?? this.syncOk),
      syncMessage: clearSyncMessage ? null : (syncMessage ?? this.syncMessage),
    );
  }
}

/// Owns the sync settings, connection test, manual sync and the foreground
/// auto-sync timer. It is kept alive by `DudoApp` so auto-sync survives page
/// navigation; the timer only runs while the app process is alive.
class DataSyncController extends StateNotifier<DataSyncState> {
  DataSyncController({
    required DataSyncSettingsRepository repository,
    required DataSyncApi api,
    required SyncSnapshotStore snapshots,
  })  : _repository = repository,
        _api = api,
        _snapshots = snapshots,
        super(DataSyncState(settings: DataSyncSettings.defaults())) {
    unawaited(_load());
  }

  static const Duration autoSyncInterval = Duration(minutes: 30);

  final DataSyncSettingsRepository _repository;
  final DataSyncApi _api;
  final SyncSnapshotStore _snapshots;

  Timer? _timer;
  bool _syncing = false;
  bool _disposed = false;

  Future<void> _load() async {
    DataSyncSettings settings;
    try {
      settings = await _repository.load();
    } catch (_) {
      settings = DataSyncSettings.defaults();
    }
    if (_disposed) return;
    state = state.copyWith(settings: settings, initialized: true);
    _scheduleAutoSync();
  }

  Future<void> saveConnection({
    required String serverUrl,
    required String accessToken,
    bool reschedule = true,
  }) async {
    final url = serverUrl.trim();
    final token = accessToken.trim();
    final urlChanged = (state.settings.serverUrl ?? '') != url;
    final next = state.settings.copyWith(
      serverUrl: url.isEmpty ? null : url,
      clearServerUrl: url.isEmpty,
      accessToken: token.isEmpty ? null : token,
      clearAccessToken: token.isEmpty,
      lastSyncedAt: urlChanged ? null : state.settings.lastSyncedAt,
      clearLastSyncedAt: urlChanged,
    );
    await _persist(next, reschedule: reschedule);
    if (_disposed) return;
    state = state.copyWith(
      clearTestOk: true,
      testMessage: url.isEmpty ? '已断开服务器' : '服务器配置已保存',
      clearSyncOk: true,
      clearSyncMessage: true,
    );
  }

  Future<void> setEnabled(bool value) {
    return _persist(state.settings.copyWith(enabled: value));
  }

  Future<void> setProgress(bool value) {
    return _persist(state.settings.copyWith(progress: value));
  }

  Future<void> setAnnotations(bool value) {
    return _persist(state.settings.copyWith(annotations: value));
  }

  Future<void> setSettingsScope(bool value) {
    return _persist(state.settings.copyWith(settings: value));
  }

  Future<void> testConnection({
    required String serverUrl,
    required String accessToken,
  }) async {
    final error = dataSyncUrlError(serverUrl);
    if (error != null) {
      if (_disposed) return;
      state = state.copyWith(testOk: false, testMessage: error);
      return;
    }
    if (state.phase == DataSyncPhase.testing || _disposed) return;

    state = state.copyWith(
      phase: DataSyncPhase.testing,
      clearTestOk: true,
      clearTestMessage: true,
    );
    try {
      await _api.ping(serverUrl: serverUrl.trim(), accessToken: accessToken);
      if (_disposed) return;
      state = state.copyWith(
        phase: DataSyncPhase.idle,
        testOk: true,
        testMessage: '连接成功，服务器可用',
      );
    } on DataSyncException catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        phase: DataSyncPhase.idle,
        testOk: false,
        testMessage: '连接失败：${error.message}',
      );
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(
        phase: DataSyncPhase.idle,
        testOk: false,
        testMessage: '连接失败，请检查地址、令牌与网络',
      );
    }
  }

  Future<void> syncNow({bool auto = false}) async {
    if (_syncing || _disposed) return;

    final settings = state.settings;
    if (!settings.isConfigured) {
      if (!auto) {
        state = state.copyWith(syncOk: false, syncMessage: '请先保存服务器配置');
      }
      return;
    }
    if (!settings.hasScope) {
      if (!auto) {
        state = state.copyWith(syncOk: false, syncMessage: '请至少选择一项同步内容');
      }
      return;
    }

    _syncing = true;
    state = state.copyWith(
      phase: DataSyncPhase.syncing,
      clearSyncOk: true,
      clearSyncMessage: true,
    );
    try {
      final snapshot = await _snapshots.build(
        includeBooks: settings.progress,
        includeAnnotations: settings.annotations,
        includeSettings: settings.settings,
      );
      final remote = await _api.sync(
        serverUrl: settings.serverUrl!,
        accessToken: settings.accessToken,
        snapshot: snapshot,
      );
      if (remote != null) {
        await _snapshots.apply(remote);
      }

      final now = DateTime.now();
      final next = state.settings.copyWith(lastSyncedAt: now);
      await _repository.save(next);
      if (_disposed) return;
      state = state.copyWith(
        settings: next,
        phase: DataSyncPhase.idle,
        syncOk: true,
        syncMessage: auto ? '已自动同步' : '同步完成',
      );
      _scheduleAutoSync();
    } on DataSyncException catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        phase: DataSyncPhase.idle,
        syncOk: false,
        syncMessage: '同步失败：${error.message}',
      );
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(
        phase: DataSyncPhase.idle,
        syncOk: false,
        syncMessage: '同步失败，请稍后重试',
      );
    } finally {
      _syncing = false;
    }
  }

  Future<void> _persist(
    DataSyncSettings next, {
    bool reschedule = true,
  }) async {
    if (_disposed) return;
    state = state.copyWith(settings: next);
    try {
      await _repository.save(next);
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(
        syncOk: false,
        syncMessage: '保存同步设置失败，请稍后重试',
      );
    }
    if (reschedule) _scheduleAutoSync();
  }

  void _scheduleAutoSync() {
    _timer?.cancel();
    _timer = null;
    if (_disposed) return;

    final settings = state.settings;
    if (!settings.enabled || !settings.isConfigured || !settings.hasScope) {
      return;
    }

    final last = settings.lastSyncedAt;
    final due =
        last == null || DateTime.now().difference(last) >= autoSyncInterval;
    if (due) unawaited(syncNow(auto: true));

    _timer = Timer.periodic(
      autoSyncInterval,
      (_) => unawaited(syncNow(auto: true)),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
