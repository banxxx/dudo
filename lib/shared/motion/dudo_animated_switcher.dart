import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// An [AnimatedSwitcher] with the house timing.
///
/// Inline swaps (icons, labels, loading markers) all fade with the same
/// enter/exit curves so a page never mixes two different swap rhythms.
class DudoAnimatedSwitcher extends StatelessWidget {
  const DudoAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = AppMotion.base,
    this.reverseDuration,
    this.switchInCurve = AppMotion.enter,
    this.switchOutCurve = AppMotion.exit,
  });

  final Widget child;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve switchInCurve;
  final Curve switchOutCurve;

  @override
  Widget build(BuildContext context) {
    final reverse = reverseDuration;
    return AnimatedSwitcher(
      duration: AppMotion.effective(context, duration),
      reverseDuration:
          reverse == null ? null : AppMotion.effective(context, reverse),
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      child: child,
    );
  }
}
