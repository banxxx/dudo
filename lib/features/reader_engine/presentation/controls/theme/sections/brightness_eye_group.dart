part of '../../../reader_controls.dart';

// 护眼与亮度区块：负责组织护眼入口和亮度滑块。

class _BrightnessEyeGroup extends StatelessWidget {
  const _BrightnessEyeGroup({
    required this.metrics,
    required this.brightness,
    required this.onBrightnessChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final double brightness;
  final ValueChanged<double> onBrightnessChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = brightness.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThemeSectionTitle(
          metrics: metrics,
          icon: LucideIcons.sun,
          title: '亮度与护眼',
        ),
        SizedBox(height: metrics.s(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '阅读亮度',
              style: DudoTextStyles.sans(
                color: context.readerControls.themePicker.ink,
                fontSize: metrics.s(13),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${(clamped * 100).round()}%',
              style: DudoTextStyles.sans(
                color: context.readerControls.themePicker.muted,
                fontSize: metrics.s(12),
              ),
            ),
          ],
        ),
        SizedBox(height: metrics.s(8)),
        _ThemeBrightnessSlider(
          metrics: metrics,
          value: clamped,
          onChanged: onBrightnessChanged,
        ),
        SizedBox(height: metrics.s(8)),
        SizedBox(
          height: metrics.s(36),
          child: Row(
            children: [
              Expanded(
                child: _ThemeQuickPill(
                  metrics: metrics,
                  icon: LucideIcons.monitorSmartphone,
                  label: '跟随系统',
                  fillColor: context.readerControls.themePicker.surfaceLow,
                  foreground: context.readerControls.themePicker.secondaryText,
                  iconColor: context.readerControls.themePicker.muted,
                ),
              ),
              SizedBox(width: metrics.s(10)),
              Expanded(
                child: _ThemeQuickPill(
                  metrics: metrics,
                  icon: LucideIcons.leaf,
                  label: '护眼增强',
                  fillColor: context.readerControls.themePicker.greenSoft,
                  foreground: context.readerControls.themePicker.green,
                  iconColor: context.readerControls.themePicker.green,
                  emphasized: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
