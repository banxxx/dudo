import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/reader_paragraph_span.dart';

class ReaderParagraphLayoutRange {
  const ReaderParagraphLayoutRange({
    required this.paragraphIndex,
    required this.startScrollOffset,
    required this.endScrollOffset,
    required this.textStartOffset,
    required this.textEndOffset,
  });

  final int paragraphIndex;
  final double startScrollOffset;
  final double endScrollOffset;
  final int textStartOffset;
  final int textEndOffset;

  double get scrollExtent => endScrollOffset - startScrollOffset;
  int get textLength => textEndOffset - textStartOffset;
}

class ReaderScrollPositionMapper {
  const ReaderScrollPositionMapper._();

  static List<ReaderParagraphLayoutRange> buildRanges({
    required List<ReaderParagraphSpan> spans,
    required TextStyle style,
    required double width,
    required double paragraphSpacing,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final ranges = <ReaderParagraphLayoutRange>[];
    var scrollOffset = 0.0;
    for (final span in spans) {
      final painter = TextPainter(
        text: TextSpan(text: span.text, style: style),
        textDirection: textDirection,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: width);
      final spacing = span.index + 1 == spans.length ? 0.0 : paragraphSpacing;
      final endScrollOffset = scrollOffset + painter.height + spacing;
      ranges.add(
        ReaderParagraphLayoutRange(
          paragraphIndex: span.index,
          startScrollOffset: scrollOffset,
          endScrollOffset: endScrollOffset,
          textStartOffset: span.startOffset,
          textEndOffset: span.endOffset,
        ),
      );
      scrollOffset = endScrollOffset;
    }
    return ranges;
  }

  static int readPositionForScrollOffset({
    required List<ReaderParagraphLayoutRange> ranges,
    required double scrollOffset,
  }) {
    if (ranges.isEmpty) return 0;
    if (scrollOffset <= ranges.first.startScrollOffset) {
      return ranges.first.textStartOffset;
    }
    if (scrollOffset >= ranges.last.endScrollOffset) {
      return ranges.last.textEndOffset;
    }

    final range = _rangeForScrollOffset(ranges, scrollOffset);
    final scrollExtent = math.max(range.scrollExtent, 1.0);
    final ratio = ((scrollOffset - range.startScrollOffset) / scrollExtent)
        .clamp(0.0, 1.0);
    return (range.textStartOffset + range.textLength * ratio)
        .round()
        .clamp(range.textStartOffset, range.textEndOffset)
        .toInt();
  }

  static double scrollOffsetForReadPosition({
    required List<ReaderParagraphLayoutRange> ranges,
    required int readPosition,
  }) {
    if (ranges.isEmpty) return 0;
    if (readPosition <= ranges.first.textStartOffset) {
      return ranges.first.startScrollOffset;
    }
    if (readPosition >= ranges.last.textEndOffset) {
      return ranges.last.endScrollOffset;
    }

    final range = _rangeForReadPosition(ranges, readPosition);
    final textLength = math.max(range.textLength, 1);
    final ratio =
        ((readPosition - range.textStartOffset) / textLength).clamp(0.0, 1.0);
    return range.startScrollOffset + range.scrollExtent * ratio;
  }

  static ReaderParagraphLayoutRange _rangeForScrollOffset(
    List<ReaderParagraphLayoutRange> ranges,
    double scrollOffset,
  ) {
    var low = 0;
    var high = ranges.length - 1;
    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      final range = ranges[mid];
      if (scrollOffset < range.startScrollOffset) {
        high = mid - 1;
      } else if (scrollOffset > range.endScrollOffset) {
        low = mid + 1;
      } else {
        return range;
      }
    }
    return ranges[low.clamp(0, ranges.length - 1)];
  }

  static ReaderParagraphLayoutRange _rangeForReadPosition(
    List<ReaderParagraphLayoutRange> ranges,
    int readPosition,
  ) {
    var low = 0;
    var high = ranges.length - 1;
    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      final range = ranges[mid];
      if (readPosition < range.textStartOffset) {
        high = mid - 1;
      } else if (readPosition > range.textEndOffset) {
        low = mid + 1;
      } else {
        return range;
      }
    }
    return ranges[low.clamp(0, ranges.length - 1)];
  }
}
