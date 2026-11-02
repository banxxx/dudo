import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dudo/features/bookshelf/data/cover_image_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('crops a normalized region to PNG bytes', (tester) async {
    await tester.runAsync(() async {
      final bytes = await _twoToneImage();

      final cropped = await cropCoverImage(
        bytes,
        const Rect.fromLTWH(0.5, 0, 0.5, 1),
      );
      final image = await decodeCoverImage(cropped);

      expect(image.width, 50);
      expect(image.height, 100);
      final color = await averageCoverColor(cropped);
      expect(color.b, greaterThan(color.r));
      image.dispose();
    });
  });

  testWidgets('samples the requested region for the spine colour',
      (tester) async {
    await tester.runAsync(() async {
      final bytes = await _twoToneImage();

      final left = await averageCoverColor(
        bytes,
        region: const Rect.fromLTWH(0, 0, 0.5, 1),
      );

      expect(left.r, greaterThan(left.b));
    });
  });
}

Future<Uint8List> _twoToneImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 50, 100),
    Paint()..color = const Color(0xFFCC2222),
  );
  canvas.drawRect(
    const Rect.fromLTWH(50, 0, 50, 100),
    Paint()..color = const Color(0xFF2233CC),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(100, 100);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return data!.buffer.asUint8List();
}
