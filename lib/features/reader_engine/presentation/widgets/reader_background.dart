import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/reader_background.dart';
import '../../domain/reader_theme.dart';
import '../layout/reader_chrome_layout.dart';

class ReaderPaperBackground extends StatelessWidget {
  const ReaderPaperBackground({
    super.key,
    required this.palette,
    this.background,
  });

  final ReaderPalette palette;
  final ReaderBackgroundPreference? background;

  @override
  Widget build(BuildContext context) {
    return ReaderBackgroundLayer(
      palette: palette,
      background: background ?? ReaderBackgroundPreference.defaults(),
    );
  }
}

class ReaderBackgroundLayer extends StatelessWidget {
  const ReaderBackgroundLayer({
    super.key,
    required this.palette,
    required this.background,
  });

  final ReaderPalette palette;
  final ReaderBackgroundPreference background;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.background,
                  palette.backgroundEnd ?? palette.background
                ],
              ),
            ),
          ),
          if (_isParchment) const _ParchmentPaperLayer(),
          if (background.hasImage)
            _ReaderBackgroundImage(
              palette: palette,
              background: background,
            ),
          if (background.hasImage)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.background.withValues(alpha: _veilOpacity * 0.4),
                    palette.background.withValues(alpha: _veilOpacity),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double get _veilOpacity {
    return palette.background.computeLuminance() < 0.2 ? 0.14 : 0.08;
  }

  bool get _isParchment {
    return background.id == ReaderBackgroundPreference.parchmentId;
  }
}

class _ParchmentPaperLayer extends StatelessWidget {
  const _ParchmentPaperLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParchmentPaperPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ParchmentPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF7E7BE),
          Color(0xFFE8C98C),
          Color(0xFFF1DBA8),
          Color(0xFFD9B678),
        ],
        stops: [0, 0.42, 0.72, 1],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    final vignettePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.center,
        radius: 0.92,
        colors: [
          Color(0x00FFFFFF),
          Color(0x339B6B2D),
          Color(0x4D6F461B),
        ],
        stops: [0.48, 0.82, 1],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);

    final fiberPaint = Paint()
      ..color = const Color(0x2C8E6534)
      ..strokeWidth = 1;
    final lightFiberPaint = Paint()
      ..color = const Color(0x36FFF6DA)
      ..strokeWidth = 1;

    final stepY = (size.height / 22).clamp(8.0, 22.0).toDouble();
    for (var y = -stepY; y < size.height + stepY; y += stepY) {
      final wobble = ((y / stepY).round().isEven ? 0.018 : -0.014) * size.width;
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * 0.28,
          y + stepY * 0.36,
          size.width * 0.58,
          y - stepY * 0.42,
          size.width,
          y + wobble,
        );
      canvas.drawPath(path, fiberPaint);
    }

    final stepX = (size.width / 14).clamp(8.0, 20.0).toDouble();
    for (var x = -stepX; x < size.width + stepX; x += stepX) {
      final path = Path()
        ..moveTo(x, 0)
        ..cubicTo(
          x + stepX * 0.34,
          size.height * 0.3,
          x - stepX * 0.28,
          size.height * 0.68,
          x + stepX * 0.18,
          size.height,
        );
      canvas.drawPath(path, lightFiberPaint);
    }

    final speckPaint = Paint()..color = const Color(0x34805C2E);
    final speckCount = (size.shortestSide / 2.4).round().clamp(32, 96);
    for (var i = 0; i < speckCount; i++) {
      final x = ((i * 37) % 101) / 101 * size.width;
      final y = ((i * 53) % 97) / 97 * size.height;
      final radius = 0.45 + ((i * 11) % 7) * 0.08;
      canvas.drawCircle(Offset(x, y), radius, speckPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParchmentPaperPainter oldDelegate) => false;
}

class _ReaderBackgroundImage extends StatelessWidget {
  const _ReaderBackgroundImage({
    required this.palette,
    required this.background,
  });

