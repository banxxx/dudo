import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'page_curl_gesture.dart';
import 'page_curl_quality.dart';

enum PageCurlCorner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class PageCurlGeometry {
  const PageCurlGeometry({
    required this.pageSize,
    required this.direction,
    required this.anchor,
    required this.corner,
    required this.progress,
    required this.unturnedPath,
    required this.turningPath,
    required this.foldedPath,
    required this.foldLineStart,
    required this.foldLineEnd,
    required this.foldCurvePath,
    required this.foldCurveControl,
    required this.outerEdgePath,
    required this.contactShadowCenter,
    required this.reflectionMatrix,
    required this.qualityStripCount,
  });

  factory PageCurlGeometry.fromGesture({
    required PageCurlGesture gesture,
    required PageCurlQuality quality,
    required Size imageSize,
  }) {
    final pageSize = gesture.pageSize;
    final width = math.max(1.0, pageSize.width);
    final height = math.max(1.0, pageSize.height);
    final pageRect = Rect.fromLTWH(0, 0, width, height);
    final progress = gesture.progress.clamp(0.0, 1.0).toDouble();
    final corner = _cornerForGesture(gesture);
    final cornerPoint = _cornerPoint(corner, width, height);
    final contactPoint = _contactPointFor(
      gesture: gesture,
      cornerPoint: cornerPoint,
      width: width,
      height: height,
      progress: progress,
    );
    final fold = _foldLineFor(
      cornerPoint: cornerPoint,
      contactPoint: contactPoint,
      pageRect: pageRect,
    );
    final turningPolygon = _clipPolygonByLine(
      polygon: _pagePolygon(width, height),
      linePoint: fold.midpoint,
      lineDirection: fold.direction,
      keepPoint: cornerPoint,
    );
    final foldCurveControl = _curveControlForEdge(
      start: fold.start,
      end: fold.end,
      toward: contactPoint,
      pageRect: pageRect,
      progress: progress,
      strengthScale: 0.9,
    );
    final foldCurvePath = Path()
      ..moveTo(fold.start.dx, fold.start.dy)
      ..quadraticBezierTo(
        foldCurveControl.dx,
        foldCurveControl.dy,
        fold.end.dx,
        fold.end.dy,
      );
    final turningPath = _curvedPathFromPolygon(
      polygon: turningPolygon,
      contactPoint: contactPoint,
      pageRect: pageRect,
      progress: progress,
    );
    final foldedPolygon = turningPolygon
        .map(
          (point) => _reflectPoint(
            point: point,
            linePoint: fold.midpoint,
            lineUnit: fold.unitDirection,
          ),
        )
        .toList();
    final foldedPath = _curvedPathFromPolygon(
      polygon: foldedPolygon,
      contactPoint: contactPoint,
      pageRect: pageRect,
      progress: progress,
    );
    final fullPath = Path()..addRect(pageRect);
    final unturnedPath = Path.combine(
      PathOperation.difference,
      fullPath,
      turningPath,
    );

    return PageCurlGeometry(
      pageSize: pageSize,
      direction: gesture.direction,
      anchor: gesture.anchor,
      corner: corner,
      progress: progress,
      unturnedPath: unturnedPath,
      turningPath: turningPath,
      foldedPath: foldedPath,
      foldLineStart: fold.start,
      foldLineEnd: fold.end,
      foldCurvePath: foldCurvePath,
      foldCurveControl: foldCurveControl,
      outerEdgePath: _outerEdgePathFor(foldedPolygon, contactPoint),
      contactShadowCenter: contactPoint,
      reflectionMatrix: _reflectionMatrix(
        linePoint: fold.midpoint,
        lineUnit: fold.unitDirection,
      ),
      qualityStripCount: quality.stripCount,
    );
  }

