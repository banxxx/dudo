import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../domain/reader_font.dart';

abstract class ReaderFontRepository {
  Future<ReaderFontLibrary> loadLibrary();

  Future<ReaderFont?> pickAndImportFont();

  Future<void> selectFont(String familyKey);

  Future<void> deleteImportedFont(String id);

  Future<String> readSelectedFontFamily();

  Future<void> loadImportedFonts();
}

class ReaderFontImportException implements Exception {
  const ReaderFontImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DriftReaderFontRepository implements ReaderFontRepository {
  DriftReaderFontRepository(this._database, {ReaderFontLoader? loader})
      : _loader = loader ?? ReaderFontLoader();

  static const _selectedFontKey = 'reader.selected_font_family';
  static const _maxFontBytes = 50 * 1024 * 1024;

  final AppDatabase _database;
  final ReaderFontLoader _loader;

  @override
  Future<ReaderFontLibrary> loadLibrary() async {
    await loadImportedFonts();
    final selectedFamilyKey = await readSelectedFontFamily();
    final imported = await (_database.select(_database.importedReaderFonts)
          ..where((table) => table.isDeleted.equals(false))
          ..orderBy([
            (table) => OrderingTerm(
                expression: table.importedAt, mode: OrderingMode.desc),
          ]))
        .get();

    return ReaderFontLibrary(
      selectedFamilyKey: _resolveSelectedFamily(
        selectedFamilyKey,
        imported.map(_fromImportedFont).toList(),
      ),
      fonts: [
        ...ReaderBuiltinFonts.values,
        ...imported.map(_fromImportedFont),
      ],
    );
  }

  @override
  Future<ReaderFont?> pickAndImportFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['ttf', 'otf'],
      allowMultiple: false,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return null;

    final extension =
        p.extension(file.name).toLowerCase().replaceFirst('.', '');
    if (extension != 'ttf' && extension != 'otf') {
      throw const ReaderFontImportException('请选择 .ttf 或 .otf 字体文件');
    }

    final bytes = file.bytes ?? await _readPickedPath(file.path);
    if (bytes.isEmpty) {
      throw const ReaderFontImportException('字体文件为空，无法导入');
    }
    if (bytes.length > _maxFontBytes) {
      throw const ReaderFontImportException('字体文件超过 50MB，无法导入');
    }

    final digest = sha256.convert(bytes).toString();
    final id = 'font_${digest.substring(0, 16)}';
    final familyKey = 'DudoImportedFont_${digest.substring(0, 16)}';
    final displayName = _displayNameFor(file.name);
    final relativePath = p.join('fonts', 'imported', id, 'font.$extension');
    final target = await _resolveSupportFile(relativePath);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);

    final now = DateTime.now();
    await _database.into(_database.importedReaderFonts).insertOnConflictUpdate(
          ImportedReaderFontsCompanion(
            id: Value(id),
            displayName: Value(displayName),
            familyKey: Value(familyKey),
            relativePath: Value(relativePath),
            originalFileName: Value(file.name),
            fileExtension: Value(extension),
            fileSize: Value(bytes.length),
            sha256: Value(digest),
            importedAt: Value(now),
            isDeleted: const Value(false),
          ),
        );

    final font = ReaderFont(
      id: id,
      displayName: displayName,
      familyKey: familyKey,
      source: ReaderFontSource.imported,
      originalFileName: file.name,
      fileSize: bytes.length,
      relativePath: relativePath,
      importedAt: now,
    );
    await _loader.loadFont(font, target);
    await selectFont(font.familyKey);
    return font;
  }

  @override
  Future<void> selectFont(String familyKey) async {
    await _database.into(_database.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(_selectedFontKey),
            value: Value(familyKey),
            updatedAt: Value(DateTime.now()),
          ),
        );

    await (_database.update(_database.importedReaderFonts)
          ..where((table) => table.familyKey.equals(familyKey)))
        .write(ImportedReaderFontsCompanion(lastUsedAt: Value(DateTime.now())));
  }

  @override
  Future<void> deleteImportedFont(String id) async {
    final font = await (_database.select(_database.importedReaderFonts)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();
    if (font == null) return;

    await (_database.update(_database.importedReaderFonts)
          ..where((table) => table.id.equals(id)))
        .write(const ImportedReaderFontsCompanion(isDeleted: Value(true)));

    if (await readSelectedFontFamily() == font.familyKey) {
      await selectFont(ReaderBuiltinFonts.serifSc.familyKey);
    }

    final file = await _resolveSupportFile(font.relativePath);
    try {
      final dir = file.parent;
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  @override
  Future<String> readSelectedFontFamily() async {
    final preference = await (_database.select(_database.appPreferences)
          ..where((table) => table.key.equals(_selectedFontKey)))
        .getSingleOrNull();
    return preference?.value ?? ReaderBuiltinFonts.serifSc.familyKey;
  }

  @override
  Future<void> loadImportedFonts() async {
    final imported = await (_database.select(_database.importedReaderFonts)
          ..where((table) => table.isDeleted.equals(false)))
        .get();
    for (final font in imported) {
      final model = _fromImportedFont(font);
      final file = await _resolveSupportFile(font.relativePath);
      if (await file.exists()) {
        await _loader.loadFont(model, file);
      }
    }
  }

  Future<Uint8List> _readPickedPath(String? path) async {
    if (path == null) {
      throw const ReaderFontImportException('无法读取所选字体文件');
    }
    return File(path).readAsBytes();
  }

  String _resolveSelectedFamily(String selected, List<ReaderFont> imported) {
    final allFonts = [...ReaderBuiltinFonts.values, ...imported];
    if (allFonts.any((font) => font.familyKey == selected)) return selected;
    return ReaderBuiltinFonts.serifSc.familyKey;
  }

  ReaderFont _fromImportedFont(ImportedReaderFont font) {
    return ReaderFont(
      id: font.id,
      displayName: font.displayName,
      familyKey: font.familyKey,
      source: ReaderFontSource.imported,
      originalFileName: font.originalFileName,
      fileSize: font.fileSize,
      relativePath: font.relativePath,
      importedAt: font.importedAt,
    );
  }

  String _displayNameFor(String fileName) {
    final name = p.basenameWithoutExtension(fileName).trim();
    return name.isEmpty ? '未命名字体' : name;
  }

  Future<File> _resolveSupportFile(String relativePath) async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, relativePath));
  }
}

class ReaderFontLoader {
  final Set<String> _loadedFamilies = <String>{};

  Future<void> loadFont(ReaderFont font, File file) async {
    if (font.isBuiltin || _loadedFamilies.contains(font.familyKey)) return;
    final bytes = await file.readAsBytes();
    final loader = FontLoader(font.familyKey)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await loader.load();
    _loadedFamilies.add(font.familyKey);
  }
}
