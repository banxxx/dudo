import 'package:flutter/material.dart';

import '../../domain/reader_theme.dart';
import '../layout/reader_page_metrics.dart';

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
  const ReaderSoftPageEdge({super.key, required this.metrics});

  final ReaderPageMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: metrics.x(18),
      top: metrics.y(100),
      width: metrics.s(1),
      height: metrics.s(610),
      child: const ColoredBox(color: Color(0x66D8CDBB)),
    );
  }
}