  final Size pageSize;
  final PageCurlDirection direction;
  final PageCurlAnchor anchor;
  final PageCurlCorner corner;
  final double progress;
  final Path unturnedPath;
  final Path turningPath;
  final Path foldedPath;
  final Offset foldLineStart;
  final Offset foldLineEnd;
  final Path foldCurvePath;
  final Offset foldCurveControl;
  final Path outerEdgePath;
  final Offset contactShadowCenter;
  final Matrix4 reflectionMatrix;
  final int qualityStripCount;

  bool get isTopCorner {
    return corner == PageCurlCorner.topLeft ||
        corner == PageCurlCorner.topRight;
  }

  bool get isRightCorner {
    return corner == PageCurlCorner.topRight ||
        corner == PageCurlCorner.bottomRight;
  }

  static PageCurlCorner _cornerForGesture(PageCurlGesture gesture) {
    final useTop = switch (gesture.anchor) {
      PageCurlAnchor.top => true,
      PageCurlAnchor.bottom => false,
      PageCurlAnchor.middle => gesture.current.dy < gesture.pageSize.height / 2,
    };

    return switch ((gesture.direction, useTop)) {
      (PageCurlDirection.next, true) => PageCurlCorner.topRight,
      (PageCurlDirection.next, false) => PageCurlCorner.bottomRight,
      (PageCurlDirection.previous, true) => PageCurlCorner.topLeft,
      (PageCurlDirection.previous, false) => PageCurlCorner.bottomLeft,
    };
  }

  static Offset _cornerPoint(
      PageCurlCorner corner, double width, double height) {
    return switch (corner) {
      PageCurlCorner.topLeft => Offset.zero,
      PageCurlCorner.topRight => Offset(width, 0),
      PageCurlCorner.bottomLeft => Offset(0, height),
      PageCurlCorner.bottomRight => Offset(width, height),
    };
  }

  static Offset _contactPointFor({
    required PageCurlGesture gesture,
    required Offset cornerPoint,
    required double width,
    required double height,
    required double progress,
  }) {
    final dragPoint = Offset(
      gesture.current.dx.clamp(0.0, width).toDouble(),
      gesture.current.dy.clamp(0.0, height).toDouble(),
    );
    final minTravel = width * (0.08 + progress * 0.04);
    final vector = dragPoint - cornerPoint;
    if (vector.distance >= minTravel) return dragPoint;

    final fallbackX = switch (gesture.direction) {
      PageCurlDirection.next => cornerPoint.dx - minTravel,
      PageCurlDirection.previous => cornerPoint.dx + minTravel,
    };
    final fallbackY = switch (gesture.anchor) {
      PageCurlAnchor.top => cornerPoint.dy + minTravel * 0.35,
      PageCurlAnchor.bottom => cornerPoint.dy - minTravel * 0.35,
      PageCurlAnchor.middle => cornerPoint.dy,
    };

    return Offset(
      fallbackX.clamp(0.0, width).toDouble(),
      fallbackY.clamp(0.0, height).toDouble(),
    );
  }

  static _FoldLine _foldLineFor({
    required Offset cornerPoint,
    required Offset contactPoint,
    required Rect pageRect,
  }) {
    final delta = contactPoint - cornerPoint;
    final safeDelta = delta.distance < 0.001 ? const Offset(-1, 1) : delta;
    final midpoint = Offset(
      (cornerPoint.dx + contactPoint.dx) / 2,
      (cornerPoint.dy + contactPoint.dy) / 2,
    );
    final direction = Offset(-safeDelta.dy, safeDelta.dx);
    final intersections = _lineRectIntersections(
      point: midpoint,
      direction: direction,
      rect: pageRect,
    );

    if (intersections.length >= 2) {
      return _FoldLine(
        start: intersections[0],
        end: intersections[1],
        midpoint: midpoint,
        direction: direction,
      );
    }

    final unit = _normalize(direction);
    return _FoldLine(
      start: midpoint - unit * pageRect.longestSide,
      end: midpoint + unit * pageRect.longestSide,
      midpoint: midpoint,
      direction: direction,
    );
  }

