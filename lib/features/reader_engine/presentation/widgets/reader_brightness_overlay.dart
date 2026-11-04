import 'package:flutter/material.dart';

import '../../../../shared/theme/app_tokens.dart';

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
          duration: AppMotion.fast,
          color: Colors.black.withValues(alpha: alpha),
        ),
      ),
    );
  }
}
