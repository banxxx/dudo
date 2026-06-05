import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../shared/theme/app_fonts.dart';
import '../domain/reader_chapter.dart';
import '../domain/reader_content_block.dart';
import '../domain/reader_location.dart';
import '../domain/reader_settings.dart';
import 'reader_layout_models.dart';
import 'reader_text_measure.dart';

abstract interface class ReaderLayoutEngine {
  Future<ReaderChapterLayout> layoutChapter({
    required ReaderChapter chapter,
    required ReaderSettings settings,
    required Size viewportSize,
  });
}

class FlutterReaderLayoutEngine implements ReaderLayoutEngine {
  const FlutterReaderLayoutEngine({
    this.textMeasure = const FlutterReaderTextMeasure(),
  });

  final ReaderTextMeasure textMeasure;

  @override
  Future<ReaderChapterLayout> layoutChapter({
    required ReaderChapter chapter,
    required ReaderSettings settings,
    required Size viewportSize,
  }) async {
    final contentWidth =
        math.max(1.0, viewportSize.width - settings.pagePadding.horizontal);
    final pageHeight =
        math.max(1.0, viewportSize.height - settings.pagePadding.vertical);
    final blockLayouts = <ReaderBlockLayout>[];
    final pages = <ReaderPageSlice>[];
    final pageBlocks = <ReaderContentBlock>[];

    var scrollOffset = 0.0;
    var pageIndex = 0;
    var pageStartOffset = 0;
    var pageEndOffset = 0;
    var pageStartLocation = ReaderLocation.startOfChapter(
      bookId: chapter.bookId,
      chapterIndex: chapter.index,
    );

    for (final block in chapter.blocks) {
      final blockHeight = _measureBlock(
        block: block,
        settings: settings,
        maxWidth: contentWidth,
      );

      if (pageBlocks.isNotEmpty &&
          scrollOffset + blockHeight - pageIndex * pageHeight > pageHeight) {
        pages.add(
          _buildPageSlice(
            chapter: chapter,
            pageIndex: pageIndex,
            startOffset: pageStartOffset,
            endOffset: pageEndOffset,
            start: pageStartLocation,
            blocks: List.unmodifiable(pageBlocks),
          ),
        );
        pageIndex += 1;
        pageBlocks.clear();
        pageStartOffset = _blockStartOffset(block);
        pageStartLocation = ReaderLocation(
          bookId: chapter.bookId,
          chapterIndex: chapter.index,
          offset: pageStartOffset,
          blockId: block.blockId,
        );
      }

      final scrollStart = scrollOffset;
      final scrollEnd = scrollStart + blockHeight;
      blockLayouts.add(
        ReaderBlockLayout(
          blockId: block.blockId,
          chapterIndex: chapter.index,
          textStartOffset: block.startOffset,
          textEndOffset: block.endOffset,
          scrollStart: scrollStart,
          scrollEnd: scrollEnd,
          pageIndex: pageIndex,
        ),
      );
      pageBlocks.add(block);
      pageEndOffset = _blockEndOffset(block);
      scrollOffset = scrollEnd;
    }

    if (pageBlocks.isNotEmpty || pages.isEmpty) {
      pages.add(
        _buildPageSlice(
          chapter: chapter,
          pageIndex: pageIndex,
          startOffset: pageStartOffset,
          endOffset: pageEndOffset,
          start: pageStartLocation,
          blocks: List.unmodifiable(pageBlocks),
        ),
      );
    }

    return ReaderChapterLayout(
      chapterIndex: chapter.index,
      revision: ReaderLayoutRevision(
        contentHash: chapter.normalizedText.hashCode,
        settingsDigest: _settingsDigest(settings, viewportSize),
      ),
      contentHeight: scrollOffset,
      blockLayouts: List.unmodifiable(blockLayouts),
      pages: List.unmodifiable(pages),
    );
  }

  double _measureBlock({
    required ReaderContentBlock block,
    required ReaderSettings settings,
    required double maxWidth,
  }) {
    final style = switch (block) {
      ReaderHeadingBlock() => DudoTextStyles.serif(
          fontSize: settings.fontSize * (24 / 19),
          height: settings.lineHeight,
          fontWeight: FontWeight.w600,
        ),
      ReaderParagraphBlock() => DudoTextStyles.serif(
          fontSize: settings.fontSize,
          height: settings.lineHeight,
          letterSpacing: 0.4,
        ),
      ReaderImageBlock() => DudoTextStyles.serif(
          fontSize: settings.fontSize,
          height: settings.lineHeight,
        ),
    };
    final text = switch (block) {
      ReaderHeadingBlock(:final text) => text,
      ReaderParagraphBlock(:final text) => text,
      ReaderImageBlock(:final alt) => alt ?? '',
    };
    final measured = textMeasure.measureHeight(
      text: text,
      style: style,
      maxWidth: maxWidth,
    );
    return measured + settings.paragraphSpacing;
  }

  ReaderPageSlice _buildPageSlice({
    required ReaderChapter chapter,
    required int pageIndex,
    required int startOffset,
    required int endOffset,
    required ReaderLocation start,
    required List<ReaderContentBlock> blocks,
  }) {
    return ReaderPageSlice(
      chapterIndex: chapter.index,
      pageIndex: pageIndex,
      start: start,
      end: ReaderLocation(
        bookId: chapter.bookId,
        chapterIndex: chapter.index,
        offset: endOffset,
      ),
      blocks: blocks,
    );
  }

  int _blockStartOffset(ReaderContentBlock block) {
    return block.startOffset;
  }

  int _blockEndOffset(ReaderContentBlock block) {
    return block.endOffset;
  }

  String _settingsDigest(ReaderSettings settings, Size viewportSize) {
    return [
      settings.paletteId,
      settings.fontFamily,
      settings.fontSize,
      settings.lineHeight,
      settings.brightness,
      settings.turnMode.name,
      settings.paragraphSpacing,
      settings.pagePadding.left,
      settings.pagePadding.top,
      settings.pagePadding.right,
      settings.pagePadding.bottom,
      viewportSize.width,
      viewportSize.height,
    ].join('|');
  }
}
