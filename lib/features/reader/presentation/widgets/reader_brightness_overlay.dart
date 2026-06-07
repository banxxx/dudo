import 'package:flutter/material.dart';

class ReaderBrightnessOverlay extends StatelessWidget {
  const ReaderBrightnessOverlay({
    super.key,
    required this.brightness,
  });

  final double brightness;

  @override
  Widget build(BuildContext context) {
    final alpha = (1 - brightness).clamp(0.0, 0.65).toDouble();
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedContainer(
          key: const ValueKey('reader-brightness-overlay'),
          duration: const Duration(milliseconds: 120),
          color: Colors.black.withValues(alpha: alpha),
        ),
      ),
    );
  }
}
