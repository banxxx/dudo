import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'page_curl_controller.dart';
import 'page_curl_fold_geometry.dart';
import 'page_curl_gesture.dart';
import 'page_curl_quality.dart';
import 'page_curl_snapshot.dart';

class PageCurlRenderBox extends RenderBox {
  static const double _backsideInkFadeOpacity = 0.28;

  @visibleForTesting
  static Color backsideInkFadeColorFor(Color pageColor) {
    return pageColor.withValues(alpha: _backsideInkFadeOpacity);
  }

  PageCurlRenderBox({
    required PageCurlController controller,
    required PageCurlSnapshotPair? snapshots,
    required Color pageColor,
    required PageCurlQuality quality,
  })  : _controller = controller,
        _snapshots = snapshots,
        _pageColor = pageColor,
        _quality = quality;

  PageCurlController _controller;
  PageCurlSnapshotPair? _snapshots;
  Color _pageColor;
  PageCurlQuality _quality;

  Color get pageColor => _pageColor;
  PageCurlGesture? get gesture => _controller.gesture;
  PageCurlTurnType? get turnType => _controller.turnType;
  PageCurlQuality get quality => _quality;

  set controller(PageCurlController value) {
    if (_controller == value) return;
    if (attached) _controller.removeListener(markNeedsPaint);
    _controller = value;
    if (attached) _controller.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set snapshots(PageCurlSnapshotPair? value) {
    if (_snapshots == value) return;
    _snapshots = value;
    markNeedsPaint();
  }

  set pageColor(Color value) {
    if (_pageColor == value) return;
    _pageColor = value;
    markNeedsPaint();
  }

  set quality(PageCurlQuality value) {
    if (_quality == value) return;
    _quality = value;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.constrain(
      Size(
        constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
        constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
      ),
    );
  }

  @override
  void performResize() {
    size = computeDryLayout(constraints);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _controller.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final snapshots = _snapshots;
    final gesture = _controller.gesture;
    final turnType = _controller.turnType;
    if (snapshots == null ||
        snapshots.isDisposed ||
        gesture == null ||
        !gesture.isTurning ||
        turnType == null ||
        size.isEmpty) {
      return;
    }

    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.clipRect(Offset.zero & size);

    final geometry = PageCurlFoldGeometry.fromGesture(
      gesture: gesture,
      turnType: turnType,
      phase: _controller.phase,
      pageSize: size,
    );

    switch (turnType) {
      case PageCurlTurnType.nextPageOut:
        _paintNextPageOut(canvas, snapshots, geometry);
      case PageCurlTurnType.previousPageIn:
        _paintPreviousPageIn(canvas, snapshots, geometry);
    }

    canvas.restore();
  }

  void _paintNextPageOut(
    Canvas canvas,
    PageCurlSnapshotPair snapshots,
    PageCurlFoldGeometry geometry,
  ) {
    _paintPageBase(canvas);
    _drawImageFull(canvas, snapshots.target);
    _drawNextFoldCastShadow(canvas, geometry);
    canvas.save();
    canvas.clipPath(geometry.unturnedPath);
    _paintPageBase(canvas);
    _drawImageFull(canvas, snapshots.current);
    canvas.restore();
    _drawFoldedPage(canvas, snapshots.current, geometry);
    _drawBacksideInkFade(canvas, geometry);
    _drawPaperBackTone(canvas, geometry);
    _drawFoldShadow(canvas, geometry);
    _drawPaperEdge(canvas, geometry);
  }

  void _paintPreviousPageIn(
    Canvas canvas,
    PageCurlSnapshotPair snapshots,
    PageCurlFoldGeometry geometry,
  ) {
    _paintPageBase(canvas);
    _drawImageFull(canvas, snapshots.current);
    _drawNextFoldCastShadow(canvas, geometry);
    _drawImageClipped(canvas, snapshots.target, geometry.unturnedPath);
    _drawFoldedPage(canvas, snapshots.target, geometry);
    _drawBacksideInkFade(canvas, geometry);
    _drawPaperBackTone(canvas, geometry);
    _drawFoldShadow(canvas, geometry);
    _drawPaperEdge(canvas, geometry);
  }

  void _paintPageBase(Canvas canvas) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _pageColor);
  }

  void _drawImageFull(Canvas canvas, ui.Image image) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = _imageFilterQuality,
    );
  }

  FilterQuality get _imageFilterQuality {
    if (_quality.pixelRatioCap >= PageCurlQuality.high.pixelRatioCap) {
      return FilterQuality.medium;
    }
    return FilterQuality.low;
  }

  void _drawImageClipped(
    Canvas canvas,
    ui.Image image,
    Path path,
  ) {
    canvas.save();
    canvas.clipPath(path);
    _paintPageBase(canvas);
    _drawImageFull(canvas, image);
    canvas.restore();
  }

  void _drawFoldedPage(
    Canvas canvas,
    ui.Image image,
    PageCurlFoldGeometry geometry,
  ) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.transform(geometry.reflectionMatrix.storage);
    canvas.clipPath(geometry.turningPath);
    _paintPageBase(canvas);
    _drawImageFull(canvas, image);
    canvas.restore();
  }

  void _drawBacksideInkFade(
    Canvas canvas,
    PageCurlFoldGeometry geometry,
  ) {
    final bounds = geometry.foldedPath.getBounds();
    if (bounds.isEmpty) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.clipPath(geometry.foldedPath);
    canvas.drawRect(
      bounds,
      Paint()..color = backsideInkFadeColorFor(_pageColor),
    );
    canvas.restore();
  }

  void _drawNextFoldCastShadow(
    Canvas canvas,
    PageCurlFoldGeometry geometry,
  ) {
    final progress = geometry.progress;
    final shadowPath = Path()
      ..moveTo(geometry.foldLineStart.dx, geometry.foldLineStart.dy)
      ..lineTo(geometry.foldLineEnd.dx, geometry.foldLineEnd.dy);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14 + progress * 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();
  }

  void _drawPaperBackTone(
    Canvas canvas,
    PageCurlFoldGeometry geometry,
  ) {
    final bounds = geometry.foldedPath.getBounds();
    if (bounds.isEmpty) return;

    final progress = geometry.progress;
    final paperBack = _tintToward(_pageColor, const Color(0xFFFFF2D8), 0.16);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.clipPath(geometry.foldedPath);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: geometry.isRightCorner
              ? Alignment.centerLeft
              : Alignment.centerRight,
          end: geometry.isRightCorner
              ? Alignment.centerRight
              : Alignment.centerLeft,
          colors: [
            paperBack.withValues(alpha: 0.10),
            Colors.black.withValues(alpha: 0.035 * progress),
            Colors.black.withValues(alpha: 0.13 * progress),
          ],
          stops: const [0, 0.58, 1],
        ).createShader(bounds),
    );
    canvas.restore();
  }

  void _drawFoldShadow(Canvas canvas, PageCurlFoldGeometry geometry) {
    final progress = geometry.progress;
    if (geometry.corner == PageCurlFoldCorner.middleRight ||
        geometry.corner == PageCurlFoldCorner.middleLeft) {
      _drawMiddleFoldShadow(canvas, geometry);
      return;
    }
    final shadowPath = Path()
      ..moveTo(geometry.foldLineStart.dx, geometry.foldLineStart.dy)
      ..lineTo(geometry.foldLineEnd.dx, geometry.foldLineEnd.dy);

    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 + progress * 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14 * progress)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.4 + progress * 1.2,
    );
  }

  void _drawMiddleFoldShadow(Canvas canvas, PageCurlFoldGeometry geometry) {
    final progress = geometry.progress;
    final x = geometry.foldLineStart.dx;
    if (x <= -size.width || x >= size.width) return;

    final bandWidth = 26 + progress * 18;
    final rect = Rect.fromLTWH(
      x - bandWidth * 0.55,
      0,
      bandWidth,
      size.height,
    );

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.20 * progress),
            Colors.black.withValues(alpha: 0.32 * progress),
            Colors.black.withValues(alpha: 0.12 * progress),
            Colors.transparent,
          ],
          stops: const [0, 0.28, 0.48, 0.68, 1],
        ).createShader(rect),
    );
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  void _drawPaperEdge(Canvas canvas, PageCurlFoldGeometry geometry) {
    final progress = geometry.progress;
    final edgePath = geometry.outerEdgePath;
    final outwardOffset =
        geometry.isRightCorner ? const Offset(-2.5, 0) : const Offset(2.5, 0);

    canvas.save();
    canvas.clipPath(_outsideFoldedPagePath(geometry));
    canvas.translate(outwardOffset.dx, outwardOffset.dy);
    canvas.drawPath(
      edgePath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20 * progress)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 20 + progress * 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(
      edgePath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14 * progress)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8 + progress * 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();
  }

  Path _outsideFoldedPagePath(PageCurlFoldGeometry geometry) {
    final pagePath = Path()..addRect(Offset.zero & size);
    return Path.combine(
      PathOperation.difference,
      pagePath,
      geometry.foldedPath,
    );
  }

  Color _tintToward(Color base, Color target, double amount) {
    return Color.alphaBlend(
      target.withValues(alpha: amount.clamp(0.0, 1.0).toDouble()),
      base,
    );
  }
}
