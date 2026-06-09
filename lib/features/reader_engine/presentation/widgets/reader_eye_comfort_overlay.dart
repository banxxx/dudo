import 'package:flutter/material.dart';

import '../../domain/reader_theme.dart';

class ReaderEyeComfortOverlay extends StatelessWidget {
  const ReaderEyeComfortOverlay({
    super.key,
    required this.enabled,
    required this.palette,
  });

  final bool enabled;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    final color = _filterColorForPalette(palette);
    final alpha = enabled ? _filterAlphaForPalette(palette) : 0.0;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedContainer(
          key: const ValueKey('reader-eye-comfort-overlay'),
          duration: const Duration(milliseconds: 140),
          color: color.withValues(alpha: alpha),
        ),
      ),
    );
  }

  Color _filterColorForPalette(ReaderPalette palette) {
    if (palette.name == ReaderTheme.night.name) {
      return const Color(0xFFFFB86A);
    }
    if (palette.name == ReaderTheme.warmBrown.name) {
      return const Color(0xFFFFC47A);
    }
    if (palette.name == ReaderTheme.eyeCare.name) {
      return const Color(0xFFFFD28A);
    }
    return const Color(0xFFFFD08A);
  }

  double _filterAlphaForPalette(ReaderPalette palette) {
    if (palette.name == ReaderTheme.night.name) {
      return 0.04;
    }
    if (palette.name == ReaderTheme.warmBrown.name) {
      return 0.05;
    }
    if (palette.name == ReaderTheme.eyeCare.name) {
      return 0.06;
    }
    return 0.08;
  }
}
