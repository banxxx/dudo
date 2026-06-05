import 'package:dudo/features/reader_engine/data/epub_reader_document_source.dart';
import 'package:dudo/features/reader_engine/domain/reader_content_block.dart';
import 'package:dudo/features/reader_engine/domain/reader_source_type.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EpubReaderDocumentSource maps epub chapters into reader chapters',
      () async {
    final source = EpubReaderDocumentSource(
      loader: _FakeEpubBookLoader(_book()),
    );

    final document = await source.loadDocument('epub-1');
    final metas = await source.loadChapterMetas(
      bookId: 'epub-1',
      offset: 0,
      limit: 10,
    );
    final chapter = await source.loadChapter(
      bookId: 'epub-1',
      chapterIndex: 0,
    );

    expect(document.title, 'EPUB 测试书');
    expect(document.sourceType, ReaderSourceType.epub);
    expect(document.chapterCount, 1);
    expect(metas.items.single.title, '第一章');
    expect(chapter.title, '第一章');
    expect(chapter.metadata['epubHref'], 'chapter1.xhtml');
    expect(chapter.normalizedText, '第一段\n\n第二段');
    expect(chapter.blocks.first, isA<ReaderHeadingBlock>());

    final paragraphs =
        chapter.blocks.whereType<ReaderParagraphBlock>().toList();
    expect(paragraphs, hasLength(2));
    expect(paragraphs.first.startOffset, 0);
    expect(paragraphs.first.endOffset, 3);
    expect(paragraphs.last.startOffset, 5);
    expect(paragraphs.last.endOffset, 8);
  });
}

EpubBook _book() {
  final chapter = EpubChapter()
    ..Title = '第一章'
    ..ContentFileName = 'chapter1.xhtml'
    ..HtmlContent = '<html><body><h1>第一章</h1><p>第一段</p><p>第二段</p></body></html>'
    ..SubChapters = [];
  return EpubBook()
    ..Title = 'EPUB 测试书'
    ..Author = '作者'
    ..Chapters = [chapter];
}

class _FakeEpubBookLoader implements EpubBookLoader {
  const _FakeEpubBookLoader(this.book);

  final EpubBook book;

  @override
  Future<EpubBook> load(String bookId) async => book;
}
