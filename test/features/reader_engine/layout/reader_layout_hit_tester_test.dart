import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_hit_tester.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_line_layout_models.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderLayoutHitTester', () {
    test('maps points to reader locations within a line', () {
      final page = _pageLayout();

      final lineStart = ReaderLayoutHitTester.locationForPoint(
        page: page,
        point: const Offset(10, 12),
      );
      final lineMiddle = ReaderLayoutHitTester.locationForPoint(
        page: page,
        point: const Offset(47, 12),
      );
      final lineEnd = ReaderLayoutHitTester.locationForPoint(
        page: page,
        point: const Offset(220, 12),
      );

      expect(lineStart.offset, 0);
      expect(lineStart.blockId, 'paragraph-0');
      expect(lineMiddle.offset, greaterThan(0));
      expect(lineMiddle.offset, lessThan(6));
      expect(lineEnd.offset, 6);
    });

    test('maps vertical gaps to the nearest line', () {
      final page = _pageLayout();

      final above = ReaderLayoutHitTester.locationForPoint(
        page: page,
        point: const Offset(10, -20),
      );
      final below = ReaderLayoutHitTester.locationForPoint(
        page: page,
        point: const Offset(10, 120),
      );

      expect(above.offset, 0);
      expect(below.offset, 6);
    });

    test('returns text rects for ranges across lines', () {
      final page = _pageLayout();

      final rects = ReaderLayoutHitTester.rectsForRange(
        page: page,
        range: const ReaderTextRange(
          chapterIndex: 0,
          startOffset: 2,
          endOffset: 8,
        ),
      );

      expect(rects, hasLength(2));
      expect(rects.first.left, greaterThanOrEqualTo(10));
      expect(rects.first.top, greaterThanOrEqualTo(0));
      expect(rects.first.bottom, lessThanOrEqualTo(28));
      expect(rects.last.top, greaterThanOrEqualTo(32));
      expect(rects.every((rect) => rect.width > 0), isTrue);
    });

    test('ignores ranges from other chapters and collapsed ranges', () {
      final page = _pageLayout();

      expect(
        ReaderLayoutHitTester.rectsForRange(
          page: page,
          range: const ReaderTextRange(
            chapterIndex: 1,
            startOffset: 0,
            endOffset: 2,
          ),
        ),
        isEmpty,
      );
      expect(
        ReaderLayoutHitTester.rectsForRange(
          page: page,
          range: const ReaderTextRange(
            chapterIndex: 0,
            startOffset: 2,
            endOffset: 2,
          ),
        ),
        isEmpty,
      );
    });
  });
}

ReaderPageLayout _pageLayout() {
  const style = TextStyle(fontSize: 18, decoration: TextDecoration.none);
  final firstLine = _line(
    text: 'abcdef',
    startOffset: 0,
    endOffset: 6,
    y: 0,
    style: style,
  );
  final secondLine = _line(
    text: 'ghijkl',
    startOffset: 6,
    endOffset: 12,
    y: 32,
    style: style,
  );
  const blockRange = ReaderTextRange(
    chapterIndex: 0,
    startOffset: 0,
    endOffset: 12,
  );
  return ReaderPageLayout(
    chapterIndex: 0,
    pageIndex: 0,
    pageRect: const Rect.fromLTWH(0, 0, 240, 160),
    contentRect: const Rect.fromLTWH(10, 0, 220, 160),
    start: const ReaderLocation(
      bookId: 'book-1',
      chapterIndex: 0,
      offset: 0,
    ),
    end: const ReaderLocation(
      bookId: 'book-1',
      chapterIndex: 0,
      offset: 12,
    ),
    blocks: [
      ReaderPageBlockLayout(
        blockId: 'paragraph-0',
        type: ReaderPageBlockType.paragraph,
        chapterIndex: 0,
        textRange: blockRange,
        rect: const Rect.fromLTWH(10, 0, 80, 60),
        style: style,
        lines: [firstLine, secondLine],
        isFirstFragmentOfBlock: true,
        isLastFragmentOfBlock: true,
      ),
    ],
  );
}

ReaderLineLayout _line({
  required String text,
  required int startOffset,
  required int endOffset,
  required double y,
  required TextStyle style,
}) {
  final width = _textWidth(text, style);
  final range = ReaderTextRange(
    chapterIndex: 0,
    startOffset: startOffset,
    endOffset: endOffset,
  );
  return ReaderLineLayout(
    textRange: range,
    x: 10,
    y: y,
    width: width,
    height: 28,
    baseline: y + 22,
    isFirstLineOfBlock: startOffset == 0,
    isLastLineOfBlock: endOffset == 12,
    isLastLineOfParagraph: endOffset == 12,
    align: ReaderTextAlign.start,
    runs: [
      ReaderTextRunLayout(
        textRange: range,
        text: text,
        x: 10,
        baseline: y + 22,
        width: width,
        style: style,
      ),
    ],
  );
}

double _textWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width;
}
