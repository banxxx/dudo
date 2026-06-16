import 'dart:convert';

import 'package:dudo/core/rule_engine/rule_engine.dart';
import 'package:dudo/features/reader_engine/data/remote_reader_content_loader.dart';
import 'package:dudo/features/reader_engine/data/text_reader_book_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads remote chapter content and writes it back to cache', () async {
    final repository = _FakeTextReaderBookRepository();
    final requested = <String>[];
    final loader = RemoteReaderContentLoader(
      repository: repository,
      sourceResolver: (sourceId) async => RemoteReaderSourceRecord(
        id: sourceId,
        name: 'Source',
        rulesJson: jsonEncode({
          'bookSourceUrl': sourceId,
          'bookSourceName': 'Source',
          'ruleContent': {'content': r'$.content'},
        }),
      ),
      contentFetcher: (source, contentUrl) async {
        requested.add('${source.id}|$contentUrl');
        return const ContentResult(
          title: 'Remote title',
          content: 'Chapter 1\nRemote body',
        );
      },
    );

    final loaded = await loader.loadIfNeeded(
      const ReaderBookRecord(
        id: 'book-1',
        title: 'Book',
        sourceId: 'source-1',
      ),
      const ReaderChapterRecord(
        id: 'chapter-1',
        bookId: 'book-1',
        chapterIndex: 0,
        title: 'Chapter 1',
        url: 'https://source.example/chapter/1',
        normalizedContentLength: 0,
        isCached: false,
      ),
    );

    expect(requested, ['source-1|https://source.example/chapter/1']);
    expect(loaded, isNotNull);
    expect(loaded!.isCached, isTrue);
    expect(loaded.content, 'Chapter 1\nRemote body');
    expect(repository.cachedContent, 'Chapter 1\nRemote body');
    expect(repository.cachedNormalizedContentLength, 'Remote body'.length);
  });

  test('skips cached chapters without calling source resolver', () async {
    final repository = _FakeTextReaderBookRepository();
    var resolverCalled = false;
    final loader = RemoteReaderContentLoader(
      repository: repository,
      sourceResolver: (sourceId) async {
        resolverCalled = true;
        return null;
      },
      contentFetcher: (source, contentUrl) async {
        fail('contentFetcher should not be called for cached chapters');
      },
    );

    final loaded = await loader.loadIfNeeded(
      const ReaderBookRecord(
        id: 'book-1',
        title: 'Book',
        sourceId: 'source-1',
      ),
      const ReaderChapterRecord(
        id: 'chapter-1',
        bookId: 'book-1',
        chapterIndex: 0,
        title: 'Chapter 1',
        url: 'https://source.example/chapter/1',
        content: 'Cached body',
        normalizedContentLength: 11,
        isCached: true,
      ),
    );

    expect(loaded, isNull);
    expect(resolverCalled, isFalse);
  });
}

class _FakeTextReaderBookRepository implements TextReaderBookRepository {
  String? cachedContent;
  int? cachedNormalizedContentLength;

  @override
  Future<void> cacheChapterContent({
    required String bookId,
    required int chapterIndex,
    required String content,
    required int normalizedContentLength,
  }) async {
    cachedContent = content;
    cachedNormalizedContentLength = normalizedContentLength;
  }

  @override
  Future<ReaderChapterRecord?> fetchChapterAtIndex({
    required String bookId,
    required int chapterIndex,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> fetchChapterCount(String bookId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ReaderChapterRecord>> fetchChapterMetasPage({
    required String bookId,
    required int offset,
    required int limit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ReaderBookRecord?> fetchBookById(String bookId) {
    throw UnimplementedError();
  }
}