  final ReaderPalette palette;
  final ReaderBackgroundPreference background;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final provider = _imageProvider(constraints);
        if (provider == null) return const SizedBox.shrink();

        Widget image = Image(
          image: provider,
          fit: _imageFit,
          alignment: background.alignment,
          repeat: _imageRepeat,
          color: background.tintEnabled ? _tintColor : null,
          colorBlendMode: background.tintEnabled ? BlendMode.modulate : null,
          filterQuality: FilterQuality.medium,
        );
        if (background.grayscaleEnabled) {
          image = ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: image,
          );
        }
        if (background.blurRadius > 0) {
          image = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: background.blurRadius,
              sigmaY: background.blurRadius,
            ),
            child: image,
          );
        }

        return Align(
          alignment: background.alignment,
          child: FractionallySizedBox(
            widthFactor: _widthFactor,
            heightFactor: _heightFactor,
            alignment: background.alignment,
            child: Opacity(
              opacity: _resolvedOpacity,
              child: image,
            ),
          ),
        );
      },
    );
  }

  ImageProvider? _imageProvider(BoxConstraints constraints) {
    final provider = _baseImageProvider;
    if (provider == null) return null;
    if (background.fit != BoxFit.none) return provider;
    return ResizeImage.resizeIfNeeded(
      _tileCacheWidth(constraints),
      null,
      provider,
    );
  }

  ImageProvider? get _baseImageProvider {
    final assetPath = background.assetPath;
    if (assetPath != null && assetPath.isNotEmpty) {
      return AssetImage(assetPath);
    }
    final filePath = background.filePath;
    if (filePath != null && filePath.isNotEmpty) {
      return FileImage(File(filePath));
    }
    return null;
  }

  int _tileCacheWidth(BoxConstraints constraints) {
    final shortestSide = constraints.biggest.shortestSide;
    if (!shortestSide.isFinite || shortestSide <= 0) {
      return 144;
    }
    return (shortestSide * 0.36).clamp(96.0, 180.0).round();
  }

  Color get _tintColor {
    final accent = palette.accent ?? palette.foreground;
    if (palette.background.computeLuminance() < 0.2) {
      return Color.lerp(accent, Colors.white, 0.36) ?? accent;
    }
    return Color.lerp(accent, palette.foreground, 0.28) ?? accent;
  }

  double get _resolvedOpacity {
    if (background.type == ReaderBackgroundType.customImage) {
      return background.opacity.clamp(0.0, 1.0).toDouble();
    }
    final base = background.opacity.clamp(0.0, 0.32).toDouble();
    if (palette.background.computeLuminance() < 0.2) {
      return (base * 0.58).clamp(0.0, 0.16).toDouble();
    }
    return base;
  }

  BoxFit get _imageFit {
    if (background.id == ReaderBackgroundPreference.bambooId) {
      return BoxFit.contain;
    }
    return background.fit;
  }

  ImageRepeat get _imageRepeat {
    if (background.fit != BoxFit.none) return ImageRepeat.noRepeat;
    return ImageRepeat.repeat;
  }

  double get _widthFactor {
    if (background.id == ReaderBackgroundPreference.bambooId) {
      return 0.56;
    }
    return 1;
  }

  double get _heightFactor {
    if (background.id == ReaderBackgroundPreference.bambooId) {
      return 0.46;
    }
    return 1;
  }
}

class ReaderSoftPageEdge extends StatelessWidget {
  const ReaderSoftPageEdge({super.key, required this.layout});

  final ReaderChromeLayout layout;

  @override
  Widget build(BuildContext context) {
    final metrics = layout.metrics;
    final contentInsets = layout.contentInsets;
    final top = contentInsets.top + metrics.s(82);
    final bottom = contentInsets.bottom + metrics.s(74);
    final height =
        (layout.size.height - top - bottom).clamp(0.0, double.infinity);

    return Positioned(
      left: metrics.x(18),
      top: top,
      width: metrics.s(1),
      height: height,
      child: const ColoredBox(color: Color(0x66D8CDBB)),
    );
  }
}
