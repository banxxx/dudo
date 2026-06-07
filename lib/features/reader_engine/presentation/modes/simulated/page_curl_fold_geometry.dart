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

class PageCurlFoldGeometry {
  const PageCurlFoldGeometry({
    required this.turnType,
    required this.pageSize,
    required this.corner,
    required this.progress,
    required this.unturnedPath,
    required this.turningPath,
    required this.foldedPath,
    required this.foldLineStart,
    required this.foldLineEnd,
    required this.foldCurvePath,
    required this.outerEdgePath,
    required this.contactShadowCenter,
    required this.reflectionMatrix,
  });

  factory PageCurlFoldGeometry.fromGesture({
    required PageCurlGesture gesture,
    required PageCurlTurnType turnType,
    PageCurlMotionPhase phase = PageCurlMotionPhase.interactive,
    required Size pageSize,
  }) {
    return switch (turnType) {
      PageCurlTurnType.nextPageOut => _buildNextPageOut(
          gesture: gesture,
          phase: phase,
          pageSize: pageSize,
        ),
      PageCurlTurnType.previousPageIn => _buildPreviousPageIn(
          gesture: gesture,
          pageSize: pageSize,
        ),
    };
  }

  factory PageCurlFoldGeometry._({
    required PageCurlTurnType turnType,
    required Size pageSize,
    required PageCurlFoldCorner corner,
    required double progress,
    required Path unturnedPath,
    required Path turningPath,
    required Path foldedPath,
    required Offset foldLineStart,
    required Offset foldLineEnd,
    required Path foldCurvePath,
    required Path outerEdgePath,
    required Offset contactShadowCenter,
    required Matrix4 reflectionMatrix,
  }) {
    return PageCurlFoldGeometry(
      turnType: turnType,
      pageSize: pageSize,
      corner: corner,
      progress: progress,
      unturnedPath: unturnedPath,
      turningPath: turningPath,
      foldedPath: foldedPath,
      foldLineStart: foldLineStart,
      foldLineEnd: foldLineEnd,
      foldCurvePath: foldCurvePath,
      outerEdgePath: outerEdgePath,
      contactShadowCenter: contactShadowCenter,
      reflectionMatrix: reflectionMatrix,
    );
  }

