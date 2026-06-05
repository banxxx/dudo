import 'dart:math' as math;

import '../domain/reader_location.dart';
import 'reader_layout_models.dart';

class ReaderPositionMapper {
  const ReaderPositionMapper._();

  static ReaderLocation locationForScrollOffset({
    required String bookId,
    required ReaderChapterLayout layout,
    required double scrollOffset,
  }) {
    final blocks = layout.blockLayouts;
    if (blocks.isEmpty) {
      return ReaderLocation.startOfChapter(
        bookId: bookId,
        chapterIndex: layout.chapterIndex,
      );
    }

    final clampedScroll = scrollOffset.clamp(0.0, layout.contentHeight);
    final block = blocks.firstWhere(
      (block) => block.containsScrollOffset(clampedScroll),
      orElse: () => clampedScroll <= 0 ? blocks.first : blocks.last,
    );
    final offset = _textOffsetForBlockScroll(block, clampedScroll);
    return ReaderLocation(
      bookId: bookId,
      chapterIndex: layout.chapterIndex,
      offset: offset,
      blockId: block.blockId,
    );
  }

  static double scrollOffsetForLocation({
    required ReaderChapterLayout layout,
    required ReaderLocation location,
  }) {
    final blocks = layout.blockLayouts;
    if (blocks.isEmpty) return 0;

    final block = blocks.firstWhere(
      (block) => block.containsOffset(location.offset),
      orElse: () {
        if (location.offset <= blocks.first.textStartOffset) {
          return blocks.first;
        }
        return blocks.last;
      },
    );
    return _scrollForBlockTextOffset(block, location.offset)
        .clamp(0.0, layout.contentHeight);
  }

  static int pageIndexForLocation({
    required ReaderChapterLayout layout,
    required ReaderLocation location,
  }) {
    if (layout.pages.isEmpty) return 0;
    final page = layout.pages.firstWhere(
      (page) =>
          location.offset >= page.start.offset &&
          location.offset <= page.end.offset,
      orElse: () {
        if (location.offset <= layout.pages.first.start.offset) {
          return layout.pages.first;
        }
        return layout.pages.last;
      },
    );
    return page.pageIndex;
  }

  static int _textOffsetForBlockScroll(
    ReaderBlockLayout block,
    double scrollOffset,
  ) {
    final textLength = block.textEndOffset - block.textStartOffset;
    if (textLength <= 0 || block.scrollEnd <= block.scrollStart) {
      return block.textStartOffset;
    }
    final ratio = ((scrollOffset - block.scrollStart) /
            (block.scrollEnd - block.scrollStart))
        .clamp(0.0, 1.0);
    return block.textStartOffset + (textLength * ratio).round();
  }

  static double _scrollForBlockTextOffset(
    ReaderBlockLayout block,
    int textOffset,
  ) {
    final textLength = block.textEndOffset - block.textStartOffset;
    if (textLength <= 0 || block.scrollEnd <= block.scrollStart) {
      return block.scrollStart;
    }
    final ratio = math.max(
          0,
          math.min(textLength, textOffset - block.textStartOffset),
        ) /
        textLength;
    return block.scrollStart + (block.scrollEnd - block.scrollStart) * ratio;
  }
}
