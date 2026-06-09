part of '../../../reader_controls.dart';

// 阅读背景入口：保留当前静态展示，为后续背景替换逻辑预留清晰边界。

class _ReadingBackgroundPill extends StatelessWidget {
  const _ReadingBackgroundPill({
    required this.metrics,
    required this.label,
    required this.fillColor,
    this.selected = false,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final Color fillColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.s(36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? context.readerControls.themePicker.ink : fillColor,
        borderRadius: BorderRadius.circular(metrics.s(16)),
        border: Border.all(
          color: selected
              ? context.readerControls.themePicker.ink
              : context.readerControls.themePicker.surfaceLine,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DudoTextStyles.sans(
          color: selected
              ? context.readerControls.themePicker.panel
              : context.readerControls.themePicker.secondaryText,
          fontSize: metrics.s(12),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
