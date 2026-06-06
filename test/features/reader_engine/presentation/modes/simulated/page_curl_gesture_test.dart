import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_gesture.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects next direction from the right side', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 480),
      start: const Offset(300, 420),
      current: const Offset(180, 400),
    );

    expect(gesture.direction, PageCurlDirection.next);
    expect(gesture.anchor, PageCurlAnchor.bottom);
    expect(gesture.progress, closeTo(120 / 320, 0.001));
  });

  test('detects previous direction from the left side', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 480),
      start: const Offset(24, 60),
      current: const Offset(130, 80),
    );

    expect(gesture.direction, PageCurlDirection.previous);
    expect(gesture.anchor, PageCurlAnchor.top);
    expect(gesture.progress, closeTo(106 / 320, 0.001));
  });

  test('detects middle anchor from side gesture', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 480),
      start: const Offset(310, 240),
      current: const Offset(220, 240),
    );

    expect(gesture.anchor, PageCurlAnchor.middle);
  });

  test('keeps locked direction when pointer crosses the drag origin', () {
    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 480),
      start: const Offset(300, 240),
      current: const Offset(318, 240),
      lockedDirection: PageCurlDirection.next,
    );

    expect(gesture.direction, PageCurlDirection.next);
    expect(gesture.progress, 0);
  });
}
