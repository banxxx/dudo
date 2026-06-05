import 'package:dudo/features/reader_engine/data/reader_content_parser.dart';
import 'package:dudo/features/reader_engine/domain/reader_content_block.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reader engine content parser', () {
    test('normalizes text with blank-line paragraph separators', () {
      expect(
        normalizeReaderEngineText('第一段\r\n\r\n 第二段 \n第三段'),
        '第一段\n\n第二段\n\n第三段',
      );
    });

    test('builds heading and paragraph blocks with stable offsets', () {
      final blocks = buildReaderContentBlocks(
        chapterIndex: 3,
        title: '第四章',
        content: 'A\nBCD',
      );

      expect(blocks, hasLength(3));
      expect(blocks[0], isA<ReaderHeadingBlock>());
      expect(blocks[0].blockId, 'c3-heading');

      final first = blocks[1] as ReaderParagraphBlock;
      final second = blocks[2] as ReaderParagraphBlock;
      expect(first.text, 'A');
      expect(first.startOffset, 0);
      expect(first.endOffset, 1);
      expect(second.text, 'BCD');
      expect(second.startOffset, 3);
      expect(second.endOffset, 6);
    });

    test('removes duplicate title paragraph from normalized text and blocks',
        () {
      final normalized = normalizeReaderEngineText(
        'Chapter 1\nBody one\nBody two',
        title: 'Chapter 1',
      );
      final blocks = buildReaderContentBlocks(
        chapterIndex: 0,
        title: 'Chapter 1',
        content: 'Chapter 1\nBody one\nBody two',
      );

      expect(normalized, 'Body one\n\nBody two');
      expect(
        blocks.whereType<ReaderParagraphBlock>().map((block) => block.text),
        ['Body one', 'Body two'],
      );
    });

    test('removes near duplicate title paragraph with punctuation', () {
      final paragraphs = readerEngineParagraphsForChapter(
        title: 'Chapter 1',
        content: 'Chapter 1:\nBody',
      );

      expect(paragraphs, ['Body']);
    });
  });
}
