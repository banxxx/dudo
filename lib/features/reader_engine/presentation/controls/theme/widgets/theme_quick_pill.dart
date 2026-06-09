part of '../../../reader_controls.dart';

// 快捷设置按钮：承接主题面板中的轻量操作入口。

class _ThemeQuickPill extends StatelessWidget {
  const _ThemeQuickPill({
    required this.metrics,
    required this.icon,
    required this.label,
    required this.fillColor,
    required this.foreground,
    required this.iconColor,
    this.emphasized = false,
  });

  final _ReaderOverlayMetrics metrics;
  final IconData icon;
  final String label;
  final Color fillColor;
  final Color foreground;
  final Color iconColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.s(36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(metrics.s(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: metrics.s(15), color: iconColor),
          SizedBox(width: metrics.s(6)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DudoTextStyles.sans(
                color: foreground,
                fontSize: metrics.s(13),
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
