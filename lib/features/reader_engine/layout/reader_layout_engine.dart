import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../shared/theme/app_fonts.dart';
import '../domain/reader_chapter.dart';
import '../domain/reader_content_block.dart';
import '../domain/reader_location.dart';
import '../domain/reader_settings.dart';
import '../domain/reader_turn_mode.dart';
import 'reader_layout_models.dart';
import 'reader_layout_settings.dart';
import 'reader_line_layout_engine.dart';
import 'reader_line_layout_models.dart';
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
    if (settings.turnMode != ReaderTurnMode.scroll) {
      return _layoutChapterWithLinePages(
        chapter: chapter,
        settings: settings,
        viewportSize: viewportSize,
      );
    }

    final contentWidth =
    math.max(1.0, viewportSize.width - settings.pagePadding.horizontal);
    final pageHeight =
    math.max(1.0, viewportSize.height - settings.pagePadding.vertical);
    final blockLayouts = <ReaderBlockLayout>[];
    final pages = <ReaderPageSlice>[];
    final pageBlocks = <ReaderContentBlock>[];

    var scrollOffset = 0.0;
    var pageIndex = 0;
    var pageContentHeight = 0.0;
    var pageStartOffset = 0;
    var pageEndOffset = 0;
    var pageStartLocation = ReaderLocation.startOfChapter(
      bookId: chapter.bookId,
      chapterIndex: chapter.index,
    );

    void startPageAt(ReaderContentBlock block) {
      if (pageBlocks.isNotEmpty) return;
      pageStartOffset = _blockStartOffset(block);
      pageStartLocation = ReaderLocation(
        bookId: chapter.bookId,
        chapterIndex: chapter.index,
        offset: pageStartOffset,
        blockId: block.blockId,
      );
    }

    void finishPage() {
      if (pageBlocks.isEmpty) return;
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
      pageContentHeight = 0;
      pageBlocks.clear();
    }

    for (final block in chapter.blocks) {
      if (block is ReaderParagraphBlock) {
        final blockHeight = _measureBlock(
          block: block,
          settings: settings,
          maxWidth: contentWidth,
        );
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

        var localStart = 0;
        while (localStart < block.text.length) {
          final remainingText = block.text.substring(localStart);
          final remainingHeight = _measureText(
            text: remainingText,
            style: _styleForBlock(block, settings),
            maxWidth: contentWidth,
          ) +
              settings.paragraphSpacing;
          var availableHeight = pageHeight - pageContentHeight;

          if (remainingHeight > availableHeight && pageBlocks.isNotEmpty) {
            final fittingLength = _maxTextPrefixThatFits(
              text: remainingText,
              style: _styleForBlock(block, settings),
              maxWidth: contentWidth,
              maxHeight: availableHeight,
            );
            if (fittingLength <= 0) {
              finishPage();
              continue;
            }

            final fragment = _paragraphFragment(
              block: block,
              localStart: localStart,
              localEnd: localStart + fittingLength,
              addBottomSpacing: false,
            );
            startPageAt(fragment);
            final fragmentHeight = _measureBlock(
              block: fragment,
              settings: settings,
              maxWidth: contentWidth,
            );
            pageBlocks.add(fragment);
            pageContentHeight += fragmentHeight;
            pageEndOffset = _blockEndOffset(fragment);
            localStart += fittingLength;
            finishPage();
            continue;
          }

          if (remainingHeight <= availableHeight) {
            final fragment = _paragraphFragment(
              block: block,
              localStart: localStart,
              localEnd: block.text.length,
              addBottomSpacing: true,
            );
            startPageAt(fragment);
            pageBlocks.add(fragment);
            pageContentHeight += remainingHeight;
            pageEndOffset = _blockEndOffset(fragment);
            localStart = block.text.length;
            continue;
          }

          availableHeight = pageHeight;
          final fittingLength = _maxTextPrefixThatFits(
            text: remainingText,
            style: _styleForBlock(block, settings),
            maxWidth: contentWidth,
            maxHeight: availableHeight,
          );
          final safeLength = math.max(1, fittingLength);
          final fragment = _paragraphFragment(
            block: block,
            localStart: localStart,
            localEnd: math.min(block.text.length, localStart + safeLength),
            addBottomSpacing: localStart + safeLength >= block.text.length,
          );
          startPageAt(fragment);
          final fragmentHeight = _measureBlock(
            block: fragment,
            settings: settings,
            maxWidth: contentWidth,
          );
          pageBlocks.add(fragment);
          pageContentHeight += fragmentHeight;
          pageEndOffset = _blockEndOffset(fragment);
          localStart = fragment.endOffset - block.startOffset;
          if (localStart < block.text.length) {
            finishPage();
          }
        }
        scrollOffset = scrollEnd;
        continue;
      }

      final blockHeight = _measureBlock(
        block: block,
        settings: settings,
        maxWidth: contentWidth,
      );

      if (pageBlocks.isNotEmpty &&
          pageContentHeight + blockHeight > pageHeight) {
        finishPage();
      }

      startPageAt(block);
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
      pageContentHeight += blockHeight;
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

  Future<ReaderChapterLayout> _layoutChapterWithLinePages({
    required ReaderChapter chapter,
    required ReaderSettings settings,
    required Size viewportSize,
  }) async {
    final lineLayout =
    await const FlutterReaderLineLayoutEngine().layoutChapter(
      chapter: chapter,
      settings: ReaderLayoutSettings.fromReaderSettings(settings),
      viewportSize: viewportSize,
    );
    final pages = [
      for (final page in lineLayout.pages)
        _buildLineBackedPageSlice(
          chapter: chapter,
          page: page,
        ),
    ];

    return ReaderChapterLayout(
      chapterIndex: chapter.index,
      revision: ReaderLayoutRevision(
        contentHash: chapter.normalizedText.hashCode,
        settingsDigest: _settingsDigest(settings, viewportSize),
      ),
      contentHeight: lineLayout.contentHeight,
      blockLayouts: _blockLayoutsFromLineLayout(
        chapter: chapter,
        lineLayout: lineLayout,
      ),
      pages: List.unmodifiable(pages),
    );
  }

  List<ReaderBlockLayout> _blockLayoutsFromLineLayout({
    required ReaderChapter chapter,
    required ReaderLineChapterLayout lineLayout,
  }) {
    final pageContentHeight = lineLayout.contentRect.height;
    final fragmentsByBlockId = <String, List<_LineBlockFragment>>{};
    for (final page in lineLayout.pages) {
      for (final block in page.blocks) {
        fragmentsByBlockId
            .putIfAbsent(block.blockId, () => <_LineBlockFragment>[])
            .add(_LineBlockFragment(pageIndex: page.pageIndex, layout: block));
      }
    }

    return [
      for (final block in chapter.blocks)
        if (block.length > 0)
          _blockLayoutFromLineFragments(
            block: block,
            fragments: fragmentsByBlockId[block.blockId] ??
                const <_LineBlockFragment>[],
            pageContentHeight: pageContentHeight,
          ),
    ];
  }

  ReaderBlockLayout _blockLayoutFromLineFragments({
    required ReaderContentBlock block,
    required List<_LineBlockFragment> fragments,
    required double pageContentHeight,
  }) {
    if (fragments.isEmpty) {
      return ReaderBlockLayout(
        blockId: block.blockId,
        chapterIndex: block.chapterIndex,
        textStartOffset: block.startOffset,
        textEndOffset: block.endOffset,
        scrollStart: 0,
        scrollEnd: 0,
        pageIndex: 0,
      );
    }

    final first = fragments.first;
    final last = fragments.last;
    final scrollStart =
        first.pageIndex * pageContentHeight + first.layout.rect.top;
    final scrollEnd =
        last.pageIndex * pageContentHeight + last.layout.rect.bottom;
    return ReaderBlockLayout(
      blockId: block.blockId,
      chapterIndex: block.chapterIndex,
      textStartOffset: block.startOffset,
      textEndOffset: block.endOffset,
      scrollStart: scrollStart,
      scrollEnd: math.max(scrollStart, scrollEnd),
      pageIndex: first.pageIndex,
    );
  }

  ReaderPageSlice _buildLineBackedPageSlice({
    required ReaderChapter chapter,
    required ReaderPageLayout page,
  }) {
    final sourceBlocks = {
      for (final block in chapter.blocks) block.blockId: block,
    };
    final blocks = <ReaderContentBlock>[
      for (final blockLayout in page.blocks)
        if (sourceBlocks.containsKey(blockLayout.blockId))
          _contentFragmentForLineBlock(
            sourceBlocks[blockLayout.blockId]!,
            blockLayout,
          ),
    ];

    return ReaderPageSlice(
      chapterIndex: page.chapterIndex,
      pageIndex: page.pageIndex,
      start: page.start,
      end: page.end,
      blocks: List.unmodifiable(blocks),
      lineLayout: page,
    );
  }

  ReaderContentBlock _contentFragmentForLineBlock(
      ReaderContentBlock block,
      ReaderPageBlockLayout blockLayout,
      ) {
    final localStart = (blockLayout.textRange.startOffset - block.startOffset)
        .clamp(0, block.length)
        .toInt();
    final localEnd = (blockLayout.textRange.endOffset - block.startOffset)
        .clamp(localStart, block.length)
        .toInt();

    return switch (block) {
      ReaderHeadingBlock(:final text, :final level) => ReaderHeadingBlock(
        blockId: block.blockId,
        chapterIndex: block.chapterIndex,
        startOffset: block.startOffset + localStart,
        endOffset: block.startOffset + localEnd,
        text: text.substring(localStart, localEnd),
        level: level,
      ),
      ReaderParagraphBlock(
          :final text,
          :final paragraphIndex,
          :final addBottomSpacing,
          :final startsAtParagraphStart,
      ) =>
          ReaderParagraphBlock(
            blockId: block.blockId,
            chapterIndex: block.chapterIndex,
            startOffset: block.startOffset + localStart,
            endOffset: block.startOffset + localEnd,
            text: text.substring(localStart, localEnd),
            paragraphIndex: paragraphIndex,
            addBottomSpacing:
            blockLayout.isLastFragmentOfBlock && addBottomSpacing,
            startsAtParagraphStart: localStart == 0 && startsAtParagraphStart,
          ),
      ReaderImageBlock(:final source, :final alt) => ReaderImageBlock(
        blockId: block.blockId,
        chapterIndex: block.chapterIndex,
        startOffset: block.startOffset + localStart,
        endOffset: block.startOffset + localEnd,
        source: source,
        alt: alt?.substring(localStart, localEnd),
      ),
    };
  }

  double _measureBlock({
    required ReaderContentBlock block,
    required ReaderSettings settings,
    required double maxWidth,
  }) {
    return _measureText(
      text: _textForBlock(block),
      style: _styleForBlock(block, settings),
      maxWidth: maxWidth,
    ) +
        _bottomSpacingForBlock(block, settings);
  }

  double _measureText({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    return textMeasure.measureHeight(
      text: text,
      style: style,
      maxWidth: maxWidth,
    );
  }

  TextStyle _styleForBlock(
      ReaderContentBlock block,
      ReaderSettings settings,
      ) {
    return switch (block) {
      ReaderHeadingBlock() => DudoTextStyles.serif(
        fontSize: settings.fontSize * (24 / 19),
        height: settings.lineHeight,
        fontWeight: settings.textEnhancementEnabled
            ? FontWeight.w700
            : FontWeight.w600,
      ),
      ReaderParagraphBlock() => DudoTextStyles.serif(
        fontSize: settings.fontSize,
        height: settings.lineHeight,
        fontWeight: settings.textEnhancementEnabled
            ? FontWeight.w500
            : FontWeight.w400,
        letterSpacing: 0.4,
      ),
      ReaderImageBlock() => DudoTextStyles.serif(
        fontSize: settings.fontSize,
        height: settings.lineHeight,
        fontWeight: settings.textEnhancementEnabled
            ? FontWeight.w500
            : FontWeight.w400,
      ),
    };
  }

  String _textForBlock(ReaderContentBlock block) {
    return switch (block) {
      ReaderHeadingBlock(:final text) => text,
      ReaderParagraphBlock(:final text) => text,
      ReaderImageBlock(:final alt) => alt ?? '',
    };
  }

  double _bottomSpacingForBlock(
      ReaderContentBlock block,
      ReaderSettings settings,
      ) {
    if (block is ReaderParagraphBlock && !block.addBottomSpacing) {
      return 0;
    }
    return settings.paragraphSpacing;
  }

  int _maxTextPrefixThatFits({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (text.isEmpty || maxHeight <= 0) return 0;
    var low = 0;
    var high = text.length;
    while (low < high) {
      final mid = ((low + high + 1) / 2).floor();
      final measured = _measureText(
        text: text.substring(0, mid),
        style: style,
        maxWidth: maxWidth,
      );
      if (measured <= maxHeight) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  ReaderParagraphBlock _paragraphFragment({
    required ReaderParagraphBlock block,
    required int localStart,
    required int localEnd,
    required bool addBottomSpacing,
  }) {
    final safeStart = localStart.clamp(0, block.text.length).toInt();
    final safeEnd = localEnd.clamp(safeStart, block.text.length).toInt();
    return ReaderParagraphBlock(
      blockId: block.blockId,
      chapterIndex: block.chapterIndex,
      startOffset: block.startOffset + safeStart,
      endOffset: block.startOffset + safeEnd,
      text: block.text.substring(safeStart, safeEnd),
      paragraphIndex: block.paragraphIndex,
      addBottomSpacing: addBottomSpacing,
      startsAtParagraphStart: safeStart == 0 && block.startsAtParagraphStart,
    );
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
      settings.turnMode.name,
      settings.paragraphSpacing,
      settings.firstLineIndentEnabled,
      settings.textEnhancementEnabled,
      settings.pagePadding.left,
      settings.pagePadding.top,
      settings.pagePadding.right,
      settings.pagePadding.bottom,
      viewportSize.width,
      viewportSize.height,
    ].join('|');
  }
}

class _LineBlockFragment {
  const _LineBlockFragment({
    required this.pageIndex,
    required this.layout,
  });

  final int pageIndex;
  final ReaderPageBlockLayout layout;
}
