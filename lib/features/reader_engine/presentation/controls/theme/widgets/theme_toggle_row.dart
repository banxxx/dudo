part of '../../../reader_controls.dart';

// 开关行控件：只负责一行设置项的布局和静态状态展示。

class _ThemeToggleRow extends StatelessWidget {
  const _ThemeToggleRow({
    required this.metrics,
    required this.data,
  });

  final _ReaderOverlayMetrics metrics;
  final _ThemeToggleRowData data;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: metrics.s(46),
      padding: EdgeInsets.symmetric(horizontal: metrics.s(12)),
      decoration: BoxDecoration(
        color: context.readerControls.themePicker.paper,
        borderRadius: BorderRadius.circular(metrics.s(18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: context.readerControls.themePicker.ink,
                    fontSize: metrics.s(13),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: metrics.s(2)),
                Text(
                  data.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DudoTextStyles.sans(
                    color: context.readerControls.themePicker.muted,
                    fontSize: metrics.s(10),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: metrics.s(10)),
          _ThemeStaticSwitch(metrics: metrics, enabled: data.enabled),
        ],
      ),
    );

    return GestureDetector(
      onTap:
          data.onChanged == null ? null : () => data.onChanged!(!data.enabled),
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
