import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_geometry.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_gesture.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_quality.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects right-side corners for next page curls', () {
    final topGeometry = PageCurlGeometry.fromGesture(
      gesture: PageCurlGesture.fromPoints(
        pageSize: const Size(320, 480),
        start: const Offset(310, 40),
        current: const Offset(180, 120),
      ),
      quality: PageCurlQuality.low,
      imageSize: const Size(320, 480),
    );
    final bottomGeometry = PageCurlGeometry.fromGesture(
      gesture: PageCurlGesture.fromPoints(
        pageSize: const Size(320, 480),
        start: const Offset(310, 440),
        current: const Offset(180, 360),
      ),
      quality: PageCurlQuality.low,
      imageSize: const Size(320, 480),
    );

    expect(topGeometry.corner, PageCurlCorner.topRight);
    expect(bottomGeometry.corner, PageCurlCorner.bottomRight);
    expect(topGeometry.foldedPath.getBounds(), isNot(Rect.zero));
    expect(bottomGeometry.foldedPath.getBounds(), isNot(Rect.zero));
  });

  test('selects left-side corners for previous page curls', () {
    final topGeometry = PageCurlGeometry.fromGesture(
      gesture: PageCurlGesture.fromPoints(
        pageSize: const Size(320, 480),
        start: const Offset(12, 40),
        current: const Offset(140, 120),
      ),
      quality: PageCurlQuality.low,
      imageSize: const Size(320, 480),
    );
    final bottomGeometry = PageCurlGeometry.fromGesture(
      gesture: PageCurlGesture.fromPoints(
        pageSize: const Size(320, 480),
        start: const Offset(12, 440),
        current: const Offset(140, 360),
      ),
      quality: PageCurlQuality.low,
      imageSize: const Size(320, 480),
    );

    expect(topGeometry.corner, PageCurlCorner.topLeft);
    expect(bottomGeometry.corner, PageCurlCorner.bottomLeft);
  });

  test('reflection matrix maps the original corner near the touch point', () {
    const touchPoint = Offset(180, 120);
    final geometry = PageCurlGeometry.fromGesture(
      gesture: PageCurlGesture.fromPoints(
        pageSize: const Size(320, 480),
        start: const Offset(310, 40),
        current: touchPoint,
      ),
      quality: PageCurlQuality.low,
      imageSize: const Size(320, 480),
    );

    final reflectedCorner = MatrixUtils.transformPoint(
      geometry.reflectionMatrix,
      const Offset(320, 0),
    );

    expect((reflectedCorner.dx - touchPoint.dx).abs(), lessThan(0.001));
    expect((reflectedCorner.dy - touchPoint.dy).abs(), lessThan(0.001));
    expect(geometry.contactShadowCenter, touchPoint);
  });

  test('fold crease uses a curved control point', () {
    final geometry = PageCurlGeometry.fromGesture(
      gesture: PageCurlGesture.fromPoints(
        pageSize: const Size(320, 480),
        start: const Offset(310, 40),
        current: const Offset(180, 120),
      ),
      quality: PageCurlQuality.low,
      imageSize: const Size(320, 480),
    );

    expect(
      _distanceToLine(
        geometry.foldCurveControl,
        geometry.foldLineStart,
        geometry.foldLineEnd,
      ),
      greaterThan(1),
    );
  });

  test('low quality policy is retained for fallback decisions', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 480),
      start: const Offset(310, 240),
      current: const Offset(120, 240),
    );

    final low = PageCurlGeometry.fromGesture(
      gesture: gesture,
      quality: PageCurlQuality.low,
      imageSize: const Size(320, 480),
    );
    final normal = PageCurlGeometry.fromGesture(
      gesture: gesture,
      quality: PageCurlQuality.normal,
      imageSize: const Size(320, 480),
    );

    expect(low.qualityStripCount, PageCurlQuality.low.stripCount);
    expect(normal.qualityStripCount, PageCurlQuality.normal.stripCount);
    expect(low.qualityStripCount, lessThan(normal.qualityStripCount));
  });
}

double _distanceToLine(Offset point, Offset start, Offset end) {
  final line = end - start;
  final length = line.distance;
  if (length == 0) return 0;
  final relative = point - start;
  return (relative.dx * line.dy - relative.dy * line.dx).abs() / length;
}
