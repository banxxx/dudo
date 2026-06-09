part of '../../../reader_controls.dart';

// 区块标题：统一主题面板内各分组标题的展示。

class _ThemeSectionTitle extends StatelessWidget {
  const _ThemeSectionTitle({
    required this.metrics,
    required this.icon,
    required this.title,
  });

  final _ReaderOverlayMetrics metrics;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: metrics.s(22),
      child: Row(
        children: [
          Icon(icon,
              size: metrics.s(16),
              color: context.readerControls.themePicker.muted),
          SizedBox(width: metrics.s(7)),
          Text(
            title,
            style: DudoTextStyles.sans(
              color: context.readerControls.themePicker.ink,
              fontSize: metrics.s(13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
