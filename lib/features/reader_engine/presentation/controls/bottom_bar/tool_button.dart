part of '../../reader_controls.dart';

class _ToolButton extends StatelessWidget {
  const _ToolButton(
      {required this.metrics,
      required this.icon,
      required this.label,
      required this.palette,
      required this.onPressed,
      this.active = false});

  final _ReaderOverlayMetrics metrics;
  final IconData icon;
  final String label;
  final ReaderPalette palette;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final foreground = active
        ? context.readerControls.action.accent
        : context.readerControls.text.secondary;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(metrics.s(16)),
      child: Container(
        height: metrics.s(52),
        decoration: BoxDecoration(
          color: active
              ? context.readerControls.action.accentSoft
              : context.readerControls.overlay.transparent,
          borderRadius: BorderRadius.circular(metrics.s(16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: metrics.s(17)),
            SizedBox(height: metrics.s(3)),
            Text(label,
                style: DudoTextStyles.sans(
                    color: foreground,
                    fontSize: metrics.s(9),
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _SmallPillButton extends StatelessWidget {
  const _SmallPillButton(
      {required this.label,
      required this.icon,
      required this.palette,
      required this.onTap,
      this.reversed = false});

  final String label;
  final IconData icon;
  final ReaderPalette palette;
  final VoidCallback onTap;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final foreground = reversed
        ? context.readerControls.surface.panel
        : context.readerControls.text.secondary;
    final background = reversed
        ? context.readerControls.text.primary
        : context.readerControls.surface.panelLow;
    final children = [
      Icon(icon, size: 16, color: foreground),
      const SizedBox(width: 6),
      Text(label,
          style: DudoTextStyles.sans(
              color: foreground,
              fontSize: 13,
              fontWeight: reversed ? FontWeight.w600 : FontWeight.normal)),
    ];
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.full,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration:
            BoxDecoration(color: background, borderRadius: AppRadius.full),
        child: Row(children: reversed ? children.reversed.toList() : children),
      ),
    );
  }
}
