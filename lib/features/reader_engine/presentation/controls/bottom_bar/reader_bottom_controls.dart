part of '../../reader_controls.dart';

class _ReaderBottomControlsSlot extends StatelessWidget {
  const _ReaderBottomControlsSlot({
    required this.metrics,
    required this.visible,
    required this.child,
  });

  final _ReaderOverlayMetrics metrics;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('reader-bottom-controls-slot'),
      left: metrics.x(16),
      top: metrics.bottomControlsTop,
      width: metrics.s(358),
      height: metrics.bottomControlsHeight,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSwitcher(
          duration: AppMotion.medium,
          reverseDuration: AppMotion.medium,
          switchInCurve: AppMotion.emphasizedDecelerate,
          switchOutCurve: AppMotion.emphasizedAccelerate,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, 0.32),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: visible
              ? child
              : const SizedBox.shrink(
                  key: ValueKey('reader-bottom-controls-hidden')),
        ),
      ),
    );
  }
}

class _ReaderBottomControls extends StatelessWidget {
  const _ReaderBottomControls({
    required this.metrics,
    required this.mode,
    required this.chapterLabel,
    required this.progress,
    required this.remainingText,
    required this.palette,
    required this.onCatalog,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.onTypography,
    required this.onTheme,
    required this.onListening,
    required this.onPageTurn,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderOverlayMode mode;
  final String chapterLabel;
  final double progress;
  final String remainingText;
  final ReaderPalette palette;
  final VoidCallback onCatalog;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final VoidCallback onTypography;
  final VoidCallback onTheme;
  final VoidCallback onListening;
  final VoidCallback onPageTurn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('reader-bottom-controls'),
      width: metrics.s(358),
      height: metrics.s(124),
      child: _GlassSurface(
        fill: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(metrics.s(28)),
        shadowOffset: Offset(0, metrics.s(14)),
        shadowBlur: metrics.s(34),
        child: Padding(
          padding: EdgeInsets.all(metrics.s(12)),
          child: Column(
            children: [
              SizedBox(
                height: metrics.s(38),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SmallPillButton(
                      label: '上一章',
                      icon: LucideIcons.chevronLeft,
                      palette: palette,
                      onTap: onPreviousChapter ?? () {},
                    ),
                    Text(
                      remainingText,
                      style: DudoTextStyles.sans(
                        color: const Color(0xFF6F6B61),
                        fontSize: metrics.s(12),
                      ),
                    ),
                    _SmallPillButton(
                      label: '下一章',
                      icon: LucideIcons.chevronRight,
                      palette: palette,
                      onTap: onNextChapter ?? () {},
                      reversed: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: metrics.s(10)),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _ToolButton(
                          metrics: metrics,
                          icon: LucideIcons.list,
                          label: '目录',
                          palette: palette,
                          active: mode == ReaderOverlayMode.catalog,
                          onPressed: onCatalog),
                    ),
                    Expanded(
                      child: _ToolButton(
                          metrics: metrics,
                          icon: LucideIcons.type,
                          label: '排版',
                          palette: palette,
                          active: mode == ReaderOverlayMode.typography,
                          onPressed: onTypography),
                    ),
                    Expanded(
                      child: _ToolButton(
                          metrics: metrics,
                          icon: LucideIcons.palette,
                          label: '主题',
                          palette: palette,
                          active: mode == ReaderOverlayMode.theme,
                          onPressed: onTheme),
                    ),
                    Expanded(
                      child: _ToolButton(
                          metrics: metrics,
                          icon: LucideIcons.panelsTopLeft,
                          label: '翻页',
                          palette: palette,
                          active: mode == ReaderOverlayMode.pageTurn,
                          onPressed: onPageTurn),
                    ),
                    Expanded(
                      child: _ToolButton(
                          metrics: metrics,
                          icon: LucideIcons.volume2,
                          label: '朗读',
                          palette: palette,
                          active: mode == ReaderOverlayMode.listening,
                          onPressed: onListening),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
