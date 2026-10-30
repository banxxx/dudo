import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../data/shelf_update_settings_repository.dart';
import '../domain/shelf_update_settings.dart';

final shelfUpdateSettingsRepositoryProvider =
    Provider<ShelfUpdateSettingsRepository>((ref) {
  return DriftShelfUpdateSettingsRepository(ref.watch(appDatabaseProvider));
});

/// Persisted shelf update settings, watched by the settings row that shows the
/// active schedule.
final shelfUpdateSettingsProvider = StreamProvider<ShelfUpdateSettings>((ref) {
  return ref.watch(shelfUpdateSettingsRepositoryProvider).watch();
});
