part of '../../../reader_controls.dart';

// 开关设置区块：统一组装主题面板里的开关行。

class _ThemeToggleGroup extends StatelessWidget {
  const _ThemeToggleGroup({
    required this.metrics,
    required this.icon,
    required this.title,
    required this.rows,
  });

  final _ReaderOverlayMetrics metrics;
  final IconData icon;
  final String title;
  final List<_ThemeToggleRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThemeSectionTitle(metrics: metrics, icon: icon, title: title),
        SizedBox(height: metrics.s(8)),
        for (var i = 0; i < rows.length; i++) ...[
          _ThemeToggleRow(metrics: metrics, data: rows[i]),
          if (i < rows.length - 1) SizedBox(height: metrics.s(8)),
        ],
      ],
    );
  }
}
