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

  testWidgets('dominant colour follows the hue that carries the jacket',
      (tester) async {
    final color = await tester.runAsync(() async {
      final image = await _paintCover((canvas) {
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 120, 180),
          Paint()..color = const Color(0xFFF3EEE2),
        );
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 72, 180),
          Paint()..color = const Color(0xFF2E6FB2),
        );
      });
      final color = await dominantColorOfImage(image);
      image.dispose();
      return color;
    });

    expect(color!.b, greaterThan(color.r));
    expect(color.b, greaterThan(color.g));
  });

  testWidgets('neutral jackets fall back to a readable palette tone',
      (tester) async {
    final color = await tester.runAsync(() async {
      final image = await _paintCover((canvas) {
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 120, 180),
          Paint()..color = const Color(0xFFFDFBF7),
        );
      });
      final color = await dominantColorOfImage(image);
      image.dispose();
      return color;
    });

    // Pure paper white would erase the spine, so the sampler pulls it down
    // towards the palette instead of returning the average verbatim.
    expect(color!.computeLuminance(), lessThan(0.6));
  });
}

Future<ui.Image> _paintCover(void Function(Canvas canvas) paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paint(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(120, 180);
  picture.dispose();
  return image;
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
