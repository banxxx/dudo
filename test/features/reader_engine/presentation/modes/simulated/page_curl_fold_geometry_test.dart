import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_controller.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_fold_geometry.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_gesture.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('locked previous-page reverse drag remains an active curl', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(20, 260),
      current: const Offset(5, 260),
      lockedDirection: PageCurlDirection.previous,
    );

    expect(gesture.progress, 0);
    expect(gesture.isTurning, isTrue);
  });

  test('stationary gesture is not an active curl', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(20, 260),
      current: const Offset(20, 260),
      lockedDirection: PageCurlDirection.previous,
    );

    expect(gesture.progress, 0);
    expect(gesture.isTurning, isFalse);
  });

  test('nextPageOut builds separate bezier corner surfaces', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(300, 430),
      current: const Offset(150, 360),
    );

    final geometry = PageCurlBezierGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.nextPageOut,
      pageSize: const Size(320, 520),
    );

    expect(geometry.corner, PageCurlFoldCorner.bottomRight);
    expect(geometry.foldPath.getBounds().isEmpty, isFalse);
    expect(geometry.backPath.getBounds().isEmpty, isFalse);
    expect(geometry.currentPagePath.getBounds().isEmpty, isFalse);
    expect(geometry.foldCurvePath.getBounds().isEmpty, isFalse);
    expect(geometry.outerEdgePath.getBounds().isEmpty, isFalse);
    expect(geometry.backPath.contains(geometry.touch), isTrue);
  });

  test('previousPageIn builds a right-side bezier entering page', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(20, 430),
      current: const Offset(170, 360),
    );

    final geometry = PageCurlBezierGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.previousPageIn,
      pageSize: const Size(320, 520),
    );

    expect(geometry.corner, PageCurlFoldCorner.bottomRight);
    expect(geometry.foldPath.getBounds().isEmpty, isFalse);
    expect(geometry.backPath.getBounds().isEmpty, isFalse);
    expect(geometry.currentPagePath.getBounds().isEmpty, isFalse);
    expect(geometry.isRightCorner, isTrue);
  });

  test('middle next-page drag maps to stable top and bottom corners', () {
    PageCurlBezierGeometry build(double startY) {
      final gesture = PageCurlGesture.fromPoints(
        pageSize: const Size(320, 520),
        start: Offset(300, startY),
        current: const Offset(170, 260),
      );
      return PageCurlBezierGeometry.fromGesture(
        gesture: gesture,
        turnType: PageCurlTurnType.nextPageOut,
        pageSize: const Size(320, 520),
      );
    }

    final upperMiddle = build(210);
    final lowerMiddle = build(300);

    expect(upperMiddle.corner, PageCurlFoldCorner.topRight);
    expect(upperMiddle.touch.dy, 1);
    expect(lowerMiddle.corner, PageCurlFoldCorner.bottomRight);
    expect(lowerMiddle.touch.dy, 519);
  });

  test('previous-page drag uses the bottom-right retreat path', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(20, 260),
      current: const Offset(170, 260),
    );

    final geometry = PageCurlBezierGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.previousPageIn,
      pageSize: const Size(320, 520),
    );

    expect(gesture.anchor, PageCurlAnchor.middle);
    expect(geometry.corner, PageCurlFoldCorner.bottomRight);
    expect(geometry.touch.dy, 519);
  });

  test('completion keeps moving the touch past screen edges', () {
    PageCurlBezierGeometry build({
      required PageCurlTurnType turnType,
      required Offset start,
      required Offset current,
    }) {
      final gesture = PageCurlGesture.fromPoints(
        pageSize: const Size(320, 520),
        start: start,
        current: current,
      );
      return PageCurlBezierGeometry.fromGesture(
        gesture: gesture,
        turnType: turnType,
        phase: PageCurlMotionPhase.completion,
        pageSize: const Size(320, 520),
      );
    }

    final next = build(
      turnType: PageCurlTurnType.nextPageOut,
      start: const Offset(320, 430),
      current: const Offset(-328, 430),
    );
    final previous = build(
      turnType: PageCurlTurnType.previousPageIn,
      start: const Offset(0, 260),
      current: const Offset(648, 260),
    );

    expect(next.touch.dx, lessThan(0));
    expect(previous.touch.dx, greaterThan(320));
  });

  test('bezier correction keeps the horizontal start point on the page', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(300, 430),
      current: const Offset(10, 430),
    );

    final geometry = PageCurlBezierGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.nextPageOut,
      pageSize: const Size(320, 520),
    );

    expect(geometry.start1.dx, greaterThanOrEqualTo(0));
    expect(geometry.start1.dx, lessThanOrEqualTo(320));
  });
}
