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
    expect(geometry.outerEdgePath.getBounds().left, 170);
    expect(geometry.foldLineStart.dx, 245);
    expect(geometry.foldLineStart.dx, geometry.foldLineEnd.dx);
    expect(geometry.foldLineStart.dy, 0);
    expect(geometry.foldLineEnd.dy, 520);
    expect(geometry.foldCurvePath.getBounds().width, 0);
    expect(geometry.turningPath.getBounds().left, geometry.foldLineStart.dx);
    expect(geometry.foldedPath.getBounds().isEmpty, isFalse);
  });

  test('nextPageOut middle page edge follows the pointer x position', () {
    PageCurlFoldGeometry build(double currentX) {
      final gesture = PageCurlGesture.fromPoints(
        pageSize: const Size(320, 520),
        start: const Offset(300, 260),
        current: Offset(currentX, 260),
      );
      return PageCurlFoldGeometry.fromGesture(
        gesture: gesture,
        turnType: PageCurlTurnType.nextPageOut,
        pageSize: const Size(320, 520),
      );
    }

    expect(build(240).outerEdgePath.getBounds().left, 240);
    expect(build(240).foldLineStart.dx, 280);
    expect(build(120).outerEdgePath.getBounds().left, 120);
    expect(build(120).foldLineStart.dx, 220);
  });

  test('previousPageIn uses the same middle curl relationship as next page',
      () {
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
    expect(geometry.corner, PageCurlFoldCorner.middleRight);
    expect(geometry.foldedPath.getBounds().isEmpty, isFalse);
    expect(geometry.turningPath.getBounds().isEmpty, isFalse);
    expect(geometry.isRightCorner, isTrue);
  });

  test('previousPageIn keeps page edge left of the fold edge', () {
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

    final frontBounds = geometry.unturnedPath.getBounds();
    final turningBounds = geometry.turningPath.getBounds();
    final foldedBounds = geometry.foldedPath.getBounds();

    expect(frontBounds.left, 0);
    expect(frontBounds.right, 120);
    expect(turningBounds.left, 220);
    expect(turningBounds.right, 320);
    expect(foldedBounds.left, 120);
    expect(foldedBounds.right, 220);
    expect(geometry.outerEdgePath.getBounds().left, 120);
    expect(geometry.foldLineStart.dx, 220);
    expect(geometry.outerEdgePath.getBounds().left,
        lessThan(geometry.foldLineStart.dx));
    expect(geometry.foldLineStart.dx, geometry.foldLineEnd.dx);
  });

  test('previousPageIn completion moves the fold past the right edge', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(0, 260),
      current: const Offset(648, 260),
    );

    final geometry = PageCurlFoldGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.previousPageIn,
      pageSize: const Size(320, 520),
    );
    final frontBounds = geometry.unturnedPath.getBounds();

    expect(geometry.corner, PageCurlFoldCorner.middleRight);
    expect(frontBounds.left, 0);
    expect(frontBounds.right, 320);
    expect(geometry.foldLineStart.dx, greaterThanOrEqualTo(320));
    expect(geometry.outerEdgePath.getBounds().left, greaterThan(320));
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

  test('nextPageOut fold shadow path follows the real fold line', () {
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
    final lineBounds = Rect.fromPoints(
      geometry.foldLineStart,
      geometry.foldLineEnd,
    );
    final foldPathBounds = geometry.foldCurvePath.getBounds();

    expect((foldPathBounds.left - lineBounds.left).abs(), lessThan(1));
    expect((foldPathBounds.top - lineBounds.top).abs(), lessThan(1));
    expect((foldPathBounds.right - lineBounds.right).abs(), lessThan(1));
    expect((foldPathBounds.bottom - lineBounds.bottom).abs(), lessThan(1));
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
      current: const Offset(-340, 260),
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
