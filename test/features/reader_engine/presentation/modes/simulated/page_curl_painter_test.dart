import 'dart:ui' as ui;

import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_geometry.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_gesture.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_painter.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_quality.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('paints paper behind transparent current page areas', () async {
    const pageSize = Size(320, 480);
    final current = await _imageWithColor(pageSize, Colors.transparent);
    final target = await _imageWithColor(pageSize, Colors.black);
    final pair = PageCurlSnapshotPair(current: current, target: target);
    final geometry = PageCurlGeometry.fromGesture(
      gesture: PageCurlGesture.fromPoints(
        pageSize: pageSize,
        start: const Offset(310, 40),
        current: const Offset(180, 120),
      ),
      quality: PageCurlQuality.low,
      imageSize: pageSize,
    );
    final sample = _findStableUnturnedPoint(geometry, pageSize);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    PageCurlPainter(
      snapshots: pair,
      geometry: geometry,
      pageColor: Colors.white,
    ).paint(canvas, pageSize);
    final image = await recorder.endRecording().toImage(
          pageSize.width.toInt(),
          pageSize.height.toInt(),
        );

    try {
      final pixel = await _pixelAt(image, sample);

      expect(pixel.red, greaterThan(220));
      expect(pixel.green, greaterThan(220));
      expect(pixel.blue, greaterThan(220));
      expect(pixel.alpha, 255);
    } finally {
      image.dispose();
      pair.dispose();
    }
  });
}

Future<ui.Image> _imageWithColor(Size size, Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Offset.zero & size, Paint()..color = color);
  return recorder.endRecording().toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
}

Offset _findStableUnturnedPoint(PageCurlGeometry geometry, Size size) {
  var bestPoint = const Offset(16, 16);
  var bestDistance = -1.0;

  for (var y = 16.0; y < size.height; y += 12) {
    for (var x = 16.0; x < size.width; x += 12) {
      final point = Offset(x, y);
      if (!geometry.unturnedPath.contains(point) ||
          geometry.foldedPath.contains(point)) {
        continue;
      }
      final distance = _distanceToLine(
        point,
        geometry.foldLineStart,
        geometry.foldLineEnd,
      );
      if (distance > bestDistance) {
        bestDistance = distance;
        bestPoint = point;
      }
    }
  }

  expect(bestDistance, greaterThan(0));
  return bestPoint;
}

double _distanceToLine(Offset point, Offset start, Offset end) {
  final line = end - start;
  final length = line.distance;
  if (length == 0) return 0;
  final relative = point - start;
  return (relative.dx * line.dy - relative.dy * line.dx).abs() / length;
}

Future<_Pixel> _pixelAt(ui.Image image, Offset point) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = byteData!.buffer.asUint8List();
  final x = point.dx.round().clamp(0, image.width - 1);
  final y = point.dy.round().clamp(0, image.height - 1);
  final index = (y * image.width + x) * 4;
  return _Pixel(
    red: bytes[index],
    green: bytes[index + 1],
    blue: bytes[index + 2],
    alpha: bytes[index + 3],
  );
}

class _Pixel {
  const _Pixel({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  final int red;
  final int green;
  final int blue;
  final int alpha;
}
