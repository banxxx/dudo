import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/storage_usage.dart';

/// Measures and reclaims the storage the app owns on this device.
abstract interface class StorageUsageRepository {
  Future<StorageUsage> measure();

  /// Deletes the files behind [category] and returns the bytes that were
  /// reclaimed. Only cache buckets should ever be passed here.
  Future<int> clearCache(StorageCategory category);
}

/// Reads the real directories instead of guessing: the image cache, the TTS
/// temp files, the SQLite database and imported reader fonts all live in
/// different platform folders (see the repositories that write them).
class FileSystemStorageUsageRepository implements StorageUsageRepository {
  const FileSystemStorageUsageRepository();

  @override
  Future<StorageUsage> measure() async {
    final locations = await _locations();
    final cover = await _measurePaths(locations.cover);
    final speech = await _measurePaths(locations.speech);
    final database = await _measurePaths(locations.database);
    final fonts = await _measurePaths(locations.fonts);

    return StorageUsage(
      items: [
        StorageUsageItem(
          category: StorageCategory.coverCache,
          title: '封面缓存',
          description: '书籍封面与远程图片',
          bytes: cover.bytes,
          fileCount: cover.files,
          clearable: true,
        ),
        StorageUsageItem(
          category: StorageCategory.speechCache,
          title: '语音临时文件',
          description: '朗读试听生成的音频',
          bytes: speech.bytes,
          fileCount: speech.files,
          clearable: true,
        ),
        StorageUsageItem(
          category: StorageCategory.database,
          title: '阅读数据库',
          description: '书籍、章节、书签与阅读记录',
          bytes: database.bytes,
          fileCount: database.files,
        ),
        StorageUsageItem(
          category: StorageCategory.fonts,
          title: '导入字体',
          description: '自定义阅读字体',
          bytes: fonts.bytes,
          fileCount: fonts.files,
        ),
      ],
    );
  }

  @override
  Future<int> clearCache(StorageCategory category) async {
    final locations = await _locations();
    final paths = switch (category) {
      StorageCategory.coverCache => locations.cover,
      StorageCategory.speechCache => locations.speech,
      StorageCategory.database => const <String>[],
      StorageCategory.fonts => const <String>[],
    };
    final before = await _measurePaths(paths);
    for (final path in paths) {
      await _deletePath(path);
    }
    return before.bytes;
  }

  Future<_StorageLocations> _locations() async {
    final temp = await getTemporaryDirectory();
    final support = await getApplicationSupportDirectory();
    final documents = await getApplicationDocumentsDirectory();
    return _StorageLocations(
      cover: [
        p.join(temp.path, 'libCachedImageData'),
        p.join(support.path, 'libCachedImageData.db'),
        p.join(support.path, 'libCachedImageData.db-journal'),
      ],
      speech: [p.join(temp.path, 'dudo_tts')],
      database: [
        p.join(documents.path, 'dudo.sqlite'),
        p.join(documents.path, 'dudo.sqlite-wal'),
        p.join(documents.path, 'dudo.sqlite-shm'),
      ],
      fonts: [p.join(support.path, 'fonts', 'imported')],
    );
  }

  Future<_Measured> _measurePaths(List<String> paths) async {
    var bytes = 0;
    var files = 0;
    for (final path in paths) {
      final type = await FileSystemEntity.type(path, followLinks: false);
      if (type == FileSystemEntityType.directory) {
        await for (final entity
            in Directory(path).list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final length = await _lengthOf(entity);
            if (length != null) {
              bytes += length;
              files++;
            }
          }
        }
      } else if (type == FileSystemEntityType.file) {
        final length = await _lengthOf(File(path));
        if (length != null) {
          bytes += length;
          files++;
        }
      }
    }
    return _Measured(bytes: bytes, files: files);
  }

  Future<int?> _lengthOf(File file) async {
    try {
      return await file.length();
    } on FileSystemException {
      return null;
    }
  }

  Future<void> _deletePath(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    try {
      if (type == FileSystemEntityType.directory) {
        await Directory(path).delete(recursive: true);
      } else if (type == FileSystemEntityType.file) {
        await File(path).delete();
      }
    } on FileSystemException {
      // A file vanished or is locked; the next measure() reports what is left.
    }
  }
}

class _StorageLocations {
  const _StorageLocations({
    required this.cover,
    required this.speech,
    required this.database,
    required this.fonts,
  });

  final List<String> cover;
  final List<String> speech;
  final List<String> database;
  final List<String> fonts;
}

class _Measured {
  const _Measured({required this.bytes, required this.files});

  final int bytes;
  final int files;
}