  static PageCurlFoldGeometry _buildNextPageOut({
    required PageCurlGesture gesture,
    required PageCurlMotionPhase phase,
    required Size pageSize,
  }) {
    if (gesture.anchor == PageCurlAnchor.middle) {
      return _buildNextPageOutMiddle(
        gesture: gesture,
        pageSize: pageSize,
      );
    }

    final width = math.max(1.0, pageSize.width);
    final height = math.max(1.0, pageSize.height);
    final pageRect = Rect.fromLTWH(0, 0, width, height);
    final progress = gesture.progress.clamp(0.001, 1.0).toDouble();
    final corner = _cornerForGesture(gesture);
    final cornerPoint = _cornerPoint(corner, width, height);
    final contactPoint = _contactPointFor(
      gesture: gesture,
      phase: phase,
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
    final foldCurvePath = Path()
      ..moveTo(fold.start.dx, fold.start.dy)
      ..lineTo(fold.end.dx, fold.end.dy);
    final turningPath = _curvedPathFromPolygon(
      polygon: turningPolygon,
      contactPoint: contactPoint,
      pageRect: pageRect,
      progress: progress,
    );
    final reflectionMatrix = _reflectionMatrix(
      linePoint: fold.midpoint,
      lineUnit: fold.unitDirection,
    );
    final foldedPath = turningPath.transform(reflectionMatrix.storage);
    final fullPath = Path()..addRect(pageRect);
    final unturnedPath = Path.combine(
      PathOperation.difference,
      fullPath,
      turningPath,
    );

    return PageCurlFoldGeometry._(
      turnType: PageCurlTurnType.nextPageOut,
      pageSize: pageSize,
      corner: corner,
      progress: progress,
      unturnedPath: unturnedPath,
      turningPath: turningPath,
      foldedPath: foldedPath,
      foldLineStart: fold.start,
      foldLineEnd: fold.end,
      foldCurvePath: foldCurvePath,
      outerEdgePath: _outerEdgePathFor(
        turningPolygon: turningPolygon,
        cornerPoint: cornerPoint,
        contactPoint: contactPoint,
        foldLinePoint: fold.midpoint,
        foldLineUnit: fold.unitDirection,
        pageRect: pageRect,
        progress: progress,
      ),
      contactShadowCenter: contactPoint,
      reflectionMatrix: reflectionMatrix,
    );
  }

  static PageCurlFoldGeometry _buildPreviousPageIn({
    required PageCurlGesture gesture,
    required Size pageSize,
  }) {
    final width = math.max(1.0, pageSize.width);
    final height = math.max(1.0, pageSize.height);
    final rawProgress = gesture.progress.clamp(0.001, 1.0).toDouble();
    final edgeX = _snap(gesture.current.dx.clamp(-width * 3.5, width * 3.5));
    final visibleEdgeX = edgeX.clamp(0.0, width).toDouble();
    final foldX = _snap(((edgeX + width) / 2).clamp(-width * 1.25, width * 2));
    final visibleFoldX = foldX.clamp(0.0, width).toDouble();
    final centerBias = ((gesture.start.dy - height / 2) / math.max(1.0, height))
        .clamp(-0.10, 0.10)
        .toDouble();
    final centerY = height / 2 + centerBias * height;

    final foldCurvePath = Path()
      ..moveTo(foldX, 0)
      ..lineTo(foldX, height);
    final frontPath = Path()
      ..moveTo(0, 0)
      ..lineTo(visibleEdgeX, 0)
      ..lineTo(visibleEdgeX, height)
      ..lineTo(0, height)
      ..close();
    final turningPath = Path()
      ..moveTo(visibleFoldX, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height)
      ..lineTo(visibleFoldX, height)
      ..close();
    final reflectionMatrix = _reflectionMatrix(
      linePoint: Offset(foldX, centerY),
      lineUnit: const Offset(0, 1),
    );
    final foldedPath = turningPath.transform(reflectionMatrix.storage);
    final outerEdgePath = Path()
      ..moveTo(edgeX, 0)
      ..lineTo(edgeX, height);

    return PageCurlFoldGeometry._(
      turnType: PageCurlTurnType.previousPageIn,
      pageSize: pageSize,
      corner: PageCurlFoldCorner.middleRight,
      progress: rawProgress,
      unturnedPath: frontPath,
      turningPath: turningPath,
      foldedPath: foldedPath,
      foldLineStart: Offset(foldX, 0),
      foldLineEnd: Offset(foldX, height),
      foldCurvePath: foldCurvePath,
      outerEdgePath: outerEdgePath,
      contactShadowCenter: Offset(foldX, centerY),
      reflectionMatrix: reflectionMatrix,
    );
  }

  static PageCurlFoldGeometry _buildNextPageOutMiddle({
    required PageCurlGesture gesture,
    required Size pageSize,
  }) {
    final width = math.max(1.0, pageSize.width);
    final height = math.max(1.0, pageSize.height);
    final rawProgress = gesture.progress.clamp(0.001, 1.0).toDouble();
    final edgeX = _snap(gesture.current.dx.clamp(-width * 3.5, width));
    final foldX = _snap(((edgeX + width) / 2).clamp(-width * 1.25, width));
    final centerBias = ((gesture.start.dy - height / 2) / math.max(1.0, height))
        .clamp(-0.10, 0.10)
        .toDouble();
    final centerY = height / 2 + centerBias * height;
    final rightX = width;
    final foldCurvePath = Path()
      ..moveTo(foldX, 0)
      ..lineTo(foldX, height);
    final unturnedPath = Path()
      ..moveTo(0, 0)
      ..lineTo(foldX.clamp(0.0, width).toDouble(), 0)
      ..lineTo(foldX.clamp(0.0, width).toDouble(), height)
      ..lineTo(0, height)
      ..close();
    final turningPath = Path()
      ..moveTo(foldX, 0)
      ..lineTo(rightX, 0)
      ..lineTo(rightX, height)
      ..lineTo(foldX, height)
      ..lineTo(foldX, 0)
      ..close();
    final reflectionMatrix = _reflectionMatrix(
      linePoint: Offset(foldX, centerY),
      lineUnit: const Offset(0, 1),
    );
    final foldedPath = turningPath.transform(reflectionMatrix.storage);
    final outerEdgePath = Path()
      ..moveTo(edgeX, 0)
      ..lineTo(edgeX, height);

    return PageCurlFoldGeometry._(
      turnType: PageCurlTurnType.nextPageOut,
      pageSize: pageSize,
      corner: PageCurlFoldCorner.middleRight,
      progress: rawProgress,
      unturnedPath: unturnedPath,
      turningPath: turningPath,
      foldedPath: foldedPath,
      foldLineStart: Offset(foldX, 0),
      foldLineEnd: Offset(foldX, height),
      foldCurvePath: foldCurvePath,
      outerEdgePath: outerEdgePath,
      contactShadowCenter: Offset(foldX, centerY),
      reflectionMatrix: reflectionMatrix,
    );
  }

  final PageCurlTurnType turnType;
  final Size pageSize;
  final PageCurlFoldCorner corner;
  final double progress;
  final Path unturnedPath;
  final Path turningPath;
  final Path foldedPath;
  final Offset foldLineStart;
  final Offset foldLineEnd;
  final Path foldCurvePath;
  final Path outerEdgePath;
  final Offset contactShadowCenter;
  final Matrix4 reflectionMatrix;

  bool get isRightCorner {
    return corner == PageCurlFoldCorner.topRight ||
        corner == PageCurlFoldCorner.middleRight ||
        corner == PageCurlFoldCorner.bottomRight;
  }

  static PageCurlFoldCorner _cornerForGesture(PageCurlGesture gesture) {
    final useTop = switch (gesture.anchor) {
      PageCurlAnchor.top => true,
      PageCurlAnchor.bottom => false,
      PageCurlAnchor.middle => gesture.start.dy < gesture.pageSize.height / 2,
    };

    return switch ((gesture.direction, useTop)) {
      (PageCurlDirection.next, true) => PageCurlFoldCorner.topRight,
      (PageCurlDirection.next, false) => PageCurlFoldCorner.bottomRight,
      (PageCurlDirection.previous, true) => PageCurlFoldCorner.topLeft,
      (PageCurlDirection.previous, false) => PageCurlFoldCorner.bottomLeft,
    };
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

  static Offset _contactPointFor({
    required PageCurlGesture gesture,
    required PageCurlMotionPhase phase,
    required Offset cornerPoint,
    required double width,
    required double height,
    required double progress,
  }) {
    if (phase == PageCurlMotionPhase.interactive) {
      return _interactiveContactPointFor(
        gesture: gesture,
        cornerPoint: cornerPoint,
        width: width,
        height: height,
      );
    }

    final direction = switch (gesture.direction) {
      PageCurlDirection.next => -1.0,
      PageCurlDirection.previous => 1.0,
    };
    final travel = width * _completionTravelRatio(progress);
    final stableY = _stableDragY(
      gesture: gesture,
      cornerY: cornerPoint.dy,
      height: height,
      progress: progress,
    );

    return Offset(
      _snap((cornerPoint.dx + direction * travel)
          .clamp(-width * 2.75, width * 3.75)),
      _snap(stableY.clamp(0.0, height)),
    );
  }

  static Offset _interactiveContactPointFor({
    required PageCurlGesture gesture,
    required Offset cornerPoint,
    required double width,
    required double height,
  }) {
    final candidate = Offset(
      gesture.current.dx.clamp(0.0, width).toDouble(),
      gesture.current.dy.clamp(0.0, height).toDouble(),
    );
    final spinePoint = Offset(0, cornerPoint.dy);
    final fromSpine = candidate - spinePoint;
    final maxDistance = math.max(1.0, width - 1);
    if (fromSpine.distance <= maxDistance) {
      return Offset(_snap(candidate.dx), _snap(candidate.dy));
    }

    final direction = _normalize(fromSpine);
    final constrained = spinePoint + direction * maxDistance;
    return Offset(
      _snap(constrained.dx.clamp(0.0, width)),
      _snap(constrained.dy.clamp(0.0, height)),
    );
  }

  static double _completionTravelRatio(double progress) {
    final p = progress.clamp(0.0, 1.0).toDouble();
    const completionTravel = 3.42;
    return p * completionTravel;
  }

  static double _stableDragY({
    required PageCurlGesture gesture,
    required double cornerY,
    required double height,
    required double progress,
  }) {
    final weightedY =
        gesture.start.dy + (gesture.current.dy - gesture.start.dy) * 0.32;
    final anchorMin = switch (gesture.anchor) {
      PageCurlAnchor.top => height * 0.05,
      PageCurlAnchor.middle => height * 0.12,
      PageCurlAnchor.bottom => height * 0.22,
    };
    final anchorMax = switch (gesture.anchor) {
      PageCurlAnchor.top => height * 0.78,
      PageCurlAnchor.middle => height * 0.88,
      PageCurlAnchor.bottom => height * 0.95,
    };
    final targetY = weightedY.clamp(anchorMin, anchorMax).toDouble();
    final pull = 0.42 + progress * 0.30;
    return _snap(cornerY + (targetY - cornerY) * pull);
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
    return path..close();
  }

  static Path _curvedPathFromPolygon({
    required List<Offset> polygon,
    required Offset contactPoint,
    required Rect pageRect,
    required double progress,
  }) {
    if (polygon.length < 3 || progress <= 0.001) {
      return _pathFromPolygon(polygon);
    }

    final path = Path()..moveTo(polygon.first.dx, polygon.first.dy);
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
    return path..close();
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

  static Path _outerEdgePathFor({
    required List<Offset> turningPolygon,
    required Offset cornerPoint,
    required Offset contactPoint,
    required Offset foldLinePoint,
    required Offset foldLineUnit,
    required Rect pageRect,
    required double progress,
  }) {
    if (turningPolygon.length < 3) return Path();

    var cornerIndex = 0;
    var cornerDistance = double.infinity;
    for (var index = 0; index < turningPolygon.length; index++) {
      final distance = (turningPolygon[index] - cornerPoint).distanceSquared;
      if (distance < cornerDistance) {
        cornerDistance = distance;
        cornerIndex = index;
      }
    }

    final previous = turningPolygon[
        (cornerIndex - 1 + turningPolygon.length) % turningPolygon.length];
    final next = turningPolygon[(cornerIndex + 1) % turningPolygon.length];
    final reflectedPrevious = _reflectPoint(
      point: previous,
      linePoint: foldLinePoint,
      lineUnit: foldLineUnit,
    );
    final reflectedCorner = _reflectPoint(
      point: cornerPoint,
      linePoint: foldLinePoint,
      lineUnit: foldLineUnit,
    );
    final reflectedNext = _reflectPoint(
      point: next,
      linePoint: foldLinePoint,
      lineUnit: foldLineUnit,
    );
    final contact = Offset(
      ((reflectedCorner.dx + contactPoint.dx) / 2)
          .clamp(
              pageRect.left - pageRect.width, pageRect.right + pageRect.width)
          .toDouble(),
      ((reflectedCorner.dy + contactPoint.dy) / 2)
          .clamp(
              pageRect.top - pageRect.height, pageRect.bottom + pageRect.height)
          .toDouble(),
    );

    final firstControl = _curveControlForEdge(
      start: reflectedPrevious,
      end: contact,
      toward: foldLinePoint,
      pageRect: pageRect,
      progress: progress,
      strengthScale: 0.8,
    );
    final secondControl = _curveControlForEdge(
      start: contact,
      end: reflectedNext,
      toward: foldLinePoint,
      pageRect: pageRect,
      progress: progress,
      strengthScale: 0.8,
    );

    return Path()
      ..moveTo(reflectedPrevious.dx, reflectedPrevious.dy)
      ..quadraticBezierTo(
          firstControl.dx, firstControl.dy, contact.dx, contact.dy)
      ..quadraticBezierTo(
        secondControl.dx,
        secondControl.dy,
        reflectedNext.dx,
        reflectedNext.dy,
      );
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

  static double _snap(num value) {
    return (value * 2).roundToDouble() / 2;
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
