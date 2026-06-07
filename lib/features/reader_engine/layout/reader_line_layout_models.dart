import 'package:flutter/painting.dart';

import '../domain/reader_location.dart';
import 'reader_layout_settings.dart';
import 'reader_layout_models.dart';

class ReaderLineChapterLayout {
  const ReaderLineChapterLayout({
    required this.chapterIndex,
    required this.revision,
    required this.viewportSize,
    required this.contentRect,
    required this.pages,
    required this.blocks,
    required this.contentHeight,
  });

  final int chapterIndex;
  final ReaderLayoutRevision revision;
  final Size viewportSize;
  final Rect contentRect;
  final List<ReaderPageLayout> pages;
  final List<ReaderPageBlockLayout> blocks;
  final double contentHeight;
}

class ReaderTextRange {
  const ReaderTextRange({
    required this.chapterIndex,
    required this.startOffset,
    required this.endOffset,
  }) : assert(endOffset >= startOffset);

  final int chapterIndex;
  final int startOffset;
  final int endOffset;

  int get length => endOffset - startOffset;

  bool get isCollapsed => startOffset == endOffset;

  bool containsOffset(int offset) {
    return offset >= startOffset && offset < endOffset;
  }

  bool intersects(ReaderTextRange other) {
    if (chapterIndex != other.chapterIndex) return false;
    return startOffset < other.endOffset && other.startOffset < endOffset;
  }

  ReaderTextRange? intersection(ReaderTextRange other) {
    if (!intersects(other)) return null;
    return ReaderTextRange(
      chapterIndex: chapterIndex,
      startOffset:
          startOffset > other.startOffset ? startOffset : other.startOffset,
      endOffset: endOffset < other.endOffset ? endOffset : other.endOffset,
    );
  }
}

enum ReaderPageBlockType {
  heading,
  paragraph,
  image,
}

class ReaderTextRunLayout {
  const ReaderTextRunLayout({
    required this.textRange,
    required this.text,
    required this.x,
    required this.baseline,
    required this.width,
    required this.style,
    this.glyphAdvances,
  });

  final ReaderTextRange textRange;
  final String text;
  final double x;
  final double baseline;
  final double width;
  final TextStyle style;
  final List<double>? glyphAdvances;
}

class ReaderLineLayout {
  const ReaderLineLayout({
    required this.textRange,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.baseline,
    required this.isFirstLineOfBlock,
    required this.isLastLineOfBlock,
    required this.isLastLineOfParagraph,
    required this.align,
    required this.runs,
  });

  final ReaderTextRange textRange;
  final double x;
  final double y;
  final double width;
  final double height;
  final double baseline;
  final bool isFirstLineOfBlock;
  final bool isLastLineOfBlock;
  final bool isLastLineOfParagraph;
  final ReaderTextAlign align;
  final List<ReaderTextRunLayout> runs;

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

class ReaderPageBlockLayout {
  const ReaderPageBlockLayout({
    required this.blockId,
    required this.type,
    required this.chapterIndex,
    required this.textRange,
    required this.rect,
    required this.style,
    required this.lines,
    required this.isFirstFragmentOfBlock,
    required this.isLastFragmentOfBlock,
  });

  final String blockId;
  final ReaderPageBlockType type;
  final int chapterIndex;
  final ReaderTextRange textRange;
  final Rect rect;
  final TextStyle style;
  final List<ReaderLineLayout> lines;
  final bool isFirstFragmentOfBlock;
  final bool isLastFragmentOfBlock;
}

class ReaderPageLayout {
  const ReaderPageLayout({
    required this.chapterIndex,
    required this.pageIndex,
    required this.pageRect,
    required this.contentRect,
    required this.start,
    required this.end,
    required this.blocks,
  });

  final int chapterIndex;
  final int pageIndex;
  final Rect pageRect;
  final Rect contentRect;
  final ReaderLocation start;
  final ReaderLocation end;
  final List<ReaderPageBlockLayout> blocks;

  Iterable<ReaderLineLayout> get lines sync* {
    for (final block in blocks) {
      yield* block.lines;
    }
  }
}
