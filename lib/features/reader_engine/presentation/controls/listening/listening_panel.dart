part of '../../reader_controls.dart';

class _ListeningPanel extends StatelessWidget {
  const _ListeningPanel({
    required this.metrics,
    required this.palette,
    required this.chapterTitle,
    required this.remainingText,
    required this.isListening,
    required this.onListeningChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final String chapterTitle;
  final String remainingText;
  final bool isListening;
  final ValueChanged<bool> onListeningChanged;

  @override
  Widget build(BuildContext context) {
    final bars = <double>[18, 34, 26, 44, 22, 38, 28, 16, 30];
    final subtitle =
        remainingText.isEmpty ? chapterTitle : '$chapterTitle · $remainingText';
    return _FloatingPanel(
      key: const ValueKey('reader-listening-panel'),
      metrics: metrics,
      top: 468,
      height: 212,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isListening ? '朗读中' : '朗读',
                      style: DudoTextStyles.serif(
                          color: context.readerControls.text.primary,
                          fontSize: metrics.s(22),
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: metrics.s(4)),
                  Text(subtitle,
                      style: DudoTextStyles.sans(
                          color: context.readerControls.text.secondary,
                          fontSize: metrics.s(12))),
                ],
              ),
              GestureDetector(
                onTap: () => onListeningChanged(!isListening),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: metrics.s(48),
                  height: metrics.s(48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.readerControls.text.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isListening ? LucideIcons.pause : LucideIcons.play,
                    size: metrics.s(20),
                    color: context.readerControls.surface.panel,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.s(14)),
          SizedBox(
            height: metrics.s(54),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  if (i > 0) SizedBox(width: metrics.s(6)),
                  AnimatedContainer(
                    duration: AppMotion.medium,
                    width: metrics.s(8),
                    height: metrics.s(
                      isListening ? bars[i] : (16 + i % 3 * 6).toDouble(),
                    ),
                    decoration: BoxDecoration(
                      color: i == 3
                          ? context.readerControls.action.accent
                          : context.readerControls.surface.outlineStrong,
                      borderRadius: AppRadius.full,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: metrics.s(14)),
          SizedBox(
            height: metrics.s(38),
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) SizedBox(width: metrics.s(10)),
                  Expanded(
                    child: _ListeningPill(
                      metrics: metrics,
                      label: const ['0.8x', '1.0x', '1.2x', '定时'][i],
                      selected: i == 1,
                      onTap: () {},
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningPill extends StatelessWidget {
  const _ListeningPill({
    required this.metrics,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? context.readerControls.action.accentSoft
              : context.readerControls.surface.panelLow,
          borderRadius: BorderRadius.circular(metrics.s(19)),
        ),
        child: Text(label,
            style: DudoTextStyles.sans(
                color: selected
                    ? context.readerControls.action.accent
                    : context.readerControls.text.secondary,
                fontSize: metrics.s(13),
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
