import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'page_curl_controller.dart';
import 'page_curl_fold_geometry.dart';
import 'page_curl_gesture.dart';
import 'page_curl_quality.dart';
import 'page_curl_snapshot.dart';

class PageCurlRenderBox extends RenderBox {
  static const Color _legadoTransparentFolderShadow = Color(0x00333333);
  static const Color _legadoFolderShadow = Color(0x20424242);
  static const Color _legadoTransparentPageShadow = Color(0x00111111);
  static const Color _legadoBackShadow = Color(0x42424242);
  static const Color _legadoFrontShadow = Color(0x18A0A0A0);
  static const double _frontShadowSpread = 10;

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

    switch (turnType) {
      case PageCurlTurnType.nextPageOut:
        final bezierGeometry = PageCurlBezierGeometry.fromGesture(
          gesture: gesture,
          turnType: PageCurlTurnType.nextPageOut,
          phase: _controller.phase,
          pageSize: size,
        );
        _paintBezierNextPageOut(canvas, snapshots, bezierGeometry);
      case PageCurlTurnType.previousPageIn:
        final bezierGeometry = PageCurlBezierGeometry.fromGesture(
          gesture: gesture,
          turnType: PageCurlTurnType.previousPageIn,
          phase: _controller.phase,
          pageSize: size,
        );
        _paintBezierPreviousPageIn(canvas, snapshots, bezierGeometry);
    }

