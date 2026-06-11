import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'page_curl_controller.dart';
import 'page_curl_gesture.dart';

enum PageCurlFoldCorner {
  topLeft,
  topRight,
  middleLeft,
  middleRight,
  bottomLeft,
  bottomRight,
}

class PageCurlBezierGeometry {
  const PageCurlBezierGeometry({
    required this.pageSize,
    required this.corner,
    required this.progress,
    required this.touch,
    required this.currentPagePath,
    required this.foldPath,
    required this.backPath,
    required this.foldCurvePath,
    required this.outerEdgePath,
    required this.reflectionMatrix,
    required this.start1,
    required this.start2,
    required this.control1,
    required this.control2,
    required this.vertex1,
    required this.vertex2,
    required this.end1,
    required this.end2,
    required this.cornerPoint,
    required this.touchToCornerDistance,
  });

  factory PageCurlBezierGeometry.fromGesture({
    required PageCurlGesture gesture,
    required PageCurlTurnType turnType,
    PageCurlMotionPhase phase = PageCurlMotionPhase.interactive,
    required Size pageSize,
  }) {
    final width = math.max(1.0, pageSize.width);
    final height = math.max(1.0, pageSize.height);
    final progress = gesture.progress.clamp(0.001, 1.0).toDouble();
    final corner = _cornerForGesture(gesture, turnType);
    final cornerPoint = _cornerPoint(corner, width, height);
    final contactPoint = _contactPointFor(
      gesture: gesture,
      turnType: turnType,
      phase: phase,
      width: width,
      height: height,
    );

    final points = _BezierPoints.fromTouch(
      cornerPoint: cornerPoint,
      touch: _stableTouch(contactPoint, width, height),
      width: width,
      height: height,
    );
    final pagePath = Path()..addRect(Rect.fromLTWH(0, 0, width, height));
    final foldPath = Path()
      ..moveTo(points.start1.dx, points.start1.dy)
      ..quadraticBezierTo(
        points.control1.dx,
        points.control1.dy,
        points.end1.dx,
        points.end1.dy,
      )
      ..lineTo(points.touch.dx, points.touch.dy)
      ..lineTo(points.end2.dx, points.end2.dy)
      ..quadraticBezierTo(
        points.control2.dx,
        points.control2.dy,
        points.start2.dx,
        points.start2.dy,
      )
      ..lineTo(cornerPoint.dx, cornerPoint.dy)
      ..close();
    final currentPagePath = Path.combine(
      PathOperation.difference,
      pagePath,
      foldPath,
    );
    final backPath = Path()
      ..moveTo(points.vertex2.dx, points.vertex2.dy)
      ..lineTo(points.vertex1.dx, points.vertex1.dy)
      ..lineTo(points.end1.dx, points.end1.dy)
      ..lineTo(points.touch.dx, points.touch.dy)
      ..lineTo(points.end2.dx, points.end2.dy)
      ..close();
    final foldCurvePath = Path()
      ..moveTo(points.start1.dx, points.start1.dy)
      ..quadraticBezierTo(
        points.control1.dx,
        points.control1.dy,
        points.end1.dx,
        points.end1.dy,
      )
      ..moveTo(points.start2.dx, points.start2.dy)
      ..quadraticBezierTo(
        points.control2.dx,
        points.control2.dy,
        points.end2.dx,
        points.end2.dy,
      );
    final outerEdgePath = Path()
      ..moveTo(points.end1.dx, points.end1.dy)
      ..lineTo(points.touch.dx, points.touch.dy)
      ..lineTo(points.end2.dx, points.end2.dy);

    return PageCurlBezierGeometry(
      pageSize: pageSize,
      corner: corner,
      progress: progress,
      touch: points.touch,
      currentPagePath: currentPagePath,
      foldPath: foldPath,
      backPath: backPath,
      foldCurvePath: foldCurvePath,
      outerEdgePath: outerEdgePath,
      reflectionMatrix: _reflectionMatrixFor(points, cornerPoint),
      start1: points.start1,
      start2: points.start2,
      control1: points.control1,
      control2: points.control2,
      vertex1: points.vertex1,
      vertex2: points.vertex2,
      end1: points.end1,
      end2: points.end2,
      cornerPoint: cornerPoint,
      touchToCornerDistance: (points.touch - cornerPoint).distance,
    );
  }

