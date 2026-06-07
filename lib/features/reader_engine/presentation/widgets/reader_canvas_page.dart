import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../layout/reader_line_layout_models.dart';

class ReaderCanvasPage extends StatelessWidget {
  const ReaderCanvasPage({
    super.key,
    required this.pageLayout,
    required this.palette,
    this.paintBackground = false,
  });

  final ReaderPageLayout pageLayout;
  final ReaderPalette palette;
  final bool paintBackground;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: pageLayout.pageRect.size,
      painter: ReaderPagePainter(
        pageLayout: pageLayout,
        palette: palette,
        paintBackground: paintBackground,
      ),
    );
  }
}

class ReaderPagePainter extends CustomPainter {
  const ReaderPagePainter({
    required this.pageLayout,
    required this.palette,
    this.paintBackground = false,
  });

  final ReaderPageLayout pageLayout;
  final ReaderPalette palette;
  final bool paintBackground;

  static void paintPage({
    required Canvas canvas,
    required ReaderPageLayout pageLayout,
    required ReaderPalette palette,
    bool paintBackground = false,
  }) {
    if (paintBackground) {
      canvas.drawRect(
        pageLayout.pageRect,
        Paint()..color = palette.background,
      );
    }

    canvas.save();
    canvas.clipRect(pageLayout.pageRect);
    for (final block in pageLayout.blocks) {
      for (final line in block.lines) {
        for (final run in line.runs) {
          final painter = TextPainter(
            text: TextSpan(
              text: run.text,
              style: run.style.copyWith(color: palette.foreground),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          painter.paint(canvas, Offset(run.x, line.y));
        }
      }
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintPage(
      canvas: canvas,
      pageLayout: pageLayout,
      palette: palette,
      paintBackground: paintBackground,
    );
  }

  @override
  bool shouldRepaint(covariant ReaderPagePainter oldDelegate) {
    return oldDelegate.pageLayout != pageLayout ||
        oldDelegate.palette != palette ||
        oldDelegate.paintBackground != paintBackground;
  }
}

class ReaderPageRasterizer {
  const ReaderPageRasterizer();

  ui.Picture renderPicture({
    required ReaderPageLayout pageLayout,
    required ReaderPalette palette,
    bool paintBackground = true,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    ReaderPagePainter.paintPage(
      canvas: canvas,
      pageLayout: pageLayout,
      palette: palette,
      paintBackground: paintBackground,
    );
    return recorder.endRecording();
  }

  Future<ui.Image> renderImage({
    required ReaderPageLayout pageLayout,
    required ReaderPalette palette,
    required double pixelRatio,
    bool paintBackground = true,
  }) async {
    final width = (pageLayout.pageRect.width * pixelRatio).round();
    final height = (pageLayout.pageRect.height * pixelRatio).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio, pixelRatio);
    ReaderPagePainter.paintPage(
      canvas: canvas,
      pageLayout: pageLayout,
      palette: palette,
      paintBackground: paintBackground,
    );
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(width, height);
    } finally {
      picture.dispose();
    }
  }
}