  static List<Offset> _pagePolygon(double width, double height) {
    return [
      Offset.zero,
      Offset(width, 0),
      Offset(width, height),
      Offset(0, height),
    ];
  }

  static List<Offset> _clipPolygonByLine({
    required List<Offset> polygon,
    required Offset linePoint,
    required Offset lineDirection,
    required Offset keepPoint,
  }) {
    final keepSide = _lineSide(keepPoint, linePoint, lineDirection);
    final clipped = <Offset>[];

    for (var index = 0; index < polygon.length; index++) {
      final current = polygon[index];
      final next = polygon[(index + 1) % polygon.length];
      final currentInside =
          _lineSide(current, linePoint, lineDirection) * keepSide >= -0.001;
      final nextInside =
          _lineSide(next, linePoint, lineDirection) * keepSide >= -0.001;

      if (currentInside && nextInside) {
        clipped.add(next);
      } else if (currentInside && !nextInside) {
        clipped.add(_segmentLineIntersection(
          current,
          next,
          linePoint,
          lineDirection,
        ));
      } else if (!currentInside && nextInside) {
        clipped
          ..add(_segmentLineIntersection(
            current,
            next,
            linePoint,
            lineDirection,
          ))
          ..add(next);
      }
    }

    return clipped;
  }

  static Path _pathFromPolygon(List<Offset> polygon) {
    final path = Path();
    if (polygon.isEmpty) return path;
    path.moveTo(polygon.first.dx, polygon.first.dy);
    for (final point in polygon.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    return path;
  }

  static Path _curvedPathFromPolygon({
    required List<Offset> polygon,
    required Offset contactPoint,
    required Rect pageRect,
    required double progress,
  }) {
    final path = Path();
    if (polygon.isEmpty) return path;
    if (polygon.length < 3 || progress <= 0.001) {
      return _pathFromPolygon(polygon);
    }

    path.moveTo(polygon.first.dx, polygon.first.dy);
    for (var index = 0; index < polygon.length; index++) {
      final current = polygon[index];
      final next = polygon[(index + 1) % polygon.length];
      final control = _curveControlForEdge(
        start: current,
        end: next,
        toward: contactPoint,
        pageRect: pageRect,
        progress: progress,
        strengthScale: 0.55,
      );
      path.quadraticBezierTo(control.dx, control.dy, next.dx, next.dy);
    }
    path.close();
    return path;
  }

  static Offset _curveControlForEdge({
    required Offset start,
    required Offset end,
    required Offset toward,
    required Rect pageRect,
    required double progress,
    required double strengthScale,
  }) {
    final edge = end - start;
    final length = edge.distance;
    if (length < 0.001) return start;

    final midpoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
    final normal = Offset(-edge.dy / length, edge.dx / length);
    final positive = midpoint + normal;
    final negative = midpoint - normal;
    final direction = (positive - toward).distanceSquared <
            (negative - toward).distanceSquared
        ? normal
        : -normal;
    final maxCurve = math.min(pageRect.width, pageRect.height) * 0.075;
    final strength = math.min(length * 0.18, maxCurve) *
        (0.35 + progress * 0.65) *
        strengthScale;

    return midpoint + direction * strength;
  }

  static Path _outerEdgePathFor(
    List<Offset> foldedPolygon,
    Offset contactPoint,
  ) {
    if (foldedPolygon.isEmpty) return Path();

    final sorted = [...foldedPolygon]..sort((a, b) {
        final da = (a - contactPoint).distanceSquared;
        final db = (b - contactPoint).distanceSquared;
        return da.compareTo(db);
      });
    final first = sorted.first;
    final second = sorted.length > 1 ? sorted[1] : sorted.first;
    final control = Offset(
      (first.dx + second.dx + contactPoint.dx) / 3,
      (first.dy + second.dy + contactPoint.dy) / 3,
    );

    return Path()
      ..moveTo(first.dx, first.dy)
      ..quadraticBezierTo(control.dx, control.dy, second.dx, second.dy);
  }

  static Matrix4 _reflectionMatrix({
    required Offset linePoint,
    required Offset lineUnit,
  }) {
    final ux = lineUnit.dx;
    final uy = lineUnit.dy;
    final a = 2 * ux * ux - 1;
    final b = 2 * ux * uy;
    final c = 2 * ux * uy;
    final d = 2 * uy * uy - 1;
    final tx = linePoint.dx - (a * linePoint.dx + c * linePoint.dy);
    final ty = linePoint.dy - (b * linePoint.dx + d * linePoint.dy);

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

  static List<Offset> _lineRectIntersections({
    required Offset point,
    required Offset direction,
    required Rect rect,
  }) {
    final intersections = <Offset>[];
    final dx = direction.dx;
    final dy = direction.dy;

    void addIfInside(double t) {
      final candidate = point + direction * t;
      if (candidate.dx >= rect.left - 0.001 &&
          candidate.dx <= rect.right + 0.001 &&
          candidate.dy >= rect.top - 0.001 &&
          candidate.dy <= rect.bottom + 0.001) {
        final normalized = Offset(
          candidate.dx.clamp(rect.left, rect.right).toDouble(),
          candidate.dy.clamp(rect.top, rect.bottom).toDouble(),
        );
        if (!intersections.any((p) => (p - normalized).distance < 0.5)) {
          intersections.add(normalized);
        }
      }
    }

    if (dx.abs() > 0.001) {
      addIfInside((rect.left - point.dx) / dx);
      addIfInside((rect.right - point.dx) / dx);
    }
    if (dy.abs() > 0.001) {
      addIfInside((rect.top - point.dy) / dy);
      addIfInside((rect.bottom - point.dy) / dy);
    }

    intersections.sort((a, b) {
      final da = (a - point).distanceSquared;
      final db = (b - point).distanceSquared;
      return da.compareTo(db);
    });
    if (intersections.length > 2) {
      return [intersections.first, intersections.last];
    }
    return intersections;
  }

  static Offset _segmentLineIntersection(
    Offset segmentStart,
    Offset segmentEnd,
    Offset linePoint,
    Offset lineDirection,
  ) {
    final segment = segmentEnd - segmentStart;
    final denominator = _cross(segment, lineDirection);
    if (denominator.abs() < 0.001) return segmentStart;
    final t = _cross(linePoint - segmentStart, lineDirection) / denominator;
    return segmentStart + segment * t.clamp(0.0, 1.0);
  }

  static Offset _reflectPoint({
    required Offset point,
    required Offset linePoint,
    required Offset lineUnit,
  }) {
    final relative = point - linePoint;
    final projection = lineUnit * _dot(relative, lineUnit);
    final perpendicular = relative - projection;
    return linePoint + projection - perpendicular;
  }

  static double _lineSide(
    Offset point,
    Offset linePoint,
    Offset lineDirection,
  ) {
    return _cross(lineDirection, point - linePoint);
  }

  static Offset _normalize(Offset value) {
    final distance = value.distance;
    if (distance < 0.001) return const Offset(1, 0);
    return Offset(value.dx / distance, value.dy / distance);
  }

  static double _cross(Offset a, Offset b) {
    return a.dx * b.dy - a.dy * b.dx;
  }

  static double _dot(Offset a, Offset b) {
    return a.dx * b.dx + a.dy * b.dy;
  }
}

class _FoldLine {
  const _FoldLine({
    required this.start,
    required this.end,
    required this.midpoint,
    required this.direction,
  });

  final Offset start;
  final Offset end;
  final Offset midpoint;
  final Offset direction;

  Offset get unitDirection {
    final distance = direction.distance;
    if (distance < 0.001) return const Offset(1, 0);
    return Offset(direction.dx / distance, direction.dy / distance);
  }
}
