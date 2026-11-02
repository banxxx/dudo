import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

Future<ui.Image> decodeCoverImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

/// Crops [bytes] to [normalizedRect] (0–1 coordinates) and returns PNG bytes.
Future<Uint8List> cropCoverImage(
  Uint8List bytes,
  Rect normalizedRect,
) async {
  final image = await decodeCoverImage(bytes);
  final source = Rect.fromLTWH(
    normalizedRect.left * image.width,
    normalizedRect.top * image.height,
    normalizedRect.width * image.width,
    normalizedRect.height * image.height,
  );
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final destination = Rect.fromLTWH(0, 0, source.width, source.height);
  canvas.drawImageRect(
    image,
    source,
    destination,
    Paint()..filterQuality = FilterQuality.high,
  );
  final picture = recorder.endRecording();
  final cropped = await picture.toImage(
    math.max(1, source.width.round()),
    math.max(1, source.height.round()),
  );
  final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  cropped.dispose();
  image.dispose();
  if (data == null) {
    throw StateError('Could not encode the cropped cover.');
  }
  return data.buffer.asUint8List();
}

/// Averages the pixels inside [region] (0–1 coordinates) so the spine can pick
/// up the colour of the user's artwork. Very light or very dark results are
/// nudged towards the app palette so the spine stays readable.
Future<Color> averageCoverColor(
  Uint8List bytes, {
  Rect region = const Rect.fromLTWH(0, 0, 1, 1),
}) async {
  final image = await decodeCoverImage(bytes);
  final left = (region.left * image.width).floor().clamp(0, image.width - 1);
  final top = (region.top * image.height).floor().clamp(0, image.height - 1);
  final right =
      (region.right * image.width).ceil().clamp(left + 1, image.width);
  final bottom =
      (region.bottom * image.height).ceil().clamp(top + 1, image.height);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) {
    image.dispose();
    return const Color(0xFF5E6F5B);
  }

  final width = right - left;
  final height = bottom - top;
  final pixels = width * height;
  final step = math.max(1, math.sqrt(pixels / 4096).floor());
  var red = 0;
  var green = 0;
  var blue = 0;
  var samples = 0;

  for (var y = top; y < bottom; y += step) {
    for (var x = left; x < right; x += step) {
      final offset = (y * image.width + x) * 4;
      final alpha = data.getUint8(offset + 3);
      if (alpha < 32) continue;
      red += data.getUint8(offset);
      green += data.getUint8(offset + 1);
      blue += data.getUint8(offset + 2);
      samples++;
    }
  }
  image.dispose();
  if (samples == 0) return const Color(0xFF5E6F5B);

  final average = Color.fromARGB(
    255,
    (red / samples).round(),
    (green / samples).round(),
    (blue / samples).round(),
  );
  final luminance = average.computeLuminance();
  if (luminance > 0.72) {
    return Color.lerp(average, const Color(0xFF4B5A45), 0.55)!;
  }
  if (luminance < 0.08) {
    return Color.lerp(average, const Color(0xFF8A735A), 0.4)!;
  }
  return average;
}
