import 'package:dudo/features/reader/domain/reader_paragraph_span.dart';
import 'package:dudo/features/reader/presentation/layout/reader_scroll_position_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderScrollPositionMapper', () {
    const style = TextStyle(fontSize: 18, height: 1.5);
    const spans = [
      ReaderParagraphSpan(index: 0, text: '第一段', startOffset: 0, endOffset: 3),
      ReaderParagraphSpan(
        index: 1,
        text: '第二段比较长一点',
        startOffset: 5,
        endOffset: 13,
      ),
      ReaderParagraphSpan(
          index: 2, text: '第三段', startOffset: 15, endOffset: 18),
    ];

    test('returns safe defaults for empty ranges', () {
      expect(
        ReaderScrollPositionMapper.readPositionForScrollOffset(
          ranges: const [],
          scrollOffset: 120,
        ),
        0,
      );
      expect(
        ReaderScrollPositionMapper.scrollOffsetForReadPosition(
          ranges: const [],
          readPosition: 9,
        ),
        0,
      );
    });

    test('builds cumulative paragraph layout ranges', () {
      final ranges = ReaderScrollPositionMapper.buildRanges(
        spans: spans,
        style: style,
        width: 220,
        paragraphSpacing: 12,
      );

      expect(ranges, hasLength(3));
      expect(ranges[0].paragraphIndex, 0);
      expect(ranges[0].startScrollOffset, 0);
      expect(ranges[1].startScrollOffset,
          greaterThan(ranges[0].startScrollOffset));
      expect(ranges[2].startScrollOffset,
          greaterThan(ranges[1].startScrollOffset));
    });

    test('maps later scroll offsets to later paragraph read positions', () {
      final ranges = ReaderScrollPositionMapper.buildRanges(
        spans: spans,
        style: style,
        width: 220,
        paragraphSpacing: 12,
      );

      expect(
        ReaderScrollPositionMapper.readPositionForScrollOffset(
          ranges: ranges,
          scrollOffset: 0,
        ),
        0,
      );
      expect(
        ReaderScrollPositionMapper.readPositionForScrollOffset(
          ranges: ranges,
          scrollOffset: ranges[1].startScrollOffset + 1,
        ),
        greaterThanOrEqualTo(5),
      );
    });

    test('maps saved read positions back to non-zero scroll offsets', () {
      final ranges = ReaderScrollPositionMapper.buildRanges(
        spans: spans,
        style: style,
        width: 220,
        paragraphSpacing: 12,
      );

      expect(
        ReaderScrollPositionMapper.scrollOffsetForReadPosition(
          ranges: ranges,
          readPosition: 0,
        ),
        0,
      );
      expect(
        ReaderScrollPositionMapper.scrollOffsetForReadPosition(
          ranges: ranges,
          readPosition: 15,
        ),
        greaterThan(0),
      );
    });

    test('clamps out-of-range positions', () {
      final ranges = ReaderScrollPositionMapper.buildRanges(
        spans: spans,
        style: style,
        width: 220,
        paragraphSpacing: 12,
      );

      expect(
        ReaderScrollPositionMapper.readPositionForScrollOffset(
          ranges: ranges,
          scrollOffset: -100,
        ),
        0,
      );
      expect(
        ReaderScrollPositionMapper.readPositionForScrollOffset(
          ranges: ranges,
          scrollOffset: ranges.last.endScrollOffset + 100,
        ),
        18,
      );
      expect(
        ReaderScrollPositionMapper.scrollOffsetForReadPosition(
          ranges: ranges,
          readPosition: -1,
        ),
        0,
      );
      expect(
        ReaderScrollPositionMapper.scrollOffsetForReadPosition(
          ranges: ranges,
          readPosition: 999,
        ),
        ranges.last.endScrollOffset,
      );
    });
  });
}
