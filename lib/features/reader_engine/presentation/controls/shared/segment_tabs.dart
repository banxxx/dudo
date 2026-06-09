part of '../../reader_controls.dart';

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs(
      {required this.metrics,
      required this.labels,
      required this.selected,
      required this.palette});

  final _ReaderOverlayMetrics metrics;
  final List<String> labels;
  final int selected;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.s(42),
      padding: EdgeInsets.all(metrics.s(4)),
      decoration: BoxDecoration(
          color: context.readerControls.surface.panelLow,
          borderRadius: AppRadius.full),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == selected
                      ? context.readerControls.surface.panelHigh
                      : context.readerControls.overlay.transparent,
                  borderRadius: AppRadius.full,
                ),
                child: Text(labels[i],
                    style: DudoTextStyles.sans(
                        color: i == selected
                            ? palette.foreground
                            : context.readerControls.text.secondary,
                        fontSize: metrics.s(13),
                        fontWeight:
                            i == selected ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }
}
