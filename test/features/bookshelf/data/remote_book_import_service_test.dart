import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:dudo/core/database/app_database.dart';
import 'package:dudo/core/rule_engine/legado/url/request_executor.dart';
import 'package:dudo/core/rule_engine/rule_engine.dart';
import 'package:dudo/features/bookshelf/data/bookshelf_repository.dart';
import 'package:dudo/features/bookshelf/data/remote_book_import_service.dart';
import 'package:dudo/features/sources/data/source_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeBookshelfRepository bookshelfRepository;
  late _FakeSourceRepository sourceRepository;

  setUp(() async {
    bookshelfRepository = _FakeBookshelfRepository();
    sourceRepository = _FakeSourceRepository(
      Source(
        id: 'mock-source',
        name: 'Mock Source',
        url: 'https://mock.example',
        enabled: true,
        rulesJson: jsonEncode({
          'bookSourceUrl': 'mock-source',
          'bookSourceName': 'Mock Source',
          'ruleToc': {
            'chapterList': r'$.chapterlist[*]',
            'chapterName': r'$.chaptername',
            'chapterUrl': r'$.chapterurl',
            'isVip': r'$.isvip',
          },
        }),
        sortOrder: 0,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });

  test('imports and appends remote catalog pages incrementally', () async {
    final service = RemoteBookImportService(
      bookshelfRepository: bookshelfRepository,
      sourceRepository: sourceRepository,
      ruleEngine: RuleEngine.create(executor: const _PagedTocExecutor()),
    );

    final bookId = await service.importRemoteBook(
      sourceId: 'mock-source',
      bookUrl: 'https://mock.example/androidapi/chapterList?novelId=1&whole=1',
      fallbackName: 'Remote Book',
      fallbackAuthor: 'Author',
    );

    var book = await bookshelfRepository.findBookById(bookId);
    var chapters = await bookshelfRepository.fetchChapterMetasPage(
      bookId: bookId,
      offset: 0,
      limit: 10,
    );

    expect(book?.remoteChapterCount, 4);
    expect(
      book?.remoteNextTocUrl,
      'https://mock.example/androidapi/chapterList?novelId=1&whole=0&more=2&limit=80',
    );
    expect(chapters.map((chapter) => chapter.title), [
      'Chapter 1',
      'Chapter 2',
    ]);

    final loadedMore = await service.loadNextRemoteCatalogPage(bookId);
    book = await bookshelfRepository.findBookById(bookId);
    chapters = await bookshelfRepository.fetchChapterMetasPage(
      bookId: bookId,
      offset: 0,
      limit: 10,
    );

    expect(loadedMore, isTrue);
    expect(book?.remoteChapterCount, 4);
    expect(book?.remoteNextTocUrl, isNull);
    expect(chapters.map((chapter) => chapter.title), [
      'Chapter 1',
      'Chapter 2',
      'Chapter 3',
      'Chapter 4',
    ]);
  });
}

class _FakeBookshelfRepository implements BookshelfRepository {
  final Map<String, Book> _books = {};
  final Map<String, List<Chapter>> _chaptersByBook = {};

  @override
  Future<Book?> findBookById(String bookId) async => _books[bookId];

  @override
  Future<int> fetchChapterCount(String bookId) async =>
      _chaptersByBook[bookId]?.length ?? 0;

  @override
  Future<List<Chapter>> fetchChapterMetasPage({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    final chapters = _chaptersByBook[bookId] ?? const <Chapter>[];
    return chapters.skip(offset).take(limit).toList();
  }

  @override
  Future<void> upsertRemoteBook({
    required BooksCompanion book,
    required List<ChaptersCompanion> chapters,
  }) async {
    final bookId = book.id.value;
    _books[bookId] = _bookFromCompanion(book);
    _chaptersByBook[bookId] = [
      for (final chapter in chapters) _chapterFromCompanion(chapter),
    ];
  }

  @override
  Future<void> appendRemoteBookChapters({
    required String bookId,
    required List<ChaptersCompanion> chapters,
    int? remoteChapterCount,
    String? remoteNextTocUrl,
  }) async {
    final existing = _books[bookId];
    if (existing != null) {
      _books[bookId] = existing.copyWith(
        remoteChapterCount: Value(remoteChapterCount),
        remoteNextTocUrl: Value(remoteNextTocUrl),
        updatedAt: DateTime(2026, 1, 2),
      );
    }
    _chaptersByBook.putIfAbsent(bookId, () => <Chapter>[]).addAll([
      for (final chapter in chapters) _chapterFromCompanion(chapter),
    ]);
    _chaptersByBook[bookId]!.sort(
      (a, b) => a.chapterIndex.compareTo(b.chapterIndex),
    );
  }

  Book _bookFromCompanion(BooksCompanion companion) {
    return Book(
      id: companion.id.value,
      title: companion.title.value,
      author: _valueOr<String?>(companion.author, null),
      coverUrl: _valueOr<String?>(companion.coverUrl, null),
      intro: _valueOr<String?>(companion.intro, null),
      sourceId: _valueOr<String?>(companion.sourceId, null),
      sourceBookUrl: _valueOr<String?>(companion.sourceBookUrl, null),
      localPath: _valueOr<String?>(companion.localPath, null),
      lastChapterIndex: _valueOr(companion.lastChapterIndex, 0),
      lastReadPosition: _valueOr(companion.lastReadPosition, 0),
      createdAt: _valueOr(companion.createdAt, DateTime(2026)),
      updatedAt: _valueOr(companion.updatedAt, DateTime(2026)),
      inShelf: _valueOr(companion.inShelf, true),
      sortOrder: _valueOr(companion.sortOrder, 0),
      remoteChapterCount: _valueOr<int?>(companion.remoteChapterCount, null),
      remoteNextTocUrl: _valueOr<String?>(companion.remoteNextTocUrl, null),
    );
  }

  Chapter _chapterFromCompanion(ChaptersCompanion companion) {
    return Chapter(
      id: companion.id.value,
      bookId: companion.bookId.value,
      chapterIndex: companion.chapterIndex.value,
      title: companion.title.value,
      url: _valueOr<String?>(companion.url, null),
      content: _valueOr<String?>(companion.content, null),
      normalizedContentLength: _valueOr(companion.normalizedContentLength, 0),
      isCached: _valueOr(companion.isCached, false),
      fetchedAt: _valueOr<DateTime?>(companion.fetchedAt, null),
    );
  }

  T _valueOr<T>(Value<T> value, T fallback) {
    return value.present ? value.value : fallback;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSourceRepository implements SourceRepository {
  const _FakeSourceRepository(this.source);

  final Source source;

  @override
  Future<Source?> findSourceById(String id) async =>
      id == source.id ? source : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PagedTocExecutor implements LegadoRequestExecutor {
  const _PagedTocExecutor();

  @override
  Future<LegadoHttpResponse> execute(LegadoRequest request) async {
    final uri = Uri.parse(request.url);
    final offset = int.tryParse(uri.queryParameters['more'] ?? '0') ?? 0;
    final page = offset <= 0
        ? [
            _chapter(1, 'Chapter 1'),
            _chapter(2, 'Chapter 2'),
          ]
        : [
            _chapter(3, 'Chapter 3'),
            _chapter(4, 'Chapter 4'),
          ];
    return LegadoHttpResponse(
      bytes: utf8.encode(jsonEncode({
        'totalCount': 4,
        'chapterlist': page,
      })),
      finalUri: uri,
      headers: Headers.fromMap({
        'content-type': ['application/json; charset=utf-8'],
      }),
      statusCode: 200,
    );
  }

  Map<String, Object?> _chapter(int id, String name) {
    return {
      'chapterid': '$id',
      'chaptername': name,
      'chapterurl': '/reader/$id',
      'isvip': 0,
    };
  }
}
