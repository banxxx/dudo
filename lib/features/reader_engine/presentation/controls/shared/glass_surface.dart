part of '../../reader_controls.dart';

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.child,
    required this.borderRadius,
    required this.fill,
    this.shadowColor,
    this.shadowOffset = const Offset(0, 12),
    this.shadowBlur = 34,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color fill;
  final Color? shadowColor;
  final Offset shadowOffset;
  final double shadowBlur;

  @override
  Widget build(BuildContext context) {
    final controlTheme = context.readerControls;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? controlTheme.surface.shadow,
            blurRadius: shadowBlur,
            offset: shadowOffset,
          ),
          BoxShadow(
            color: controlTheme.overlay.glassHighlight,
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: borderRadius,
            border: Border.all(
              color: controlTheme.surface.outline,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
