import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../data/read_aloud_settings_repository.dart';
import '../domain/read_aloud_settings.dart';

final readAloudSettingsRepositoryProvider =
    Provider<ReadAloudSettingsRepository>((ref) {
  return DriftReadAloudSettingsRepository(ref.watch(appDatabaseProvider));
});

/// Persisted read-aloud settings, watched by the settings row that shows the
/// active voice and speed.
final readAloudSettingsProvider = StreamProvider<ReadAloudSettings>((ref) {
  return ref.watch(readAloudSettingsRepositoryProvider).watch();
});
