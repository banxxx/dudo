part of '../../reader_controls.dart';

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.child,
    required this.borderRadius,
    required this.fill,
    this.shadowColor = const Color(0x3325251F),
    this.shadowOffset = const Offset(0, 12),
    this.shadowBlur = 34,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color fill;
  final Color shadowColor;
  final Offset shadowOffset;
  final double shadowBlur;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: shadowBlur,
            offset: shadowOffset,
          ),
          const BoxShadow(
            color: Color(0x12FFFFFF),
            blurRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: borderRadius,
            border: Border.all(color: const Color(0xFFE7DCC8)),
          ),
          child: child,
        ),
      ),
    );
  }
}
