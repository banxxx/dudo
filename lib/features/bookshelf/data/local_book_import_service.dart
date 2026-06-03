import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import 'bookshelf_repository.dart';
import 'local_book_chapter_analysis_service.dart';

class LocalBookImportCandidate {
  const LocalBookImportCandidate({
    required this.sourcePath,
    required this.fileName,
    required this.title,
  });

  final String sourcePath;
  final String fileName;
  final String title;
}

enum LocalBookDuplicateResolution { skip, overwrite, importAnyway }

class LocalBookImportResult {
  const LocalBookImportResult({required this.bookId, required this.title});

  final String bookId;
  final String title;
}

abstract class LocalBookImporter {
  Future<LocalBookImportCandidate?> pickTxtBook();

  Future<LocalBookImportResult?> importTxtBook();

  Future<LocalBookImportResult> importTxtBookCandidate(
    LocalBookImportCandidate candidate, {
    Book? overwriteBook,
  });

  Future<int> deleteLocalBooksByIds(Set<String> ids);
}

class LocalBookImportService implements LocalBookImporter {
  const LocalBookImportService({
    required this.repository,
    required this.chapterAnalysisService,
  });

  final BookshelfRepository repository;
  final LocalBookChapterAnalysisService chapterAnalysisService;

  @override
  Future<LocalBookImportCandidate?> pickTxtBook() async {
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

    final title = p.basenameWithoutExtension(pickedFile.name).trim();
    return LocalBookImportCandidate(
      sourcePath: sourcePath,
      fileName: pickedFile.name,
      title: title.isEmpty ? '未命名本地书' : title,
    );
  }

  @override
  Future<LocalBookImportResult?> importTxtBook() async {
    final candidate = await pickTxtBook();
    if (candidate == null) return null;
    return importTxtBookCandidate(candidate);
  }

  @override
  Future<LocalBookImportResult> importTxtBookCandidate(
    LocalBookImportCandidate candidate, {
    Book? overwriteBook,
  }) async {
    final sourceFile = File(candidate.sourcePath);
    final now = DateTime.now();
    final bookId = 'local_${now.microsecondsSinceEpoch}';
    final documentsDir = await getApplicationDocumentsDirectory();
    final bookDir =
        Directory(p.join(documentsDir.path, 'books', 'local', bookId));
    await bookDir.create(recursive: true);
    final localPath = p.join(bookDir.path, 'book.txt');
    await sourceFile.copy(localPath);

    await repository.replaceImportedTxtBook(
      replacedBookIds: overwriteBook == null ? const {} : {overwriteBook.id},
      book: BooksCompanion.insert(
        id: bookId,
        title: candidate.title,
        author: const Value('本地文件'),
        localPath: Value(localPath),
        createdAt: Value(now),
        updatedAt: Value(now),
        inShelf: const Value(true),
        sortOrder: Value(now.millisecondsSinceEpoch),
      ),
      chapters: const [],
    );

    chapterAnalysisService.analyzeInBackground(
      bookId: bookId,
      localPath: localPath,
    );

    if (overwriteBook != null) {
      await _deleteLocalBookFile(overwriteBook);
    }

    return LocalBookImportResult(bookId: bookId, title: candidate.title);
  }

  @override
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