  final Size pageSize;
  final PageCurlFoldCorner corner;
  final double progress;
  final Offset touch;
  final Path currentPagePath;
  final Path foldPath;
  final Path backPath;
  final Path foldCurvePath;
  final Path outerEdgePath;
  final Matrix4 reflectionMatrix;
  final Offset start1;
  final Offset start2;
  final Offset control1;
  final Offset control2;
  final Offset vertex1;
  final Offset vertex2;
  final Offset end1;
  final Offset end2;
  final Offset cornerPoint;
  final double touchToCornerDistance;

  bool get isRightCorner {
    return corner == PageCurlFoldCorner.topRight ||
        corner == PageCurlFoldCorner.bottomRight;
  }

  bool get isRightTopOrLeftBottom {
    return corner == PageCurlFoldCorner.topRight ||
        corner == PageCurlFoldCorner.bottomLeft;
  }

  static PageCurlFoldCorner _cornerForGesture(
    PageCurlGesture gesture,
    PageCurlTurnType turnType,
  ) {
    if (turnType == PageCurlTurnType.nextPageOut) {
      final useTop = switch (gesture.anchor) {
        PageCurlAnchor.top => true,
        PageCurlAnchor.middle => gesture.start.dy < gesture.pageSize.height / 2,
        PageCurlAnchor.bottom => false,
      };
      return useTop
          ? PageCurlFoldCorner.topRight
          : PageCurlFoldCorner.bottomRight;
    }

    return PageCurlFoldCorner.bottomRight;
  }

  static Offset _contactPointFor({
    required PageCurlGesture gesture,
    required PageCurlTurnType turnType,
    required PageCurlMotionPhase phase,
    required double width,
    required double height,
  }) {
    final touchY = _touchYFor(
      gesture: gesture,
      turnType: turnType,
      height: height,
    );
    if (phase == PageCurlMotionPhase.completion) {
      return Offset(
        _snap(gesture.current.dx.clamp(-width * 2.75, width * 3.75)),
        _snap(touchY.clamp(0.0, height)),
      );
    }

    return Offset(
      _snap(gesture.current.dx),
      _snap(touchY.clamp(0.0, height)),
    );
  }

  static double _touchYFor({
    required PageCurlGesture gesture,
    required PageCurlTurnType turnType,
    required double height,
  }) {
    final topY = math.min(1.0, height);
    final bottomY = math.max(0.0, height - 1.0);

    if (turnType == PageCurlTurnType.previousPageIn) {
      return bottomY;
    }
    if (gesture.anchor != PageCurlAnchor.middle) {
      return switch (gesture.anchor) {
        PageCurlAnchor.top => math.max(topY, gesture.current.dy),
        PageCurlAnchor.bottom => math.min(bottomY, gesture.current.dy),
        PageCurlAnchor.middle => gesture.current.dy,
      };
    }
    return gesture.start.dy < height / 2 ? topY : bottomY;
  }

  static Offset _stableTouch(Offset touch, double width, double height) {
    const edgeInset = 0.1;

    double stable(double value, double max) {
      if (value == 0) return edgeInset;
      if (value == max) return max - edgeInset;
      return value;
    }

    return Offset(
      touch.dx >= 0 && touch.dx <= width ? stable(touch.dx, width) : touch.dx,
      touch.dy >= 0 && touch.dy <= height ? stable(touch.dy, height) : touch.dy,
    );
  }

  static Matrix4 _reflectionMatrixFor(
    _BezierPoints points,
    Offset cornerPoint,
  ) {
    final dx = cornerPoint.dx - points.control1.dx;
    final dy = points.control2.dy - cornerPoint.dy;
    final distance = math.max(0.001, math.sqrt(dx * dx + dy * dy));
    final f8 = dx / distance;
    final f9 = dy / distance;
    final a = 1 - 2 * f9 * f9;
    final b = 2 * f8 * f9;
    final c = b;
    final d = 1 - 2 * f8 * f8;
    final tx =
        points.control1.dx - (a * points.control1.dx + c * points.control1.dy);
    final ty =
        points.control1.dy - (b * points.control1.dx + d * points.control1.dy);

    return Matrix4.fromList([
      a,
      b,
      0,
      0,
      c,
      d,
      0,
      0,
      0,
      0,
      1,
      0,
      tx,
      ty,
      0,
      1,
    ]);
  }

  static Offset _cornerPoint(
    PageCurlFoldCorner corner,
    double width,
    double height,
  ) {
    return switch (corner) {
      PageCurlFoldCorner.topLeft => Offset.zero,
      PageCurlFoldCorner.topRight => Offset(width, 0),
      PageCurlFoldCorner.middleLeft => Offset(0, height / 2),
      PageCurlFoldCorner.middleRight => Offset(width, height / 2),
      PageCurlFoldCorner.bottomLeft => Offset(0, height),
      PageCurlFoldCorner.bottomRight => Offset(width, height),
    };
  }

