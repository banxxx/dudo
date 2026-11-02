import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/offline_cache_settings_repository.dart';
import '../domain/offline_cache_settings.dart';

final offlineCacheSettingsRepositoryProvider =
    Provider<OfflineCacheSettingsRepository>((ref) {
  return DriftOfflineCacheSettingsRepository(ref.watch(appDatabaseProvider));
});

/// The persisted download concurrency. The initial value is the default while
/// the repository loads; the UI can be interacted with immediately.
class OfflineCacheSettingsController
    extends StateNotifier<OfflineCacheSettings> {
  OfflineCacheSettingsController(this._repository)
      : super(OfflineCacheSettings.defaults()) {
    unawaited(_load());
  }

  final OfflineCacheSettingsRepository _repository;
  bool _disposed = false;
  bool _dirty = false;

  Future<void> _load() async {
    try {
      final settings = await _repository.load();
      if (_disposed || _dirty) return;
      state = settings;
    } catch (_) {
      // Keep the default; the page remains usable if preferences are missing.
    }
  }

  Future<void> setConcurrency(int value) async {
    if (!OfflineCacheSettings.concurrencyOptions.contains(value)) return;
    if (state.concurrency == value) return;
    _dirty = true;
    state = state.copyWith(concurrency: value);
    try {
      await _repository.save(state);
    } catch (_) {
      // The in-memory value still applies for this session.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final offlineCacheSettingsControllerProvider =
    StateNotifierProvider<OfflineCacheSettingsController, OfflineCacheSettings>(
  (ref) {
    return OfflineCacheSettingsController(
      ref.watch(offlineCacheSettingsRepositoryProvider),
    );
  },
);
