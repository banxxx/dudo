import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import 'bookshelf_repository.dart';

class LocalBookImportResult {
  const LocalBookImportResult({required this.bookId, required this.title});

  final String bookId;
  final String title;
}

class LocalBookImportService {
  const LocalBookImportService({required this.repository});

  final BookshelfRepository repository;

  Future<LocalBookImportResult?> importTxtBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt'],
      allowMultiple: false,
      withData: false,
    );

    final pickedFile = result?.files.single;
    final sourcePath = pickedFile?.path;
    if (pickedFile == null || sourcePath == null) {
      return null;
    }

    final sourceFile = File(sourcePath);
    final content = await sourceFile.readAsString();
    final now = DateTime.now();
    final bookId = 'local_${now.microsecondsSinceEpoch}';
    final title = p.basenameWithoutExtension(pickedFile.name).trim();
    final safeTitle = title.isEmpty ? '未命名本地书' : title;
    final documentsDir = await getApplicationDocumentsDirectory();
    final bookDir =
        Directory(p.join(documentsDir.path, 'books', 'local', bookId));
    await bookDir.create(recursive: true);
    final localPath = p.join(bookDir.path, 'book.txt');
    await sourceFile.copy(localPath);

    await repository.insertImportedTxtBook(
      book: BooksCompanion.insert(
        id: bookId,
        title: safeTitle,
        author: const Value('本地文件'),
        localPath: Value(localPath),
        createdAt: Value(now),
        updatedAt: Value(now),
        inShelf: const Value(true),
        sortOrder: Value(now.millisecondsSinceEpoch),
      ),
      chapter: ChaptersCompanion.insert(
        id: '${bookId}_chapter_0',
        bookId: bookId,
        chapterIndex: 0,
        title: '全文',
        content: Value(content),
        isCached: const Value(true),
        fetchedAt: Value(now),
      ),
    );

    return LocalBookImportResult(bookId: bookId, title: safeTitle);
  }

  Future<int> deleteLocalBooksByIds(Set<String> ids) async {
    final deletedBooks = await repository.deleteLocalBooksByIds(ids);
    for (final book in deletedBooks) {
      await _deleteLocalBookFile(book);
    }
    return deletedBooks.length;
  }

  Future<void> _deleteLocalBookFile(Book book) async {
    final localPath = book.localPath;
    if (localPath == null) return;

    final file = File(localPath);
    final bookDir = file.parent;
    try {
      final isImportedBookDir = p.basename(bookDir.path) == book.id &&
          p.basename(bookDir.parent.path) == 'local' &&
          p.basename(bookDir.parent.parent.path) == 'books';
      if (isImportedBookDir) {
        if (await bookDir.exists()) await bookDir.delete(recursive: true);
        return;
      }
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
