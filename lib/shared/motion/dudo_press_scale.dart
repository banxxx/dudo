import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A quiet press acknowledgement for tappable surfaces.
///
/// This only watches the pointer with a [Listener]; taps, long presses and
/// ink ripples stay with the child. The surface eases in a fraction and back
/// out, which gives the paper a little give without moving the layout.
class DudoPressScale extends StatefulWidget {
  const DudoPressScale({
    super.key,
    required this.child,
    this.pressedScale = 0.985,
  });

  final Widget child;
  final double pressedScale;

  @override
  State<DudoPressScale> createState() => _DudoPressScaleState();
}

class _DudoPressScaleState extends State<DudoPressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: reduced ? null : (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: AppMotion.effective(context, AppMotion.instant),
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}
