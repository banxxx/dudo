import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/reader_background.dart';
import '../../domain/reader_theme.dart';

class ReaderBackgroundCanvas {
  const ReaderBackgroundCanvas._();

  static String digest(ReaderBackgroundPreference background) {
    return [
      background.type.name,
      background.id,
      background.assetPath ?? '',
      background.filePath ?? '',
      background.opacity,
      background.alignment.x,
      background.alignment.y,
      background.fit.name,
      background.tintEnabled,
      background.grayscaleEnabled,
      background.blurRadius,
    ].join('|');
  }

  static Future<ui.Image?> resolveImage(
    ReaderBackgroundPreference background,
  ) async {
    if (!background.hasImage) return null;
    Uint8List? bytes;
    final assetPath = background.assetPath;
    if (assetPath != null && assetPath.isNotEmpty) {
      final data = await rootBundle.load(assetPath);
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } else {
      final filePath = background.filePath;
      if (filePath == null || filePath.isEmpty) return null;
      final file = File(filePath);
      if (!await file.exists()) return null;
      bytes = await file.readAsBytes();
    }
    if (bytes.isEmpty) return null;
    return _decodeImage(bytes);
  }

  static void paint({
    required Canvas canvas,
    required Rect rect,
    required ReaderPalette palette,
    required ReaderBackgroundPreference background,
    ui.Image? image,
    double decorationImageScale = 1,
    double imageOpacityMultiplier = 1,
  }) {
    _paintBase(canvas: canvas, rect: rect, palette: palette);
    if (!background.hasImage || image == null) return;

    canvas.save();
    canvas.clipRect(rect);
    _paintImage(
      canvas: canvas,
      rect: rect,
      palette: palette,
      background: background,
      image: image,
      decorationImageScale: decorationImageScale,
      imageOpacityMultiplier: imageOpacityMultiplier,
    );
    _paintVeil(canvas: canvas, rect: rect, palette: palette);
    canvas.restore();
  }

