import 'package:flutter/material.dart';

import '../../domain/reader_theme.dart';
import '../layout/reader_chrome_layout.dart';

class ReaderPaperBackground extends StatelessWidget {
  const ReaderPaperBackground({super.key, required this.palette});

  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
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
    );
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
