import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/reader_chapter.dart';
import '../domain/reader_content_block.dart';
import '../domain/reader_location.dart';
import 'reader_layout_models.dart';
import 'reader_layout_settings.dart';
import 'reader_line_layout_models.dart';

abstract interface class ReaderLineLayoutEngine {
  Future<ReaderLineChapterLayout> layoutChapter({
    required ReaderChapter chapter,
    required ReaderLayoutSettings settings,
    required Size viewportSize,
  });
}

class FlutterReaderLineLayoutEngine implements ReaderLineLayoutEngine {
  const FlutterReaderLineLayoutEngine();

  @override
  Future<ReaderLineChapterLayout> layoutChapter({
    required ReaderChapter chapter,
    required ReaderLayoutSettings settings,
    required Size viewportSize,
  }) async {
    final pageRect = Offset.zero & viewportSize;
    final contentRect = Rect.fromLTRB(
      settings.pagePadding.left,
      settings.pagePadding.top,
      math.max(settings.pagePadding.left + 1,
          viewportSize.width - settings.pagePadding.right),
      math.max(settings.pagePadding.top + 1,
          viewportSize.height - settings.pagePadding.bottom),
    );
    final pageLayouts = <ReaderPageLayout>[];
    final chapterBlocks = <ReaderPageBlockLayout>[];

    var pageIndex = 0;
    var cursorY = contentRect.top;
    var scrollY = 0.0;
    var pageBlocks = <ReaderPageBlockLayout>[];
    ReaderLocation? pageStart;
    ReaderLocation? pageEnd;

    void finishPage() {
      if (pageBlocks.isEmpty) return;
      pageLayouts.add(
        ReaderPageLayout(
          chapterIndex: chapter.index,
          pageIndex: pageIndex,
          pageRect: pageRect,
          contentRect: contentRect,
          start: pageStart ??
              ReaderLocation.startOfChapter(
                bookId: chapter.bookId,
                chapterIndex: chapter.index,
              ),
          end: pageEnd ??
              ReaderLocation.startOfChapter(
                bookId: chapter.bookId,
                chapterIndex: chapter.index,
              ),
          blocks: List.unmodifiable(pageBlocks),
        ),
      );
      pageIndex += 1;
      cursorY = contentRect.top;
      pageBlocks = <ReaderPageBlockLayout>[];
      pageStart = null;
      pageEnd = null;
    }

    for (final block in chapter.blocks) {
      final text = _textForBlock(block);
      if (text.isEmpty) continue;

      final style = _styleForBlock(block, settings);
      final type = _typeForBlock(block);
      final blockLines = _buildBlockLines(
        block: block,
        text: text,
        style: style,
        settings: settings,
        contentRect: contentRect,
      );

      final pendingLines = <ReaderLineLayout>[];
      var firstFragment = true;

      void flushBlockFragment({required bool isLastFragment}) {
        if (pendingLines.isEmpty) return;
        final rect = _rectForLines(pendingLines);
        final fragment = ReaderPageBlockLayout(
          blockId: block.blockId,
          type: type,
          chapterIndex: chapter.index,
          textRange: ReaderTextRange(
            chapterIndex: chapter.index,
            startOffset: pendingLines.first.textRange.startOffset,
            endOffset: pendingLines.last.textRange.endOffset,
          ),
          rect: rect,
          style: style,
          lines: List.unmodifiable(pendingLines),
          isFirstFragmentOfBlock: firstFragment,
          isLastFragmentOfBlock: isLastFragment,
        );
        pageBlocks.add(fragment);
        chapterBlocks.add(fragment);
        firstFragment = false;
        pendingLines.clear();
      }

      for (final line in blockLines) {
        if (cursorY + line.height > contentRect.bottom &&
            (pendingLines.isNotEmpty || pageBlocks.isNotEmpty)) {
          flushBlockFragment(isLastFragment: false);
          finishPage();
        }

        pageStart ??= ReaderLocation(
          bookId: chapter.bookId,
          chapterIndex: chapter.index,
          offset: line.textRange.startOffset,
          blockId: block.blockId,
        );
        pageEnd = ReaderLocation(
          bookId: chapter.bookId,
          chapterIndex: chapter.index,
          offset: line.textRange.endOffset,
          blockId: block.blockId,
        );

        final pageLine = _moveLineToY(line, cursorY);
        pendingLines.add(pageLine);
        cursorY += pageLine.height;
        scrollY += pageLine.height;
      }

      flushBlockFragment(isLastFragment: true);
      if (pageBlocks.isNotEmpty) {
        final spacing = _bottomSpacingForBlock(block, settings);
        cursorY += spacing;
        scrollY += spacing;
      }
    }

    if (pageBlocks.isNotEmpty) {
      finishPage();
    }
    if (pageLayouts.isEmpty) {
      pageLayouts.add(
        ReaderPageLayout(
          chapterIndex: chapter.index,
          pageIndex: 0,
          pageRect: pageRect,
          contentRect: contentRect,
          start: ReaderLocation.startOfChapter(
            bookId: chapter.bookId,
            chapterIndex: chapter.index,
          ),
          end: ReaderLocation.startOfChapter(
            bookId: chapter.bookId,
            chapterIndex: chapter.index,
          ),
          blocks: const [],
        ),
      );
    }

    return ReaderLineChapterLayout(
      chapterIndex: chapter.index,
      revision: ReaderLayoutRevision(
        contentHash: chapter.normalizedText.hashCode,
        settingsDigest: _settingsDigest(settings, viewportSize),
      ),
      viewportSize: viewportSize,
      contentRect: contentRect,
      pages: List.unmodifiable(pageLayouts),
      blocks: List.unmodifiable(chapterBlocks),
      contentHeight: scrollY,
    );
  }

