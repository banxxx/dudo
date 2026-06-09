part of '../../reader_controls.dart';

class _MenuItem extends StatelessWidget {
  const _MenuItem(
      {required this.metrics,
      required this.palette,
      required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(metrics.s(16)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: metrics.s(10)),
        decoration: BoxDecoration(
          color: active
              ? context.readerControls.action.accentSoft
              : context.readerControls.overlay.transparent,
          borderRadius: BorderRadius.circular(metrics.s(16)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: metrics.s(17),
                color: active
                    ? context.readerControls.action.accent
                    : palette.mutedForeground ??
                        context.readerControls.text.secondary),
            SizedBox(width: metrics.s(10)),
            Text(label,
                style: DudoTextStyles.sans(
                    color: palette.foreground,
                    fontSize: metrics.s(13),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
