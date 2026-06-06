import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_controller.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_gesture.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PageCurlController stores active turn type and clears to idle', () {
    final controller = PageCurlController();
    addTearDown(controller.dispose);

    final gesture = PageCurlGesture.fromPoints(
      pageSize: const Size(320, 520),
      start: const Offset(300, 260),
      current: const Offset(220, 260),
    );

    controller.update(
      gesture: gesture,
      turnType: PageCurlTurnType.nextPageOut,
    );

    expect(controller.isActive, isTrue);
    expect(controller.gesture, gesture);
    expect(controller.turnType, PageCurlTurnType.nextPageOut);

    controller.clear();

    expect(controller.isActive, isFalse);
    expect(controller.gesture, isNull);
    expect(controller.turnType, isNull);
  });
}