  static double _snap(num value) {
    return (value * 2).roundToDouble() / 2;
  }
}

class _BezierPoints {
  const _BezierPoints({
    required this.touch,
    required this.control1,
    required this.control2,
    required this.start1,
    required this.start2,
    required this.end1,
    required this.end2,
    required this.vertex1,
    required this.vertex2,
  });

  factory _BezierPoints.fromTouch({
    required Offset cornerPoint,
    required Offset touch,
    required double width,
    required double height,
  }) {
    var stableTouch = touch;
    var points = _BezierPoints._calculate(cornerPoint, stableTouch);

    for (var attempt = 0;
        attempt < 3 &&
            stableTouch.dx > 0 &&
            stableTouch.dx < width &&
            (points.start1.dx < 0 || points.start1.dx > width);
        attempt++) {
      final correctedStartX =
          points.start1.dx < 0 ? width - points.start1.dx : points.start1.dx;
      final horizontalDistance = (cornerPoint.dx - stableTouch.dx).abs();
      if (horizontalDistance <= 0.001 || correctedStartX.abs() <= 0.001) {
        break;
      }
      final touchX =
          (cornerPoint.dx - width * horizontalDistance / correctedStartX).abs();
      final touchY = (cornerPoint.dy -
              (cornerPoint.dx - touchX).abs() *
                  (cornerPoint.dy - stableTouch.dy).abs() /
                  horizontalDistance)
          .abs();
      stableTouch = Offset(
        touchX.clamp(0.0, width).toDouble(),
        touchY.clamp(0.0, height).toDouble(),
      );
      points = _BezierPoints._calculate(cornerPoint, stableTouch);
    }

    return points;
  }

  factory _BezierPoints._calculate(Offset cornerPoint, Offset touch) {
    final middleX = (touch.dx + cornerPoint.dx) / 2;
    final middleY = (touch.dy + cornerPoint.dy) / 2;
    final control1 = Offset(
      (middleX -
              math.pow(cornerPoint.dy - middleY, 2) /
                  _nonZero(cornerPoint.dx - middleX))
          .toDouble(),
      cornerPoint.dy,
    );
    final control2 = Offset(
      cornerPoint.dx,
      (middleY -
              math.pow(cornerPoint.dx - middleX, 2) /
                  _nonZero(cornerPoint.dy - middleY))
          .toDouble(),
    );
    final start1 = Offset(
      control1.dx - (cornerPoint.dx - control1.dx) / 2,
      cornerPoint.dy,
    );
    final start2 = Offset(
      cornerPoint.dx,
      control2.dy - (cornerPoint.dy - control2.dy) / 2,
    );
    final end1 = _lineIntersection(touch, control1, start1, start2);
    final end2 = _lineIntersection(touch, control2, start1, start2);
    final vertex1 = Offset(
      (start1.dx + 2 * control1.dx + end1.dx) / 4,
      (start1.dy + 2 * control1.dy + end1.dy) / 4,
    );
    final vertex2 = Offset(
      (start2.dx + 2 * control2.dx + end2.dx) / 4,
      (start2.dy + 2 * control2.dy + end2.dy) / 4,
    );

    return _BezierPoints(
      touch: touch,
      control1: control1,
      control2: control2,
      start1: start1,
      start2: start2,
      end1: end1,
      end2: end2,
      vertex1: vertex1,
      vertex2: vertex2,
    );
  }

  final Offset touch;
  final Offset control1;
  final Offset control2;
  final Offset start1;
  final Offset start2;
  final Offset end1;
  final Offset end2;
  final Offset vertex1;
  final Offset vertex2;

  static double _nonZero(double value) {
    if (value.abs() >= 0.001) return value;
    return value.isNegative ? -0.001 : 0.001;
  }

  static Offset _lineIntersection(
    Offset p1,
    Offset p2,
    Offset p3,
    Offset p4,
  ) {
    final a1 = (p2.dy - p1.dy) / _nonZero(p2.dx - p1.dx);
    final b1 = (p1.dx * p2.dy - p2.dx * p1.dy) / _nonZero(p1.dx - p2.dx);
    final a2 = (p4.dy - p3.dy) / _nonZero(p4.dx - p3.dx);
    final b2 = (p3.dx * p4.dy - p4.dx * p3.dy) / _nonZero(p3.dx - p4.dx);
    final x = (b2 - b1) / _nonZero(a1 - a2);
    return Offset(x, a1 * x + b1);
  }
}
