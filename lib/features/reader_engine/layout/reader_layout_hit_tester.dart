import 'package:flutter/painting.dart';

import '../domain/reader_location.dart';
import 'reader_line_layout_models.dart';

class ReaderLayoutHitTester {
  const ReaderLayoutHitTester._();

  static ReaderLocation locationForPoint({
    required ReaderPageLayout page,
    required Offset point,
  }) {
    if (page.blocks.isEmpty) return page.start;

    final blockLine = _nearestBlockLine(page, point);
    if (blockLine == null) return page.start;

    final block = blockLine.block;
    final line = blockLine.line;
    final run = _nearestRun(line, point.dx);
    if (run == null) {
      return ReaderLocation(
        bookId: page.start.bookId,
        chapterIndex: line.textRange.chapterIndex,
        offset: line.textRange.startOffset,
        blockId: block.blockId,
      );
    }

    final painter = _painterForRun(run);
    final localDx = (point.dx - run.x).clamp(0.0, painter.width).toDouble();
    final localDy = (point.dy - line.y).clamp(0.0, line.height).toDouble();
    final localPosition = Offset(
      localDx,
      localDy,
    );
    final position = painter.getPositionForOffset(localPosition);
    final offset = (run.textRange.startOffset + position.offset)
        .clamp(
          run.textRange.startOffset,
          run.textRange.endOffset,
        )
        .toInt();

    return ReaderLocation(
      bookId: page.start.bookId,
      chapterIndex: run.textRange.chapterIndex,
      offset: offset,
      blockId: block.blockId,
    );
  }

  static List<Rect> rectsForRange({
    required ReaderPageLayout page,
    required ReaderTextRange range,
  }) {
    if (range.isCollapsed) return const [];
    final rects = <Rect>[];

    for (final block in page.blocks) {
      if (!block.textRange.intersects(range)) continue;
      for (final line in block.lines) {
        if (!line.textRange.intersects(range)) continue;
        for (final run in line.runs) {
          final intersection = run.textRange.intersection(range);
          if (intersection == null || intersection.isCollapsed) continue;

          final painter = _painterForRun(run);
          final boxes = painter.getBoxesForSelection(
            TextSelection(
              baseOffset: intersection.startOffset - run.textRange.startOffset,
              extentOffset: intersection.endOffset - run.textRange.startOffset,
            ),
          );
          for (final box in boxes) {
            rects.add(
              Rect.fromLTRB(
                run.x + box.left,
                line.y + box.top,
                run.x + box.right,
                line.y + box.bottom,
              ),
            );
          }
        }
      }
    }

    return rects;
  }

  static _ReaderBlockLine? _nearestBlockLine(
    ReaderPageLayout page,
    Offset point,
  ) {
    _ReaderBlockLine? nearest;
    var nearestDistance = double.infinity;

    for (final block in page.blocks) {
      for (final line in block.lines) {
        if (point.dy >= line.y && point.dy <= line.y + line.height) {
          return _ReaderBlockLine(block: block, line: line);
        }
        final centerY = line.y + line.height / 2;
        final distance = (point.dy - centerY).abs();
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearest = _ReaderBlockLine(block: block, line: line);
        }
      }
    }

    return nearest;
  }

  static ReaderTextRunLayout? _nearestRun(
    ReaderLineLayout line,
    double pointX,
  ) {
    if (line.runs.isEmpty) return null;
    for (final run in line.runs) {
      if (pointX >= run.x && pointX <= run.x + run.width) return run;
    }
    return line.runs.reduce((best, run) {
      final bestDistance = _horizontalDistanceToRun(best, pointX);
      final distance = _horizontalDistanceToRun(run, pointX);
      return distance < bestDistance ? run : best;
    });
  }

  static double _horizontalDistanceToRun(
    ReaderTextRunLayout run,
    double pointX,
  ) {
    if (pointX < run.x) return run.x - pointX;
    if (pointX > run.x + run.width) return pointX - (run.x + run.width);
    return 0;
  }

  static TextPainter _painterForRun(ReaderTextRunLayout run) {
    return TextPainter(
      text: TextSpan(text: run.text, style: run.style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }
}

class _ReaderBlockLine {
  const _ReaderBlockLine({
    required this.block,
    required this.line,
  });

  final ReaderPageBlockLayout block;
  final ReaderLineLayout line;
}
