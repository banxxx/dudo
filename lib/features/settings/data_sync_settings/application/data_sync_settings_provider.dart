import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../data/data_sync_settings_repository.dart';
import '../domain/data_sync_settings.dart';

final dataSyncSettingsRepositoryProvider =
    Provider<DataSyncSettingsRepository>((ref) {
  return DriftDataSyncSettingsRepository(ref.watch(appDatabaseProvider));
});

/// Persisted cloud sync settings, watched by the settings row and the sync
/// page.
final dataSyncSettingsProvider = StreamProvider<DataSyncSettings>((ref) {
  return ref.watch(dataSyncSettingsRepositoryProvider).watch();
});
