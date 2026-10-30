/// The storage buckets the app can account for on the "缓存与存储" page.
///
/// Only [coverCache] and [speechCache] are reclaimable: the database holds the
/// library itself and imported fonts are managed from 字体管理, so neither gets
/// a destructive action here.
enum StorageCategory { coverCache, speechCache, database, fonts }

class StorageUsageItem {
  const StorageUsageItem({
    required this.category,
    required this.title,
    required this.description,
    required this.bytes,
    this.fileCount = 0,
    this.clearable = false,
  });

  final StorageCategory category;
  final String title;
  final String description;
  final int bytes;
  final int fileCount;
  final bool clearable;
}

/// A snapshot of everything the storage page reports.
class StorageUsage {
  const StorageUsage({required this.items});

  final List<StorageUsageItem> items;

  int get totalBytes => items.fold(0, (sum, item) => sum + item.bytes);

  int get clearableBytes => items
      .where((item) => item.clearable)
      .fold(0, (sum, item) => sum + item.bytes);

  bool get hasClearableData => items.any(
        (item) => item.clearable && item.bytes > 0,
      );

  StorageUsageItem? itemFor(StorageCategory category) {
    for (final item in items) {
      if (item.category == category) return item;
    }
    return null;
  }
}

/// Formats a byte count the way the rest of the app shows sizes: no space
/// before the unit, one decimal below 100 (`11.8MB`, `1.2GB`), integers above.
String formatStorageBytes(int bytes) {
  if (bytes <= 0) return '0B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  if (unitIndex == 0) return '${value.round()}B';
  final text = value >= 100
      ? value.round().toString()
      : value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  return '$text${units[unitIndex]}';
}
