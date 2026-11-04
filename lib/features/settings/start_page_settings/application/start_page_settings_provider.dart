import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../data/start_page_settings_repository.dart';
import '../domain/start_page_settings.dart';

final startPageSettingsRepositoryProvider =
    Provider<StartPageSettingsRepository>((ref) {
  return DriftStartPageSettingsRepository(ref.watch(appDatabaseProvider));
});

/// Persisted startup-page choice. `main()` reads the repository directly
/// before the router exists; the settings page watches this stream so its row
/// and picker follow every save.
final startPageSettingsProvider = StreamProvider<StartPageSettings>((ref) {
  return ref.watch(startPageSettingsRepositoryProvider).watch();
});
