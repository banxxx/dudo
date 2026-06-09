import 'dart:convert';
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
    await _refreshImportedDisplayNames();
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
    final displayName = _displayNameFor(bytes, file.name);
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

  Future<void> _refreshImportedDisplayNames() async {
    final imported = await (_database.select(_database.importedReaderFonts)
          ..where((table) => table.isDeleted.equals(false)))
        .get();

    for (final font in imported) {
      if (font.displayName != _fallbackDisplayNameFor(font.originalFileName)) {
        continue;
      }

      final file = await _resolveSupportFile(font.relativePath);
      if (!await file.exists()) continue;

      final displayName = ReaderFontDisplayNameParser.tryReadDisplayName(
          await file.readAsBytes());
      if (displayName == null || displayName == font.displayName) continue;

      await (_database.update(_database.importedReaderFonts)
            ..where((table) => table.id.equals(font.id)))
          .write(ImportedReaderFontsCompanion(displayName: Value(displayName)));
    }
  }

  String _displayNameFor(Uint8List bytes, String fileName) {
    return ReaderFontDisplayNameParser.tryReadDisplayName(bytes) ??
        _fallbackDisplayNameFor(fileName);
  }

  String _fallbackDisplayNameFor(String fileName) {
    final name = p.basenameWithoutExtension(fileName).trim();
    return name.isEmpty ? '未命名字体' : name;
  }

  Future<File> _resolveSupportFile(String relativePath) async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, relativePath));
  }
}

class ReaderFontDisplayNameParser {
  ReaderFontDisplayNameParser._();

  static String? tryReadDisplayName(Uint8List bytes) {
    try {
      if (bytes.length < 12) return null;

      final tableCount = _uint16(bytes, 4);
      final directoryEnd = 12 + tableCount * 16;
      if (directoryEnd > bytes.length) return null;

      int? nameOffset;
      int? nameLength;
      for (var i = 0; i < tableCount; i++) {
        final tableOffset = 12 + i * 16;
        if (_tag(bytes, tableOffset) != 'name') continue;
        nameOffset = _uint32(bytes, tableOffset + 8);
        nameLength = _uint32(bytes, tableOffset + 12);
        break;
      }
      if (nameOffset == null || nameLength == null) return null;
      if (nameOffset < 0 ||
          nameLength <= 0 ||
          nameOffset + nameLength > bytes.length ||
          nameOffset + 6 > bytes.length) {
        return null;
      }

      final recordCount = _uint16(bytes, nameOffset + 2);
      final stringStorageOffset = nameOffset + _uint16(bytes, nameOffset + 4);
      final recordsEnd = nameOffset + 6 + recordCount * 12;
      if (recordsEnd > nameOffset + nameLength ||
          stringStorageOffset > nameOffset + nameLength) {
        return null;
      }

      final candidates = <_ReaderFontNameCandidate>[];
      for (var i = 0; i < recordCount; i++) {
        final recordOffset = nameOffset + 6 + i * 12;
        final platformId = _uint16(bytes, recordOffset);
        final encodingId = _uint16(bytes, recordOffset + 2);
        final languageId = _uint16(bytes, recordOffset + 4);
        final nameId = _uint16(bytes, recordOffset + 6);
        final length = _uint16(bytes, recordOffset + 8);
        final offset = _uint16(bytes, recordOffset + 10);

        if (nameId != 1 && nameId != 4 && nameId != 16) continue;

        final stringStart = stringStorageOffset + offset;
        final stringEnd = stringStart + length;
        if (stringStart < stringStorageOffset ||
            stringEnd > nameOffset + nameLength ||
            stringEnd > bytes.length) {
          continue;
        }

        final value = _decodeName(
          bytes.sublist(stringStart, stringEnd),
          platformId,
          encodingId,
        );
        if (value == null || value.isEmpty) continue;

        candidates.add(
          _ReaderFontNameCandidate(
            value: value,
            nameId: nameId,
            platformId: platformId,
            encodingId: encodingId,
            languageId: languageId,
          ),
        );
      }

      if (candidates.isEmpty) return null;
      candidates.sort((a, b) => b.score.compareTo(a.score));
      return candidates.first.value;
    } catch (_) {
      return null;
    }
  }

  static String? _decodeName(
    Uint8List bytes,
    int platformId,
    int encodingId,
  ) {
    final value = switch (platformId) {
      0 => _decodeUtf16BigEndian(bytes),
      1 => latin1.decode(bytes, allowInvalid: true),
      3 when encodingId == 0 || encodingId == 1 || encodingId == 10 =>
        _decodeUtf16BigEndian(bytes),
      _ => null,
    };
    return _normalize(value);
  }

  static String? _decodeUtf16BigEndian(Uint8List bytes) {
    if (bytes.length.isOdd) return null;
    final chars = <int>[];
    for (var i = 0; i < bytes.length; i += 2) {
      chars.add((bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(chars);
  }

  static String? _normalize(String? value) {
    final normalized = value?.replaceAll('\u0000', '').trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _tag(Uint8List bytes, int offset) {
    return ascii.decode(bytes.sublist(offset, offset + 4), allowInvalid: true);
  }

  static int _uint16(Uint8List bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  static int _uint32(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }
}

class _ReaderFontNameCandidate {
  const _ReaderFontNameCandidate({
    required this.value,
    required this.nameId,
    required this.platformId,
    required this.encodingId,
    required this.languageId,
  });

  final String value;
  final int nameId;
  final int platformId;
  final int encodingId;
  final int languageId;

  int get score {
    final nameScore = switch (nameId) {
      16 => 300,
      1 => 200,
      4 => 100,
      _ => 0,
    };
    final languageScore = switch (languageId) {
      0x0804 => 40,
      0x0404 || 0x0c04 => 35,
      0x0409 => 25,
      0 => 15,
      _ => 0,
    };
    final platformScore = switch (platformId) {
      3 => 20,
      0 => 15,
      1 => 5,
      _ => 0,
    };
    final encodingScore = platformId == 3 && encodingId == 10 ? 5 : 0;
    return nameScore + languageScore + platformScore + encodingScore;
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