  List<ReaderLineLayout> _buildBlockLines({
    required ReaderContentBlock block,
    required String text,
    required TextStyle style,
    required ReaderLayoutSettings settings,
    required Rect contentRect,
  }) {
    final lines = <ReaderLineLayout>[];
    final contentWidth = contentRect.width;
    var localStart = 0;
    var isFirstLine = true;

    while (localStart < text.length) {
      final indent = block is ReaderParagraphBlock &&
              block.startsAtParagraphStart &&
              isFirstLine
          ? settings.firstLineIndent
          : 0.0;
      final maxWidth = math.max(1.0, contentWidth - indent);
      final localEnd = _maxTextPrefixForWidth(
        text: text,
        localStart: localStart,
        style: style,
        maxWidth: maxWidth,
      );
      final safeEnd = math.max(localStart + 1, localEnd);
      final lineText = text.substring(localStart, safeEnd);
      final metrics = _measureLine(lineText, style);
      final startOffset = block.startOffset + localStart;
      final endOffset = block.startOffset + safeEnd;
      final textRange = ReaderTextRange(
        chapterIndex: block.chapterIndex,
        startOffset: startOffset,
        endOffset: endOffset,
      );
      final x = contentRect.left + indent;
      final baseline = metrics.baseline;
      final height = metrics.height;

      lines.add(
        ReaderLineLayout(
          textRange: textRange,
          x: x,
          y: 0,
          width: metrics.width,
          height: height,
          baseline: baseline,
          isFirstLineOfBlock: isFirstLine,
          isLastLineOfBlock: safeEnd >= text.length,
          isLastLineOfParagraph: safeEnd >= text.length,
          align: settings.enableJustify
              ? ReaderTextAlign.justify
              : settings.textAlign,
          runs: [
            ReaderTextRunLayout(
              textRange: textRange,
              text: lineText,
              x: x,
              baseline: baseline,
              width: metrics.width,
              style: style,
            ),
          ],
        ),
      );
      localStart = safeEnd;
      isFirstLine = false;
    }
    return lines;
  }

