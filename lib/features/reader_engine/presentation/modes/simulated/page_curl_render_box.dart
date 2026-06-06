import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'page_curl_controller.dart';
import 'page_curl_fold_geometry.dart';
import 'page_curl_quality.dart';
import 'page_curl_snapshot.dart';

class PageCurlRenderBox extends RenderBox {
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
    _drawContactShadow(canvas, geometry, isPrevious: false);
    canvas.save();
    canvas.clipPath(geometry.unturnedPath);
    _paintPageBase(canvas);
    _drawImageFull(canvas, snapshots.current);
    canvas.restore();
    _drawFoldedPage(canvas, snapshots.current, geometry);
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
    _drawContactShadow(canvas, geometry, isPrevious: true);
    _drawPreviousIncomingPage(canvas, snapshots.target, geometry);
    _drawPreviousFoldBack(canvas, geometry);
    _drawPreviousLeadingShadow(canvas, geometry);
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
      Paint()..filterQuality = FilterQuality.low,
    );
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

  void _drawPreviousIncomingPage(
    Canvas canvas,
    ui.Image image,
    PageCurlFoldGeometry geometry,
  ) {
    _drawImageClipped(canvas, image, geometry.foldedPath);
  }

  void _drawPreviousFoldBack(
    Canvas canvas,
    PageCurlFoldGeometry geometry,
  ) {
    final progress = geometry.progress;
    final bounds = geometry.turningPath.getBounds();
    if (bounds.isEmpty) return;

    canvas.save();
    canvas.clipPath(geometry.turningPath);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _tintToward(_pageColor, const Color(0xFFFFF8EA), 0.42)
                .withValues(alpha: 0.20),
            _tintToward(_pageColor, const Color(0xFFFFF2D8), 0.30)
                .withValues(alpha: 0.12),
            Colors.black.withValues(alpha: 0.11 * progress),
          ],
          stops: const [0, 0.56, 1],
        ).createShader(bounds),
    );
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

  void _drawContactShadow(
    Canvas canvas,
    PageCurlFoldGeometry geometry, {
    required bool isPrevious,
  }) {
    final progress = geometry.progress;
    final shadowPath = isPrevious ? geometry.turningPath : geometry.foldedPath;
    if (shadowPath.getBounds().isEmpty) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.restore();
  }

  void _drawPreviousLeadingShadow(
    Canvas canvas,
    PageCurlFoldGeometry geometry,
  ) {
    final progress = geometry.progress;
    final bounds = geometry.turningPath.getBounds();
    if (bounds.isEmpty) return;

    canvas.save();
    canvas.clipPath(geometry.turningPath);
    canvas.drawRect(
      bounds.inflate(10),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.10 * progress),
            Colors.black.withValues(alpha: 0.20 * progress),
          ],
          stops: const [0, 0.58, 1],
        ).createShader(bounds.inflate(10)),
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
    final warmPaper = _tintToward(_pageColor, const Color(0xFFFFF2D8), 0.34);
    final warmHighlight =
        _tintToward(_pageColor, const Color(0xFFFFF8EA), 0.46);

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
            warmHighlight.withValues(alpha: 0.20),
            warmPaper.withValues(alpha: 0.28),
            Colors.black.withValues(alpha: 0.08 * progress),
          ],
          stops: const [0, 0.62, 1],
        ).createShader(bounds),
    );
    canvas.restore();
  }

  void _drawFoldShadow(Canvas canvas, PageCurlFoldGeometry geometry) {
    final progress = geometry.progress;
    canvas.drawPath(
      geometry.foldCurvePath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 + progress * 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _drawPaperEdge(Canvas canvas, PageCurlFoldGeometry geometry) {
    final progress = geometry.progress;
    final isPrevious = geometry.turnType == PageCurlTurnType.previousPageIn;
    canvas.drawPath(
      geometry.outerEdgePath,
      Paint()
        ..color = Colors.black.withValues(
          alpha: (isPrevious ? 0.16 : 0.14) * progress,
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = isPrevious ? 2.6 + progress * 2.4 : 2.2 + progress * 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    if (!isPrevious) return;
    canvas.drawPath(
      geometry.outerEdgePath,
      Paint()
        ..color = _tintToward(_pageColor, const Color(0xFFFFF2D8), 0.32)
            .withValues(alpha: 0.20 * progress)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.8,
    );
  }

  Color _tintToward(Color base, Color target, double amount) {
    return Color.alphaBlend(
      target.withValues(alpha: amount.clamp(0.0, 1.0).toDouble()),
      base,
    );
  }
}
