import 'package:flutter/material.dart';

import 'page_curl_geometry.dart';
import 'page_curl_snapshot.dart';

class PageCurlPainter extends CustomPainter {
  const PageCurlPainter({
    required this.snapshots,
    required this.geometry,
    required this.pageColor,
  });

  final PageCurlSnapshotPair snapshots;
  final PageCurlGeometry geometry;
  final Color pageColor;

  @override
  void paint(Canvas canvas, Size size) {
    final pageRect = Offset.zero & size;
    final imageCurrentRect = Rect.fromLTWH(
      0,
      0,
      snapshots.current.width.toDouble(),
      snapshots.current.height.toDouble(),
    );
    final imageTargetRect = Rect.fromLTWH(
      0,
      0,
      snapshots.target.width.toDouble(),
      snapshots.target.height.toDouble(),
    );
    final basePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.low;
    final pagePaint = Paint()..color = pageColor;

    canvas.drawRect(pageRect, pagePaint);
    canvas.drawImageRect(
      snapshots.target,
      imageTargetRect,
      pageRect,
      basePaint,
    );

    _paintUnderPageShadow(canvas, pageRect);

    canvas.save();
    canvas.clipPath(geometry.unturnedPath);
    canvas.drawRect(pageRect, pagePaint);
    canvas.drawImageRect(
      snapshots.current,
      imageCurrentRect,
      pageRect,
      basePaint,
    );
    canvas.restore();

    _paintFoldedPage(
      canvas: canvas,
      pageRect: pageRect,
      imageCurrentRect: imageCurrentRect,
      basePaint: basePaint,
      pagePaint: pagePaint,
    );
    _paintFoldShadow(canvas);
    _paintPaperEdge(canvas);
    _paintFoldHighlight(canvas);
  }

  void _paintFoldedPage({
    required Canvas canvas,
    required Rect pageRect,
    required Rect imageCurrentRect,
    required Paint basePaint,
    required Paint pagePaint,
  }) {
    canvas.save();
    canvas.clipRect(pageRect);
    canvas.clipPath(geometry.foldedPath);
    canvas.drawRect(pageRect, pagePaint);
    canvas.transform(geometry.reflectionMatrix.storage);
    canvas.drawImageRect(
      snapshots.current,
      imageCurrentRect,
      pageRect,
      basePaint,
    );
    canvas.restore();

    final bounds = geometry.foldedPath.getBounds();
    if (bounds.isEmpty) return;

    final shader = LinearGradient(
      begin:
          geometry.isRightCorner ? Alignment.centerLeft : Alignment.centerRight,
      end:
          geometry.isRightCorner ? Alignment.centerRight : Alignment.centerLeft,
      colors: [
        const Color(0xFFFFF7E8).withValues(alpha: 0.18),
        const Color(0xFFFFE5B8).withValues(alpha: 0.28),
        Colors.black.withValues(alpha: 0.08 * geometry.progress),
      ],
      stops: const [0, 0.62, 1],
    ).createShader(bounds);

    canvas.save();
    canvas.clipRect(pageRect);
    canvas.drawPath(geometry.foldedPath, Paint()..shader = shader);
    canvas.restore();
  }

  void _paintUnderPageShadow(Canvas canvas, Rect pageRect) {
    canvas.save();
    canvas.clipRect(pageRect);
    canvas.drawPath(
      geometry.foldedPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2 * geometry.progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.restore();
  }

  void _paintFoldShadow(Canvas canvas) {
    canvas.drawPath(
      geometry.foldCurvePath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.24 * geometry.progress)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12 + geometry.progress * 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _paintFoldHighlight(Canvas canvas) {
    canvas.drawPath(
      geometry.foldCurvePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.36 * geometry.progress)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2 + geometry.progress * 2,
    );
  }

  void _paintPaperEdge(Canvas canvas) {
    canvas.drawPath(
      geometry.outerEdgePath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.26 * geometry.progress)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3 + geometry.progress * 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      geometry.outerEdgePath,
      Paint()
        ..color = const Color(0xFFFFF9EF).withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant PageCurlPainter oldDelegate) {
    return oldDelegate.snapshots != snapshots ||
        oldDelegate.pageColor != pageColor ||
        oldDelegate.geometry.progress != geometry.progress ||
        oldDelegate.geometry.corner != geometry.corner ||
        oldDelegate.geometry.foldLineStart != geometry.foldLineStart ||
        oldDelegate.geometry.foldLineEnd != geometry.foldLineEnd ||
        oldDelegate.geometry.foldCurveControl != geometry.foldCurveControl ||
        oldDelegate.geometry.contactShadowCenter !=
            geometry.contactShadowCenter;
  }
}
