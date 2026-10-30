import 'package:dudo/features/settings/storage_settings/domain/storage_usage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats byte counts with the units the app shows', () {
    expect(formatStorageBytes(0), '0B');
    expect(formatStorageBytes(512), '512B');
    expect(formatStorageBytes(2048), '2KB');
    expect(formatStorageBytes(12 * 1024 + 512), '12.5KB');
    expect(formatStorageBytes(100 * 1024 * 1024), '100MB');
    expect(formatStorageBytes(13002342), '12.4MB');
    expect(formatStorageBytes(1288490188), '1.2GB');
  });

  test('totals the buckets and the reclaimable part', () {
    const usage = StorageUsage(
      items: [
        StorageUsageItem(
          category: StorageCategory.coverCache,
          title: '封面缓存',
          description: '书籍封面与远程图片',
          bytes: 300,
          clearable: true,
        ),
        StorageUsageItem(
          category: StorageCategory.speechCache,
          title: '语音临时文件',
          description: '朗读试听生成的音频',
          bytes: 200,
          clearable: true,
        ),
        StorageUsageItem(
          category: StorageCategory.database,
          title: '阅读数据库',
          description: '书籍、章节、书签与阅读记录',
          bytes: 500,
        ),
      ],
    );

    expect(usage.totalBytes, 1000);
    expect(usage.clearableBytes, 500);
    expect(usage.hasClearableData, isTrue);
    expect(usage.itemFor(StorageCategory.database)?.bytes, 500);
    expect(usage.itemFor(StorageCategory.fonts), isNull);
  });
}
