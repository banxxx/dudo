import 'package:flutter/material.dart';

import '../../layout/reader_layout_hit_tester.dart';
import '../../layout/reader_line_layout_models.dart';

class ReaderPageHighlight {
  const ReaderPageHighlight({
    required this.range,
    required this.color,
    this.borderRadius = 4,
    this.padding = const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
  });

  final ReaderTextRange range;
  final Color color;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReaderPageHighlight &&
            other.range.chapterIndex == range.chapterIndex &&
            other.range.startOffset == range.startOffset &&
            other.range.endOffset == range.endOffset &&
            other.color == color &&
            other.borderRadius == borderRadius &&
            other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(
        range.chapterIndex,
        range.startOffset,
        range.endOffset,
        color,
        borderRadius,
        padding,
      );
}

class ReaderCanvasHighlightPainter {
  const ReaderCanvasHighlightPainter._();

  static void paintHighlights({
    required Canvas canvas,
    required ReaderPageLayout pageLayout,
    required List<ReaderPageHighlight> highlights,
  }) {
    if (highlights.isEmpty) return;

    for (final highlight in highlights) {
      final paint = Paint()..color = highlight.color;
      final radius = Radius.circular(highlight.borderRadius);
      final rects = ReaderLayoutHitTester.rectsForRange(
        page: pageLayout,
        range: highlight.range,
      );

      for (final rect in rects) {
        final paddedRect = highlight.padding.inflateRect(rect);
        final clippedRect = paddedRect.intersect(pageLayout.pageRect);
        if (clippedRect.isEmpty) continue;

        canvas.drawRRect(
          RRect.fromRectAndRadius(clippedRect, radius),
          paint,
        );
      }
    }
  }
}
