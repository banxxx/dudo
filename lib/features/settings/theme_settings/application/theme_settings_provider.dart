import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../data/theme_settings_repository.dart';
import '../domain/theme_settings.dart';

final themeSettingsRepositoryProvider = Provider<ThemeSettingsRepository>((ref) {
  return DriftThemeSettingsRepository(ref.watch(appDatabaseProvider));
});

/// Persisted theme appearance settings. Watched by the app root so changing the
/// mode or accent restyles the whole tree, and by the settings page to show the
/// active selection.
final themeSettingsProvider = StreamProvider<ThemeSettings>((ref) {
  return ref.watch(themeSettingsRepositoryProvider).watch();
});
