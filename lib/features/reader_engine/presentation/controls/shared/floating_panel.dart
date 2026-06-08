part of '../../reader_controls.dart';

class _FloatingPanel extends StatelessWidget {
  const _FloatingPanel({
    super.key,
    required this.metrics,
    required this.top,
    required this.height,
    required this.palette,
    required this.child,
    this.padding,
  });

  final _ReaderOverlayMetrics metrics;
  final double top;
  final double height;
  final ReaderPalette palette;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: metrics.x(16),
      top: metrics.floatingPanelTop(preferredTop: top, height: height),
      width: metrics.s(358),
      height: metrics.s(height),
      child: _GlassSurface(
        fill: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(metrics.s(26)),
        shadowColor: Colors.transparent,
        shadowOffset: Offset.zero,
        shadowBlur: 0,
        child: Padding(
          padding: padding ?? EdgeInsets.all(metrics.s(16)),
          child: child,
        ),
      ),
    );
  }
}