    canvas.restore();
  }

  void _paintBezierNextPageOut(
    Canvas canvas,
    PageCurlSnapshotPair snapshots,
    PageCurlBezierGeometry geometry,
  ) {
    _paintPageBase(canvas);
    _drawImageFull(canvas, snapshots.target);
    _drawBezierNextPageAreaShadow(canvas, geometry);
    _drawImageClipped(canvas, snapshots.current, geometry.currentPagePath);
    _drawBezierCurrentPageShadow(canvas, geometry);
    _drawBezierBackPage(canvas, snapshots.current, geometry);
    _drawBezierFoldedBackShadow(canvas, geometry);
  }

  void _paintBezierPreviousPageIn(
    Canvas canvas,
    PageCurlSnapshotPair snapshots,
    PageCurlBezierGeometry geometry,
  ) {
    _paintPageBase(canvas);
    _drawImageFull(canvas, snapshots.current);
    _drawBezierNextPageAreaShadow(canvas, geometry);
    _drawImageClipped(canvas, snapshots.target, geometry.currentPagePath);
    _drawBezierCurrentPageShadow(canvas, geometry);
    _drawBezierBackPage(canvas, snapshots.target, geometry);
    _drawBezierFoldedBackShadow(canvas, geometry);
  }

  void _paintPageBase(Canvas canvas) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _pageColor);
  }

  void _drawImageFull(Canvas canvas, ui.Image image) {
    _drawImageFullWithPaint(
      canvas,
      image,
      Paint()..filterQuality = _imageFilterQuality,
    );
  }

  void _drawImageFullWithPaint(
    Canvas canvas,
    ui.Image image,
    Paint paint,
  ) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      paint,
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

  void _drawBezierBackPage(
    Canvas canvas,
    ui.Image image,
    PageCurlBezierGeometry geometry,
  ) {
    final bounds = geometry.backPath.getBounds();
    if (bounds.isEmpty) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _clipBezierBackArea(canvas, geometry);
    canvas.drawRect(Offset.zero & size, Paint()..color = _pageColor);
    canvas.transform(geometry.reflectionMatrix.storage);
    _drawImageFullWithPaint(
      canvas,
      image,
      Paint()..filterQuality = _imageFilterQuality,
    );
    canvas.restore();
  }

  void _drawBezierNextPageAreaShadow(
    Canvas canvas,
    PageCurlBezierGeometry geometry,
  ) {
    final shadowPath = Path()
      ..moveTo(geometry.start1.dx, geometry.start1.dy)
      ..lineTo(geometry.vertex1.dx, geometry.vertex1.dy)
      ..lineTo(geometry.vertex2.dx, geometry.vertex2.dy)
      ..lineTo(geometry.start2.dx, geometry.start2.dy)
      ..lineTo(geometry.cornerPoint.dx, geometry.cornerPoint.dy)
      ..close();
    final bandWidth = geometry.touchToCornerDistance / 4;
    final left = geometry.isRightTopOrLeftBottom
        ? _trunc(geometry.start1.dx)
        : _trunc(geometry.start1.dx - bandWidth);
    final right = geometry.isRightTopOrLeftBottom
        ? _trunc(geometry.start1.dx + bandWidth)
        : _trunc(geometry.start1.dx);
    final radians = math.atan2(
      geometry.control1.dx - geometry.cornerPoint.dx,
      geometry.control2.dy - geometry.cornerPoint.dy,
    );

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.clipPath(geometry.foldPath);
    canvas.clipPath(shadowPath);
    _drawRotatedBand(
      canvas,
      pivot: geometry.start1,
      radians: radians,
      rect: Rect.fromLTRB(
        left,
        _trunc(geometry.start1.dy),
        right,
        _trunc(geometry.start1.dy + _maxShadowLength),
      ),
      colors: geometry.isRightTopOrLeftBottom
          ? [_legadoBackShadow, _legadoTransparentPageShadow]
          : [_legadoTransparentPageShadow, _legadoBackShadow],
      horizontal: true,
    );
    canvas.restore();
  }

  void _drawBezierCurrentPageShadow(
    Canvas canvas,
    PageCurlBezierGeometry geometry,
  ) {
    final outsideFoldPath = _outsideBezierFoldPath(geometry);
    final degree = geometry.isRightTopOrLeftBottom
        ? math.pi / 4 -
            math.atan2(
              geometry.control1.dy - geometry.touch.dy,
              geometry.touch.dx - geometry.control1.dx,
            )
        : math.pi / 4 -
            math.atan2(
              geometry.touch.dy - geometry.control1.dy,
              geometry.touch.dx - geometry.control1.dx,
            );
    final d1 = _frontShadowSpread * math.sqrt2 * math.cos(degree);
    final d2 = _frontShadowSpread * math.sqrt2 * math.sin(degree);
    final shadowTip = Offset(
      geometry.touch.dx + d1,
      geometry.touch.dy + (geometry.isRightTopOrLeftBottom ? d2 : -d2),
    );

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.clipPath(outsideFoldPath);
    canvas.clipPath(
      Path()
        ..moveTo(shadowTip.dx, shadowTip.dy)
        ..lineTo(geometry.touch.dx, geometry.touch.dy)
        ..lineTo(geometry.control1.dx, geometry.control1.dy)
        ..lineTo(geometry.start1.dx, geometry.start1.dy)
        ..close(),
    );
    final verticalLeft = geometry.isRightTopOrLeftBottom
        ? _trunc(geometry.control1.dx)
        : _trunc(geometry.control1.dx - _frontShadowSpread);
    final verticalRight = geometry.isRightTopOrLeftBottom
        ? _trunc(geometry.control1.dx + _frontShadowSpread)
        : _trunc(geometry.control1.dx + 1);
    _drawRotatedBand(
      canvas,
      pivot: geometry.control1,
      radians: math.atan2(
        geometry.touch.dx - geometry.control1.dx,
        geometry.control1.dy - geometry.touch.dy,
      ),
      rect: Rect.fromLTRB(
        verticalLeft,
        _trunc(geometry.control1.dy - _maxShadowLength),
        verticalRight,
        _trunc(geometry.control1.dy),
      ),
      colors: geometry.isRightTopOrLeftBottom
          ? [_legadoFrontShadow, _legadoTransparentPageShadow]
          : [_legadoTransparentPageShadow, _legadoFrontShadow],
      horizontal: true,
    );
    canvas.restore();

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.clipPath(outsideFoldPath);
    canvas.clipPath(
      Path()
        ..moveTo(shadowTip.dx, shadowTip.dy)
        ..lineTo(geometry.touch.dx, geometry.touch.dy)
        ..lineTo(geometry.control2.dx, geometry.control2.dy)
        ..lineTo(geometry.start2.dx, geometry.start2.dy)
        ..close(),
    );
    final horizontalTop = geometry.isRightTopOrLeftBottom
        ? _trunc(geometry.control2.dy)
        : _trunc(geometry.control2.dy - _frontShadowSpread);
    final horizontalBottom = geometry.isRightTopOrLeftBottom
        ? _trunc(geometry.control2.dy + _frontShadowSpread)
        : _trunc(geometry.control2.dy + 1);
    final temp = geometry.control2.dy < 0
        ? geometry.control2.dy - size.height
        : geometry.control2.dy;
    final hmg = math.sqrt(
      geometry.control2.dx * geometry.control2.dx + temp * temp,
    );
    final horizontalLeft = hmg > _maxShadowLength
        ? _trunc(geometry.control2.dx - _frontShadowSpread - hmg)
        : _trunc(geometry.control2.dx - _maxShadowLength);
    final horizontalRight = hmg > _maxShadowLength
        ? _trunc(geometry.control2.dx + _maxShadowLength - hmg)
        : _trunc(geometry.control2.dx);
    _drawRotatedBand(
      canvas,
      pivot: geometry.control2,
      radians: math.atan2(
        geometry.control2.dy - geometry.touch.dy,
        geometry.control2.dx - geometry.touch.dx,
      ),
      rect: Rect.fromLTRB(
        horizontalLeft,
        horizontalTop,
        horizontalRight,
        horizontalBottom,
      ),
      colors: geometry.isRightTopOrLeftBottom
          ? [_legadoFrontShadow, _legadoTransparentPageShadow]
          : [_legadoTransparentPageShadow, _legadoFrontShadow],
      horizontal: false,
    );
    canvas.restore();
  }

  void _drawBezierFoldedBackShadow(
    Canvas canvas,
    PageCurlBezierGeometry geometry,
  ) {
    final i = _trunc((geometry.start1.dx + geometry.control1.dx) / 2);
    final f1 = (i - geometry.control1.dx).abs();
    final i1 = _trunc((geometry.start2.dy + geometry.control2.dy) / 2);
    final f2 = (i1 - geometry.control2.dy).abs();
    final bandWidth = math.min(f1, f2);
    final left = geometry.isRightTopOrLeftBottom
        ? _trunc(geometry.start1.dx - 1)
        : _trunc(geometry.start1.dx - bandWidth - 1);
    final right = geometry.isRightTopOrLeftBottom
        ? _trunc(geometry.start1.dx + bandWidth + 1)
        : _trunc(geometry.start1.dx + 1);
    final radians = math.atan2(
      geometry.control1.dx - geometry.cornerPoint.dx,
      geometry.control2.dy - geometry.cornerPoint.dy,
    );

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _clipBezierBackArea(canvas, geometry);
    _drawRotatedBand(
      canvas,
      pivot: geometry.start1,
      radians: radians,
      rect: Rect.fromLTRB(
        left,
        _trunc(geometry.start1.dy),
        right,
        _trunc(geometry.start1.dy + _maxShadowLength),
      ),
      colors: geometry.isRightTopOrLeftBottom
          ? [_legadoTransparentFolderShadow, _legadoFolderShadow]
          : [_legadoFolderShadow, _legadoTransparentFolderShadow],
      horizontal: true,
    );
    canvas.restore();
  }

  double get _maxShadowLength {
    return math.sqrt(size.width * size.width + size.height * size.height);
  }

  double _trunc(double value) {
    return value.truncateToDouble();
  }

  Path _outsideBezierFoldPath(PageCurlBezierGeometry geometry) {
    final pagePath = Path()..addRect(Offset.zero & size);
    return Path.combine(
      PathOperation.difference,
      pagePath,
      geometry.foldPath,
    );
  }

  void _clipBezierBackArea(
    Canvas canvas,
    PageCurlBezierGeometry geometry,
  ) {
    canvas.clipPath(geometry.foldPath);
    canvas.clipPath(geometry.backPath);
  }

  void _drawRotatedBand(
    Canvas canvas, {
    required Offset pivot,
    required double radians,
    required Rect rect,
    required List<Color> colors,
    required bool horizontal,
  }) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(radians);
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
          end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );
    canvas.restore();
  }
}
