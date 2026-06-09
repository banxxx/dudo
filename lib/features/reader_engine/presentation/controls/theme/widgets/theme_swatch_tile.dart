part of '../../../reader_controls.dart';

// 主题样式卡片：只处理单个样式项的展示与点击态。

class _ThemeSwatchTile extends StatelessWidget {
  const _ThemeSwatchTile({
    required this.metrics,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final _ThemeStyleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: metrics.s(64),
      padding: EdgeInsets.symmetric(
        horizontal: metrics.s(8),
        vertical: metrics.s(7),
      ),
      decoration: BoxDecoration(
        color: option.fillColor,
        borderRadius: BorderRadius.circular(metrics.s(17)),
        border: Border.all(
          color: option.borderColor,
          width: metrics.s(selected ? 2 : 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: option.swatchColor,
                borderRadius: BorderRadius.circular(metrics.s(9)),
              ),
            ),
          ),
          SizedBox(height: metrics.s(3)),
          Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.sans(
              color: selected ? option.selectedTextColor : option.textColor,
              fontSize: metrics.s(10),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
