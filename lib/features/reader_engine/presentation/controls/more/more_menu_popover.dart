part of '../../reader_controls.dart';

class _MoreMenuPopover extends StatelessWidget {
  const _MoreMenuPopover({
    required this.metrics,
    required this.palette,
    required this.onPageTurn,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final VoidCallback onPageTurn;

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.bookmarkPlus, '加入书签', null),
      (LucideIcons.highlighter, '划线批注', null),
      (LucideIcons.share2, '分享章节', null),
      (LucideIcons.download, '缓存全书', null),
      (LucideIcons.bookOpen, '翻页设置', onPageTurn),
      (LucideIcons.messageCircleWarning, '内容反馈', null),
    ];
    return Positioned(
      key: const ValueKey('reader-more-popover'),
      left: metrics.x(146),
      top: metrics.y(136),
      width: metrics.s(228),
      height: metrics.s(266),
      child: _GlassSurface(
        fill: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(metrics.s(24)),
        child: Padding(
          padding: EdgeInsets.all(metrics.s(10)),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _MenuItem(
                    metrics: metrics,
                    palette: palette,
                    icon: items[i].$1,
                    label: items[i].$2,
                    active: i == 0,
                    onTap: items[i].$3 ?? () {},
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
