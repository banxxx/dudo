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
  try {
    return await averageColorOfImage(image, region: region);
  } finally {
    image.dispose();
  }
}

/// Picks the colour that visually carries an already decoded cover.
///
/// A plain average of a multicolour jacket turns into grey, so the hue that
/// holds the most saturated weight wins instead; neutral covers (no clear
/// hue) fall back to the average. The result is then pulled towards the app
/// palette when it is too bright or too dark to read spine type on.
Future<Color> dominantColorOfImage(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return _fallbackSpineColor;

  const binCount = 24;
  final binWeights = List<double>.filled(binCount, 0);
  final binRed = List<double>.filled(binCount, 0);
  final binGreen = List<double>.filled(binCount, 0);
  final binBlue = List<double>.filled(binCount, 0);
  var saturatedWeight = 0.0;
  var red = 0.0;
  var green = 0.0;
  var blue = 0.0;
  var samples = 0;

  final step = _sampleStep(image.width * image.height);
  for (var y = 0; y < image.height; y += step) {
    for (var x = 0; x < image.width; x += step) {
      final offset = (y * image.width + x) * 4;
      if (data.getUint8(offset + 3) < 32) continue;
      final r = data.getUint8(offset).toDouble();
      final g = data.getUint8(offset + 1).toDouble();
      final b = data.getUint8(offset + 2).toDouble();
      red += r;
      green += g;
      blue += b;
      samples++;

      final maxChannel = math.max(r, math.max(g, b)) / 255;
      final minChannel = math.min(r, math.min(g, b)) / 255;
      final lightness = (maxChannel + minChannel) / 2;
      final delta = maxChannel - minChannel;
      final saturation = delta == 0
          ? 0.0
          : delta / (1 - (2 * lightness - 1).abs()).clamp(0.0001, 1.0);
      // White paper and black type are present on almost every jacket; giving
      // them a share of the vote would drown the actual artwork colour.
      if (saturation < 0.12 || lightness < 0.08 || lightness > 0.94) continue;

      final hue = _hue(r, g, b);
      final bin = (hue / 360 * binCount).floor().clamp(0, binCount - 1);
      final weight = saturation * saturation + 0.05;
      binWeights[bin] += weight;
      binRed[bin] += r * weight;
      binGreen[bin] += g * weight;
      binBlue[bin] += b * weight;
      saturatedWeight += weight;
    }
  }

  var bestBin = -1;
  var bestWeight = 0.0;
  for (var index = 0; index < binCount; index++) {
    if (binWeights[index] > bestWeight) {
      bestWeight = binWeights[index];
      bestBin = index;
    }
  }

  // A hue has to carry at least a meaningful slice of the jacket; otherwise
  // the cover is effectively neutral and the average is the honest answer.
  if (samples == 0 || bestBin < 0 || bestWeight < saturatedWeight * 0.14) {
    if (samples == 0) return _fallbackSpineColor;
    return _readableSpineTone(
      Color.fromARGB(
        255,
        (red / samples).round(),
        (green / samples).round(),
        (blue / samples).round(),
      ),
    );
  }

  final average = Color.fromARGB(
    255,
    (binRed[bestBin] / bestWeight).round().clamp(0, 255),
    (binGreen[bestBin] / bestWeight).round().clamp(0, 255),
    (binBlue[bestBin] / bestWeight).round().clamp(0, 255),
  );
  return _readableSpineTone(average);
}

/// Averages the pixels inside [region] of an already decoded image.
Future<Color> averageColorOfImage(
  ui.Image image, {
  Rect region = const Rect.fromLTWH(0, 0, 1, 1),
}) async {
  final left = (region.left * image.width).floor().clamp(0, image.width - 1);
  final top = (region.top * image.height).floor().clamp(0, image.height - 1);
  final right =
      (region.right * image.width).ceil().clamp(left + 1, image.width);
  final bottom =
      (region.bottom * image.height).ceil().clamp(top + 1, image.height);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return _fallbackSpineColor;

  final width = right - left;
  final height = bottom - top;
  final step = _sampleStep(width * height);
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
  if (samples == 0) return _fallbackSpineColor;

  return _readableSpineTone(
    Color.fromARGB(
      255,
      (red / samples).round(),
      (green / samples).round(),
      (blue / samples).round(),
    ),
  );
}

/// The spine colour used when there is no artwork to sample from at all.
const Color _fallbackSpineColor = Color(0xFF5E6F5B);

/// Keeps a sampled spine tone legible for the printed spine text.
Color _readableSpineTone(Color color) {
  final luminance = color.computeLuminance();
  if (luminance > 0.72) {
    return Color.lerp(color, const Color(0xFF4B5A45), 0.55)!;
  }
  if (luminance < 0.08) {
    return Color.lerp(color, const Color(0xFF8A735A), 0.4)!;
  }
  return color;
}

int _sampleStep(int pixels) => math.max(1, math.sqrt(pixels / 4096).floor());

double _hue(double red, double green, double blue) {
  final maxValue = math.max(red, math.max(green, blue));
  final minValue = math.min(red, math.min(green, blue));
  final delta = maxValue - minValue;
  if (delta == 0) return 0;
  final hue = maxValue == red
      ? ((green - blue) / delta) % 6
      : maxValue == green
          ? (blue - red) / delta + 2
          : (red - green) / delta + 4;
  return (hue * 60 + 360) % 360;
}
