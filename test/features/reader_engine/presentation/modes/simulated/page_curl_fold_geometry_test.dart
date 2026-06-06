import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_controller.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_fold_geometry.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_gesture.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nextPageOut uses a right-side folded page model', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(300, 430),
      current: const Offset(150, 360),
    );

    final geometry = PageCurlFoldGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.nextPageOut,
      pageSize: const Size(320, 520),
    );

    expect(geometry.turnType, PageCurlTurnType.nextPageOut);
    expect(geometry.corner, PageCurlFoldCorner.bottomRight);
    expect(geometry.foldedPath.getBounds().isEmpty, isFalse);
    expect(geometry.unturnedPath.getBounds().isEmpty, isFalse);
    expect(geometry.isRightCorner, isTrue);
  });

  test('nextPageOut uses a middle cylinder model from the right side', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(300, 260),
      current: const Offset(170, 260),
    );

    final geometry = PageCurlFoldGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.nextPageOut,
      pageSize: const Size(320, 520),
    );

    expect(gesture.anchor, PageCurlAnchor.middle);
    expect(geometry.corner, PageCurlFoldCorner.middleRight);
    expect(geometry.foldLineStart.dx, geometry.foldLineEnd.dx);
    expect(geometry.foldLineStart.dy, 0);
    expect(geometry.foldLineEnd.dy, 520);
    expect(geometry.foldedPath.getBounds().isEmpty, isFalse);
  });

  test('previousPageIn uses a left-side folded page model', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(20, 430),
      current: const Offset(170, 360),
    );

    final geometry = PageCurlFoldGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.previousPageIn,
      pageSize: const Size(320, 520),
    );

    expect(geometry.turnType, PageCurlTurnType.previousPageIn);
    expect(geometry.corner, PageCurlFoldCorner.bottomLeft);
    expect(geometry.foldedPath.getBounds().isEmpty, isFalse);
    expect(geometry.turningPath.getBounds().isEmpty, isFalse);
    expect(geometry.isRightCorner, isFalse);
  });

  test('previousPageIn enters from the left with a vertical leading fold', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(20, 260),
      current: const Offset(120, 260),
    );

    final geometry = PageCurlFoldGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.previousPageIn,
      pageSize: const Size(320, 520),
    );

    final incomingBounds = geometry.foldedPath.getBounds();
    final foldBounds = geometry.turningPath.getBounds();

    expect(incomingBounds.left, 0);
    expect(incomingBounds.right, greaterThan(150));
    expect(foldBounds.left, greaterThanOrEqualTo(0));
    expect(foldBounds.width, lessThan(90));
    expect(geometry.foldLineStart.dx, geometry.foldLineEnd.dx);
  });

  test('nextPageOut keeps its corner stable across vertical pointer noise', () {
    PageCurlFoldCorner cornerFor(Offset current) {
      final gesture = PageCurlGesture.fromPoints(
        pageSize: const Size(320, 520),
        start: const Offset(300, 430),
        current: current,
      );
      return PageCurlFoldGeometry.fromGesture(
        gesture: gesture,
        turnType: PageCurlTurnType.nextPageOut,
        pageSize: const Size(320, 520),
      ).corner;
    }

    expect(cornerFor(const Offset(150, 250)), PageCurlFoldCorner.bottomRight);
    expect(cornerFor(const Offset(150, 300)), PageCurlFoldCorner.bottomRight);
  });

  test('nextPageOut folded path uses the reflected turning path', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(300, 430),
      current: const Offset(150, 360),
    );

    final geometry = PageCurlFoldGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.nextPageOut,
      pageSize: const Size(320, 520),
    );
    final reflectedTurningBounds = geometry.turningPath
        .transform(geometry.reflectionMatrix.storage)
        .getBounds();
    final foldedBounds = geometry.foldedPath.getBounds();

    expect(
        (foldedBounds.left - reflectedTurningBounds.left).abs(), lessThan(1));
    expect((foldedBounds.top - reflectedTurningBounds.top).abs(), lessThan(1));
    expect(
      (foldedBounds.right - reflectedTurningBounds.right).abs(),
      lessThan(1),
    );
    expect(
      (foldedBounds.bottom - reflectedTurningBounds.bottom).abs(),
      lessThan(1),
    );
  });

  test('nextPageOut completion moves the fold past the left edge', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(300, 430),
      current: const Offset(-20, 430),
    );

    final geometry = PageCurlFoldGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.nextPageOut,
      pageSize: const Size(320, 520),
    );
    final turningBounds = geometry.turningPath.getBounds();
    final foldedBounds = geometry.foldedPath.getBounds();

    expect(gesture.progress, 1);
    expect(geometry.foldLineStart.dx, lessThanOrEqualTo(0));
    expect(turningBounds.left, lessThanOrEqualTo(0));
    expect(turningBounds.right, greaterThanOrEqualTo(320));
    expect(foldedBounds.right, lessThanOrEqualTo(0));
  });

  test('nextPageOut middle completion moves the folded page offscreen', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(300, 260),
      current: const Offset(-20, 260),
    );

    final geometry = PageCurlFoldGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.nextPageOut,
      pageSize: const Size(320, 520),
    );
    final foldedBounds = geometry.foldedPath.getBounds();

    expect(geometry.corner, PageCurlFoldCorner.middleRight);
    expect(foldedBounds.right, lessThanOrEqualTo(0));
  });

  test('outer edge remains stable for tiny pointer changes', () {
    PageCurlFoldGeometry build(Offset current) {
      final gesture = PageCurlGesture.fromPoints(
        pageSize: const Size(320, 520),
        start: const Offset(300, 430),
        current: current,
      );
      return PageCurlFoldGeometry.fromGesture(
        gesture: gesture,
        turnType: PageCurlTurnType.nextPageOut,
        pageSize: const Size(320, 520),
      );
    }

    final first = build(const Offset(150, 360));
    final second = build(const Offset(150, 361));
    final firstBounds = first.outerEdgePath.getBounds();
    final secondBounds = second.outerEdgePath.getBounds();

    expect(firstBounds.isEmpty, isFalse);
    expect(secondBounds.isEmpty, isFalse);
    expect((firstBounds.left - secondBounds.left).abs(), lessThan(8));
    expect((firstBounds.top - secondBounds.top).abs(), lessThan(8));
  });
}
