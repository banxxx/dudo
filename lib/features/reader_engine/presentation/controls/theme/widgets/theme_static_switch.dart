part of '../../../reader_controls.dart';

// 静态开关：当前用于 UI 占位，不在这里处理点击后的状态变更。

class _ThemeStaticSwitch extends StatelessWidget {
  const _ThemeStaticSwitch({
    required this.metrics,
    required this.enabled,
  });

  final _ReaderOverlayMetrics metrics;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: metrics.s(44),
      height: metrics.s(26),
      padding: EdgeInsets.all(metrics.s(3)),
      decoration: BoxDecoration(
        color: enabled
            ? context.readerControls.themePicker.green
            : context.readerControls.themePicker.surfaceLine,
        borderRadius: BorderRadius.circular(metrics.s(13)),
      ),
      child: Align(
        alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: metrics.s(20),
          height: metrics.s(20),
          decoration: BoxDecoration(
            color: context.readerControls.themePicker.panel,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.readerControls.themePicker.ink
                    .withValues(alpha: 0.14),
                blurRadius: metrics.s(4),
                offset: Offset(0, metrics.s(1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
