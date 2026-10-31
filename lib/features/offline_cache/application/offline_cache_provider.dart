import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/offline_cache_repository.dart';
import '../domain/offline_cache.dart';

final offlineCacheRepositoryProvider = Provider<OfflineCacheRepository>((ref) {
  return OfflineCacheRepository(ref.watch(appDatabaseProvider));
});

/// Downloaded chapter content grouped by book. Invalidate it after clearing.
final offlineCacheProvider = FutureProvider<OfflineCache>((ref) {
  return ref.watch(offlineCacheRepositoryProvider).measure();
});
