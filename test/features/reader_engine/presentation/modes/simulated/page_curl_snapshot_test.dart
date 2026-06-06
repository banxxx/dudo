import 'dart:ui' as ui;

import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PageCurlSnapshotPair disposes images once', () async {
    final current = await _testImage();
    final target = await _testImage();
    final pair = PageCurlSnapshotPair(current: current, target: target);

    expect(pair.isDisposed, isFalse);

    pair.dispose();
    pair.dispose();

    expect(pair.isDisposed, isTrue);
  });
}

Future<ui.Image> _testImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 8, 8),
    Paint()..color = Colors.white,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(8, 8);
  picture.dispose();
  return image;
}
