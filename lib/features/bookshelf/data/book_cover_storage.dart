import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores user-cropped covers under the app documents directory. The database
/// only keeps the absolute paths, so removing a book's artwork is a simple
/// file delete plus nulling the columns.
class BookCoverStorage {
  const BookCoverStorage();

  static const _folder = 'covers';

  Future<String> saveFrontCover(String bookId, Uint8List bytes) {
    return _write(bookId, 'front', bytes);
  }

  Future<String> saveWrapCover(String bookId, Uint8List bytes) {
    return _write(bookId, 'wrap', bytes);
  }

  Future<void> deleteBookCovers(String bookId) async {
    final directory = await _directory();
    final prefix = _safeId(bookId);
    if (!directory.existsSync()) return;
    await for (final entity in directory.list()) {
      if (entity is File && p.basename(entity.path).startsWith('${prefix}_')) {
        try {
          await entity.delete();
        } on FileSystemException {
          // The file may already be gone; nothing else to clean up.
        }
      }
    }
  }

  Future<String> _write(String bookId, String kind, Uint8List bytes) async {
    final directory = await _directory();
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    final file = File(
      p.join(directory.path, '${_safeId(bookId)}_$kind.png'),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Directory> _directory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, _folder));
  }

  String _safeId(String bookId) {
    final digest = sha256.convert(utf8.encode(bookId)).toString();
    return digest.substring(0, 16);
  }
}

final bookCoverStorageProvider = Provider<BookCoverStorage>((ref) {
  return const BookCoverStorage();
});
