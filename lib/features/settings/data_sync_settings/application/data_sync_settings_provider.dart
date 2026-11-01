import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../data/data_sync_api.dart';
import '../data/data_sync_settings_repository.dart';
import '../data/sync_snapshot_repository.dart';
import '../domain/data_sync_settings.dart';
import 'data_sync_controller.dart';

final dataSyncSettingsRepositoryProvider =
    Provider<DataSyncSettingsRepository>((ref) {
  return DriftDataSyncSettingsRepository(ref.watch(appDatabaseProvider));
});

/// Persisted cloud sync settings, watched by the settings row and the sync
/// page.
final dataSyncSettingsProvider = StreamProvider<DataSyncSettings>((ref) {
  return ref.watch(dataSyncSettingsRepositoryProvider).watch();
});

final dataSyncApiProvider = Provider<DataSyncApi>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return DudoSyncApi(dio);
});

final syncSnapshotRepositoryProvider = Provider<SyncSnapshotStore>((ref) {
  return SyncSnapshotRepository(ref.watch(appDatabaseProvider));
});

/// Settings, connection test, manual sync and the foreground auto-sync timer.
/// `DudoApp` keeps this alive for the whole app session.
final dataSyncControllerProvider =
    StateNotifierProvider<DataSyncController, DataSyncState>((ref) {
  return DataSyncController(
    repository: ref.watch(dataSyncSettingsRepositoryProvider),
    api: ref.watch(dataSyncApiProvider),
    snapshots: ref.watch(syncSnapshotRepositoryProvider),
  );
});
