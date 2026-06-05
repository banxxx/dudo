import 'package:dudo/features/reader_engine/data/text_reader_book_repository.dart';
import 'package:dudo/features/reader_engine/data/text_reader_document_source.dart';
import 'package:dudo/features/reader_engine/domain/reader_content_block.dart';
import 'package:dudo/features/reader_engine/domain/reader_source_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeTextReaderBookRepository repository;
  late TextReaderDocumentSource source;

  setUp(() {
    repository = _FakeTextReaderBookRepository();
    source = TextReaderDocumentSource(repository);
  });

  test('loads document metadata from existing book and chapter tables',
      () async {
    repository.books['book-1'] = const ReaderBookRecord(
      id: 'book-1',
      title: '测试书',
      author: '作者',
      localPath: 'E:/books/test.txt',
    );
    repository.chapters['book-1'] = const [
      ReaderChapterRecord(
        id: 'chapter-1',
        bookId: 'book-1',
        chapterIndex: 0,
        title: '第一章',
        content: '第一段',
        isCached: true,
        normalizedContentLength: 3,
      ),
    ];

    final document = await source.loadDocument('book-1');

    expect(document.bookId, 'book-1');
    expect(document.title, '测试书');
    expect(document.sourceType, ReaderSourceType.localTxt);
    expect(document.chapterCount, 1);
    expect(document.metadata['author'], '作者');
  });

  test('loads chapter content as normalized reader chapter', () async {
    repository.books['book-1'] = const ReaderBookRecord(
      id: 'book-1',
      title: '测试书',
    );
    repository.chapters['book-1'] = const [
      ReaderChapterRecord(
        id: 'chapter-1',
        bookId: 'book-1',
        chapterIndex: 0,
        title: '第一章',
        content: '甲\r\n\r\n乙',
        isCached: true,
        normalizedContentLength: 4,
      ),
    ];

    final chapter = await source.loadChapter(
      bookId: 'book-1',
      chapterIndex: 0,
    );

    expect(chapter.id, 'chapter-1');
    expect(chapter.normalizedText, '甲\n\n乙');
    expect(chapter.textLength, 4);
    expect(chapter.blocks.first, isA<ReaderHeadingBlock>());
    expect(chapter.blocks.whereType<ReaderParagraphBlock>(), hasLength(2));
  });

  test('removes duplicated title from loaded chapter content', () async {
    repository.books['book-1'] = const ReaderBookRecord(
      id: 'book-1',
      title: 'Book',
    );
    repository.chapters['book-1'] = const [
      ReaderChapterRecord(
        id: 'chapter-1',
        bookId: 'book-1',
        chapterIndex: 0,
        title: 'Chapter 1',
        content: 'Chapter 1\nBody',
        isCached: true,
        normalizedContentLength: 4,
      ),
    ];

    final chapter = await source.loadChapter(
      bookId: 'book-1',
      chapterIndex: 0,
    );

    expect(chapter.normalizedText, 'Body');
    expect(
      chapter.blocks
          .whereType<ReaderParagraphBlock>()
          .map((block) => block.text),
      ['Body'],
    );
  });
}

class _FakeTextReaderBookRepository implements TextReaderBookRepository {
  final books = <String, ReaderBookRecord>{};
  final chapters = <String, List<ReaderChapterRecord>>{};

  @override
  Future<ReaderBookRecord?> fetchBookById(String bookId) async {
    return books[bookId];
  }

  @override
  Future<int> fetchChapterCount(String bookId) async {
    return chapters[bookId]?.length ?? 0;
  }

  @override
  Future<List<ReaderChapterRecord>> fetchChapterMetasPage({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    return (chapters[bookId] ?? const <ReaderChapterRecord>[])
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<ReaderChapterRecord?> fetchChapterAtIndex({
    required String bookId,
    required int chapterIndex,
  }) async {
    for (final chapter in chapters[bookId] ?? const <ReaderChapterRecord>[]) {
      if (chapter.chapterIndex == chapterIndex) return chapter;
    }
    return null;
  }
}