  static Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  static void _paintBase({
    required Canvas canvas,
    required Rect rect,
    required ReaderPalette palette,
  }) {
    final end = palette.backgroundEnd ?? palette.background;
    if (end == palette.background) {
      canvas.drawRect(rect, Paint()..color = palette.background);
      return;
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.background, end],
        ).createShader(rect),
    );
  }

  static void _paintImage({
    required Canvas canvas,
    required Rect rect,
    required ReaderPalette palette,
    required ReaderBackgroundPreference background,
    required ui.Image image,
    required double decorationImageScale,
    required double imageOpacityMultiplier,
  }) {
    final opacity = _resolvedOpacity(
      palette: palette,
      background: background,
      imageOpacityMultiplier: imageOpacityMultiplier,
    );
    if (opacity <= 0) return;

    final paint = _imagePaint(
      palette: palette,
      background: background,
      opacity: opacity,
    )..filterQuality = FilterQuality.medium;
    void draw() {
      if (background.fit == BoxFit.none && !_isBambooDecoration(background)) {
        _drawRepeatedImage(
          canvas: canvas,
          rect: rect,
          image: image,
          paint: paint,
        );
        return;
      }
      _drawFittedImage(
        canvas: canvas,
        rect: rect,
        image: image,
        paint: paint,
        background: background,
        decorationImageScale: decorationImageScale,
      );
    }

    if (background.blurRadius > 0) {
      canvas.saveLayer(
        rect.inflate(background.blurRadius * 2),
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: background.blurRadius,
            sigmaY: background.blurRadius,
          ),
      );
      draw();
      canvas.restore();
      return;
    }
    draw();
  }

  static void _drawFittedImage({
    required Canvas canvas,
    required Rect rect,
    required ui.Image image,
    required Paint paint,
    required ReaderBackgroundPreference background,
    required double decorationImageScale,
  }) {
    final targetRect = _imageTargetRect(
      rect: rect,
      background: background,
      decorationImageScale: decorationImageScale,
    );
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final fit =
        _isBambooDecoration(background) ? BoxFit.contain : background.fit;
    final sizes = applyBoxFit(fit, imageSize, targetRect.size);
    final source = background.alignment.inscribe(
      sizes.source,
      Offset.zero & imageSize,
    );
    final destination = background.alignment.inscribe(
      sizes.destination,
      targetRect,
    );
    canvas.drawImageRect(image, source, destination, paint);
  }

  static void _drawRepeatedImage({
    required Canvas canvas,
    required Rect rect,
    required ui.Image image,
    required Paint paint,
  }) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    if (imageWidth <= 0 || imageHeight <= 0) return;
    final tileWidth = _tileCacheWidth(rect).toDouble();
    final tileHeight = math.max(1.0, tileWidth * imageHeight / imageWidth);
    final source = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
    for (var y = rect.top; y < rect.bottom; y += tileHeight) {
      for (var x = rect.left; x < rect.right; x += tileWidth) {
        canvas.drawImageRect(
          image,
          source,
          Rect.fromLTWH(x, y, tileWidth, tileHeight),
          paint,
        );
      }
    }
  }

  static Rect _imageTargetRect({
    required Rect rect,
    required ReaderBackgroundPreference background,
    required double decorationImageScale,
  }) {
    if (!_isBambooDecoration(background)) return rect;
    final widthFactor = (0.56 * decorationImageScale).clamp(0.0, 1.0);
    final heightFactor = (0.46 * decorationImageScale).clamp(0.0, 1.0);
    return background.alignment.inscribe(
      Size(rect.width * widthFactor, rect.height * heightFactor),
      rect,
    );
  }

  static Paint _imagePaint({
    required ReaderPalette palette,
    required ReaderBackgroundPreference background,
    required double opacity,
  }) {
    final paint = Paint();
    if (background.grayscaleEnabled) {
      final tint = background.tintEnabled
          ? _tintColor(palette)
          : const Color(0xFFFFFFFF);
      final red = _redUnit(tint);
      final green = _greenUnit(tint);
      final blue = _blueUnit(tint);
      paint.colorFilter = ColorFilter.matrix(<double>[
        0.2126 * red,
        0.7152 * red,
        0.0722 * red,
        0,
        0,
        0.2126 * green,
        0.7152 * green,
        0.0722 * green,
        0,
        0,
        0.2126 * blue,
        0.7152 * blue,
        0.0722 * blue,
        0,
        0,
        0,
        0,
        0,
        opacity,
        0,
      ]);
      return paint;
    }

    final color = background.tintEnabled
        ? _tintColor(palette).withValues(alpha: opacity)
        : Colors.white.withValues(alpha: opacity);
    paint.colorFilter = ColorFilter.mode(color, BlendMode.modulate);
    return paint;
  }

  static void _paintVeil({
    required Canvas canvas,
    required Rect rect,
    required ReaderPalette palette,
  }) {
    final opacity = palette.background.computeLuminance() < 0.2 ? 0.14 : 0.08;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.background.withValues(alpha: opacity * 0.4),
            palette.background.withValues(alpha: opacity),
          ],
        ).createShader(rect),
    );
  }

  static double _resolvedOpacity({
    required ReaderPalette palette,
    required ReaderBackgroundPreference background,
    required double imageOpacityMultiplier,
  }) {
    final multiplier = imageOpacityMultiplier.clamp(0.0, 4.0).toDouble();
    if (background.type == ReaderBackgroundType.customImage) {
      return (background.opacity * multiplier).clamp(0.0, 1.0).toDouble();
    }
    final base = background.opacity.clamp(0.0, 0.32).toDouble();
    if (palette.background.computeLuminance() < 0.2) {
      return (base * 0.58 * multiplier).clamp(0.0, 0.32).toDouble();
    }
    return (base * multiplier).clamp(0.0, 0.32).toDouble();
  }

  static int _tileCacheWidth(Rect rect) {
    final shortestSide = math.min(rect.width, rect.height);
    if (!shortestSide.isFinite || shortestSide <= 0) return 144;
    return (shortestSide * 0.36).clamp(96.0, 180.0).round();
  }

  static Color _tintColor(ReaderPalette palette) {
    final accent = palette.accent ?? palette.foreground;
    if (palette.background.computeLuminance() < 0.2) {
      return Color.lerp(accent, Colors.white, 0.36) ?? accent;
    }
    return Color.lerp(accent, palette.foreground, 0.28) ?? accent;
  }

  static bool _isBambooDecoration(ReaderBackgroundPreference background) {
    return background.id == ReaderBackgroundPreference.bambooId ||
        background.id == ReaderBackgroundPreference.bambooCornerId;
  }

  static double _redUnit(Color color) {
    return ((color.toARGB32() >> 16) & 0xFF) / 255.0;
  }

  static double _greenUnit(Color color) {
    return ((color.toARGB32() >> 8) & 0xFF) / 255.0;
  }

  static double _blueUnit(Color color) {
    return (color.toARGB32() & 0xFF) / 255.0;
  }
}
