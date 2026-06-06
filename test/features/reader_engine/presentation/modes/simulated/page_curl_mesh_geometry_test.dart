import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_controller.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_gesture.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_mesh_geometry.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_quality.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nextPageOut keeps stable mesh strip count', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(300, 260),
      current: const Offset(180, 260),
    );

    final geometry = PageCurlMeshGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.nextPageOut,
      pageSize: const Size(320, 520),
      imageSize: const Size(480, 780),
      quality: PageCurlQuality.normal,
    );

    expect(geometry.turnType, PageCurlTurnType.nextPageOut);
    expect(geometry.positions,
        hasLength((PageCurlQuality.normal.stripCount + 1) * 9));
    expect(geometry.textureCoordinates, hasLength(geometry.positions.length));
    expect(
        geometry.indices, hasLength(PageCurlQuality.normal.stripCount * 8 * 6));
    expect(geometry.unturnedRect.width, greaterThan(0));
    expect(geometry.unturnedPath.getBounds().width, greaterThan(0));
  });

  test('previousPageIn uses entering page geometry', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(20, 260),
      current: const Offset(140, 260),
    );

    final geometry = PageCurlMeshGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.previousPageIn,
      pageSize: const Size(320, 520),
      imageSize: const Size(480, 780),
      quality: PageCurlQuality.low,
    );

    expect(geometry.turnType, PageCurlTurnType.previousPageIn);
    expect(geometry.positions,
        hasLength((PageCurlQuality.low.stripCount + 1) * 9));
    expect(geometry.indices, hasLength(PageCurlQuality.low.stripCount * 8 * 6));
    expect(geometry.unturnedRect, Rect.zero);
    expect(geometry.positions.first.dx, closeTo(0, 0.001));
  });

  test('page edge is bowed instead of a straight vertical line', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(300, 260),
      current: const Offset(170, 260),
    );

    final geometry = PageCurlMeshGeometry.fromGesture(
      gesture: gesture,
      turnType: PageCurlTurnType.nextPageOut,
      pageSize: const Size(320, 520),
      imageSize: const Size(480, 780),
      quality: PageCurlQuality.low,
    );

    const rowStride = 9;
    final edgeStart = PageCurlQuality.low.stripCount * rowStride;
    final topX = geometry.positions[edgeStart].dx;
    final middleX = geometry.positions[edgeStart + 4].dx;

    expect(middleX, lessThan(topX));
  });
}
