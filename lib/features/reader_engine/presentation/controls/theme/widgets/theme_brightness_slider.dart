part of '../../../reader_controls.dart';

// 亮度滑块：只负责拖拽展示与禁用态，具体亮度来源由阅读页状态管理。

class _ThemeBrightnessSlider extends StatelessWidget {
  const _ThemeBrightnessSlider({
    required this.metrics,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        void updateFromOffset(double dx) {
          if (!enabled) return;
          onChanged((dx / constraints.maxWidth).clamp(0.0, 1.0).toDouble());
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled
              ? (details) => updateFromOffset(details.localPosition.dx)
              : null,
          onHorizontalDragUpdate: enabled
              ? (details) => updateFromOffset(details.localPosition.dx)
              : null,
          child: SizedBox(
            key: const ValueKey('reader-theme-brightness-slider'),
            height: metrics.s(24),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: metrics.s(8),
                  decoration: BoxDecoration(
                    color: context.readerControls.themePicker.surfaceLine
                        .withValues(alpha: enabled ? 1 : 0.42),
                    borderRadius: AppRadius.full,
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: clamped == 0 ? 0.0001 : clamped,
                  child: Container(
                    height: metrics.s(8),
                    decoration: BoxDecoration(
                      color: context.readerControls.themePicker.green
                          .withValues(alpha: enabled ? 1 : 0.46),
                      borderRadius: AppRadius.full,
                    ),
                  ),
                ),
                Positioned(
                  left: ((constraints.maxWidth - metrics.s(20)) * clamped)
                      .toDouble(),
                  child: Container(
                    width: metrics.s(20),
                    height: metrics.s(20),
                    decoration: BoxDecoration(
                      color: context.readerControls.themePicker.panel,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.readerControls.themePicker.green
                            .withValues(alpha: enabled ? 1 : 0.48),
                        width: metrics.s(2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.readerControls.themePicker.ink
                              .withValues(alpha: 0.14),
                          blurRadius: metrics.s(6),
                          offset: Offset(0, metrics.s(2)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
