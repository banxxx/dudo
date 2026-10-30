import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/storage_usage_repository.dart';
import '../domain/storage_usage.dart';

final storageUsageRepositoryProvider = Provider<StorageUsageRepository>((ref) {
  return const FileSystemStorageUsageRepository();
});

/// Real on-device usage, shared by the 缓存与存储 page and the settings row
/// that shows the current total. Invalidate it after clearing a cache.
final storageUsageProvider = FutureProvider<StorageUsage>((ref) {
  return ref.watch(storageUsageRepositoryProvider).measure();
});
