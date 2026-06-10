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
    final provider = _imageProvider;
    if (provider == null) return const SizedBox.shrink();

    Widget image = Image(
      image: provider,
      fit: _imageFit,
      alignment: background.alignment,
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
  }

  ImageProvider? get _imageProvider {
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

  Color get _tintColor {
    final accent = palette.accent ?? palette.foreground;
    if (palette.background.computeLuminance() < 0.2) {
      return Color.lerp(accent, Colors.white, 0.36) ?? accent;
    }
    return Color.lerp(accent, palette.foreground, 0.28) ?? accent;
  }

  double get _resolvedOpacity {
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
