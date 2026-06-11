import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../domain/reader_background.dart';

abstract interface class ReaderBackgroundRepository {
  Future<ReaderBackgroundPreference> readPreference();

  Future<ReaderBackgroundPreference?> readCustomPreference();

  Future<void> savePreference(ReaderBackgroundPreference preference);

  Future<ReaderBackgroundPreference?> pickAndImportBackground();
}

class DriftReaderBackgroundRepository implements ReaderBackgroundRepository {
  const DriftReaderBackgroundRepository(this._database);

  static const preferenceKey = 'reader.background.preference';
  static const customPreferenceKey = 'reader.background.customPreference';
  static const _maxBackgroundBytes = 10 * 1024 * 1024;

  final AppDatabase _database;

  @override
  Future<ReaderBackgroundPreference> readPreference() async {
    final preference = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(preferenceKey)))
        .getSingleOrNull();
    final value = preference?.value;
    if (value == null || value.isEmpty) {
      return ReaderBackgroundPreference.defaults();
    }
    return ReaderBackgroundPreference.fromJsonString(value);
  }

  @override
  Future<ReaderBackgroundPreference?> readCustomPreference() async {
    final preference = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(customPreferenceKey)))
        .getSingleOrNull();
    final value = preference?.value;
    if (value == null || value.isEmpty) return null;

    final background = ReaderBackgroundPreference.fromJsonString(value);
    if (background.type != ReaderBackgroundType.customImage) return null;
    return background.hasImage ? background : null;
  }

  @override
  Future<void> savePreference(ReaderBackgroundPreference preference) async {
    final now = DateTime.now();
    await _database.transaction(() async {
      await _savePreferenceValue(preferenceKey, preference, now);
      if (preference.type == ReaderBackgroundType.customImage) {
        await _savePreferenceValue(customPreferenceKey, preference, now);
      }
    });
  }

  @override
  Future<ReaderBackgroundPreference?> pickAndImportBackground() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: false,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return null;

    final extension =
        p.extension(file.name).toLowerCase().replaceFirst('.', '');
    if (!const {'png', 'jpg', 'jpeg', 'webp'}.contains(extension)) {
      throw const ReaderBackgroundImportException(
        '请选择 PNG、JPG 或 WEBP 图片',
      );
    }

    final bytes = file.bytes ?? await _readPickedPath(file.path);
    if (bytes.isEmpty) {
      throw const ReaderBackgroundImportException('图片文件为空，无法导入');
    }
    if (bytes.length > _maxBackgroundBytes) {
      throw const ReaderBackgroundImportException('图片超过 10MB，无法导入');
    }

    final digest = sha256.convert(bytes).toString();
    final id = 'custom_${digest.substring(0, 16)}';
    final relativePath = p.join(
      'reader_backgrounds',
      'custom',
      '$id.$extension',
    );
    final target = await _resolveSupportFile(relativePath);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);

    final preference = ReaderBackgroundPreference(
      type: ReaderBackgroundType.customImage,
      id: id,
      filePath: target.path,
      opacity: 0.18,
      alignment: Alignment.center,
      fit: BoxFit.cover,
      tintEnabled: false,
      grayscaleEnabled: false,
      blurRadius: 0,
    );
    await savePreference(preference);
    return preference;
  }

  Future<Uint8List> _readPickedPath(String? path) async {
    if (path == null) {
      throw const ReaderBackgroundImportException('无法读取所选图片');
    }
    return File(path).readAsBytes();
  }

  Future<File> _resolveSupportFile(String relativePath) async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, relativePath));
  }

  Future<void> _savePreferenceValue(
    String key,
    ReaderBackgroundPreference preference,
    DateTime updatedAt,
  ) {
    return _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: Value(key),
            value: Value(preference.toJsonString()),
            updatedAt: Value(updatedAt),
          ),
        );
  }
}

class ReaderBackgroundImportException implements Exception {
  const ReaderBackgroundImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
