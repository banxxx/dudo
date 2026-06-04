import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../reader/domain/reader_text_normalizer.dart';
import 'bookshelf_repository.dart';
import 'txt_chapter_parser.dart';

class LocalBookChapterAnalysisService {
  LocalBookChapterAnalysisService({required this.repository});

  final BookshelfRepository repository;
  final Set<String> _runningBookIds = <String>{};

  void analyzeInBackground({required String bookId, required String localPath}) {
    if (!_runningBookIds.add(bookId)) return;
    Future<void>(() async {
      try {
        await analyzeNow(bookId: bookId, localPath: localPath);
      } catch (_) {
      } finally {
        _runningBookIds.remove(bookId);
      }
    });
  }

  Future<void> analyzeNow({required String bookId, required String localPath}) async {
    final result = await Isolate.run(
      () => _parseLocalTxtBook(_LocalTxtParseRequest(localPath)),
    );
    final now = DateTime.now();
    await repository.replaceChaptersForBook(
      bookId: bookId,
      chapters: [
        for (var i = 0; i < result.chapters.length; i++)
          ChaptersCompanion.insert(
            id: '${bookId}_chapter_$i',
            bookId: bookId,
            chapterIndex: i,
            title: result.chapters[i].title,
            content: Value(result.chapters[i].content),
            normalizedContentLength: Value(
              normalizedReaderTextLength(result.chapters[i].content),
            ),
            isCached: const Value(true),
            fetchedAt: Value(now),
          ),
      ],
    );
  }
}

class _LocalTxtParseRequest {
  const _LocalTxtParseRequest(this.localPath);

  final String localPath;
}

TxtChapterParseResult _parseLocalTxtBook(_LocalTxtParseRequest request) {
  final content = File(request.localPath).readAsStringSync();
  return TxtChapterParser.parse(content);
}
