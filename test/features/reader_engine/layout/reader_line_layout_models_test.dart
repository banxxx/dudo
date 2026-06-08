import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_line_layout_models.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderTextRange', () {
    test('uses half-open offsets for containment', () {
      const range = ReaderTextRange(
        chapterIndex: 2,
        startOffset: 10,
        endOffset: 20,
      );

      expect(range.length, 10);
      expect(range.containsOffset(10), isTrue);
      expect(range.containsOffset(19), isTrue);
      expect(range.containsOffset(20), isFalse);
    });

    test('intersects ranges within the same chapter only', () {
      const range = ReaderTextRange(
        chapterIndex: 0,
        startOffset: 10,
        endOffset: 20,
      );

      expect(
        range.intersection(
          const ReaderTextRange(
            chapterIndex: 0,
            startOffset: 15,
            endOffset: 25,
          ),
        ),
        isA<ReaderTextRange>()
            .having((value) => value.startOffset, 'startOffset', 15)
            .having((value) => value.endOffset, 'endOffset', 20),
      );
      expect(
        range.intersection(
          const ReaderTextRange(
            chapterIndex: 1,
            startOffset: 15,
            endOffset: 25,
          ),
        ),
        isNull,
      );
    });
  });

  group('ReaderLayoutSettings', () {
    test('derives reader defaults and includes advanced layout fields', () {
      final settings = ReaderLayoutSettings.fromReaderSettings(
        ReaderSettings.defaults(),
      );

      expect(settings.firstLineIndent, ReaderSettings.defaults().fontSize * 2);
      expect(settings.enableKinsoku, isTrue);
      expect(settings.enableJustify, isFalse);
      expect(settings.textEnhancementEnabled, isFalse);

      final disabledIndent = ReaderLayoutSettings.fromReaderSettings(
        ReaderSettings.defaults().copyWith(firstLineIndentEnabled: false),
      );
      expect(disabledIndent.firstLineIndent, 0);

      final enhanced = ReaderLayoutSettings.fromReaderSettings(
        ReaderSettings.defaults().copyWith(textEnhancementEnabled: true),
      );
      expect(enhanced.textEnhancementEnabled, isTrue);
      expect(enhanced.digest, isNot(settings.digest));

      final justified = settings.copyWith(
        enableJustify: true,
        textAlign: ReaderTextAlign.justify,
      );
      expect(justified.digest, isNot(settings.digest));
    });
  });

  group('ReaderPageLayout', () {
    test('exposes all laid out lines from page blocks', () {
      const style = TextStyle(fontSize: 18);
      const textRange = ReaderTextRange(
        chapterIndex: 0,
        startOffset: 0,
        endOffset: 4,
      );
      const line = ReaderLineLayout(
        textRange: textRange,
        x: 12,
        y: 24,
        width: 80,
        height: 30,
        baseline: 46,
        isFirstLineOfBlock: true,
        isLastLineOfBlock: true,
        isLastLineOfParagraph: true,
        align: ReaderTextAlign.start,
        runs: [
          ReaderTextRunLayout(
            textRange: textRange,
            text: '测试文本',
            x: 12,
            baseline: 46,
            width: 80,
            style: style,
          ),
        ],
      );
      const block = ReaderPageBlockLayout(
        blockId: 'block-1',
        type: ReaderPageBlockType.paragraph,
        chapterIndex: 0,
        textRange: textRange,
        rect: Rect.fromLTWH(12, 24, 80, 30),
        style: style,
        lines: [line],
        isFirstFragmentOfBlock: true,
        isLastFragmentOfBlock: true,
      );
      const page = ReaderPageLayout(
        chapterIndex: 0,
        pageIndex: 0,
        pageRect: Rect.fromLTWH(0, 0, 320, 640),
        contentRect: Rect.fromLTWH(24, 28, 272, 584),
        start: ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 0,
          offset: 0,
        ),
        end: ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 0,
          offset: 4,
        ),
        blocks: [block],
      );

      expect(page.lines, contains(line));
      expect(line.rect, const Rect.fromLTWH(12, 24, 80, 30));
    });
  });
}