  int _maxTextPrefixForWidth({
    required String text,
    required int localStart,
    required TextStyle style,
    required double maxWidth,
  }) {
    var low = localStart + 1;
    var high = text.length;
    var best = low;

    while (low <= high) {
      final mid = ((low + high) / 2).floor();
      final width = _measureLine(text.substring(localStart, mid), style).width;
      if (width <= maxWidth) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return best;
  }

  _LineMetrics _measureLine(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final metrics = painter.computeLineMetrics();
    final line = metrics.isEmpty ? null : metrics.first;
    return _LineMetrics(
      width: painter.width,
      height: line?.height ?? painter.height,
      baseline: line?.baseline ?? painter.height,
    );
  }

  ReaderLineLayout _moveLineToY(ReaderLineLayout line, double y) {
    return ReaderLineLayout(
      textRange: line.textRange,
      x: line.x,
      y: y,
      width: line.width,
      height: line.height,
      baseline: y + line.baseline,
      isFirstLineOfBlock: line.isFirstLineOfBlock,
      isLastLineOfBlock: line.isLastLineOfBlock,
      isLastLineOfParagraph: line.isLastLineOfParagraph,
      align: line.align,
      runs: [
        for (final run in line.runs)
          ReaderTextRunLayout(
            textRange: run.textRange,
            text: run.text,
            x: run.x,
            baseline: y + run.baseline,
            width: run.width,
            style: run.style,
            glyphAdvances: run.glyphAdvances,
          ),
      ],
    );
  }

  Rect _rectForLines(List<ReaderLineLayout> lines) {
    final left = lines.map((line) => line.x).reduce(math.min);
    final top = lines.map((line) => line.y).reduce(math.min);
    final right = lines.map((line) => line.x + line.width).reduce(math.max);
    final bottom = lines.map((line) => line.y + line.height).reduce(math.max);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  TextStyle _styleForBlock(
    ReaderContentBlock block,
    ReaderLayoutSettings settings,
  ) {
    return switch (block) {
      ReaderHeadingBlock() => _textStyle(
          settings: settings,
          fontSize: settings.fontSize * (24 / 19),
          fontWeight: settings.textEnhancementEnabled
              ? FontWeight.w700
              : FontWeight.w600,
          letterSpacing: 0,
        ),
      ReaderParagraphBlock() => _textStyle(
          settings: settings,
          fontSize: settings.fontSize,
          fontWeight: settings.textEnhancementEnabled
              ? FontWeight.w500
              : FontWeight.w400,
          letterSpacing: settings.letterSpacing,
        ),
      ReaderImageBlock() => _textStyle(
          settings: settings,
          fontSize: settings.fontSize,
          fontWeight: settings.textEnhancementEnabled
              ? FontWeight.w500
              : FontWeight.w400,
          letterSpacing: settings.letterSpacing,
        ),
    };
  }

  TextStyle _textStyle({
    required ReaderLayoutSettings settings,
    required double fontSize,
    required FontWeight fontWeight,
    required double letterSpacing,
  }) {
    return TextStyle(
      fontFamily: settings.fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: settings.lineHeight,
      letterSpacing: letterSpacing,
      decoration: TextDecoration.none,
    );
  }

  String _textForBlock(ReaderContentBlock block) {
    return switch (block) {
      ReaderHeadingBlock(:final text) => text,
      ReaderParagraphBlock(:final text) => text,
      ReaderImageBlock(:final alt) => alt ?? '',
    };
  }

  ReaderPageBlockType _typeForBlock(ReaderContentBlock block) {
    return switch (block) {
      ReaderHeadingBlock() => ReaderPageBlockType.heading,
      ReaderParagraphBlock() => ReaderPageBlockType.paragraph,
      ReaderImageBlock() => ReaderPageBlockType.image,
    };
  }

  double _bottomSpacingForBlock(
    ReaderContentBlock block,
    ReaderLayoutSettings settings,
  ) {
    if (block is ReaderParagraphBlock && !block.addBottomSpacing) {
      return 0;
    }
    return settings.paragraphSpacing;
  }

  String _settingsDigest(ReaderLayoutSettings settings, Size viewportSize) {
    return [
      settings.digest,
      viewportSize.width,
      viewportSize.height,
    ].join('|');
  }
}

class _LineMetrics {
  const _LineMetrics({
    required this.width,
    required this.height,
    required this.baseline,
  });

  final double width;
  final double height;
  final double baseline;
}
