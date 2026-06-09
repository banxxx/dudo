part of '../../reader_controls.dart';

class _ReaderTopControlsSlot extends StatelessWidget {
  const _ReaderTopControlsSlot({
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
      key: const ValueKey('reader-top-controls-slot'),
      left: metrics.x(16),
      top: metrics.topControlsTop,
      width: metrics.s(358),
      height: metrics.s(58),
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSwitcher(
          duration: AppMotion.medium,
          reverseDuration: AppMotion.medium,
          switchInCurve: AppMotion.emphasizedDecelerate,
          switchOutCurve: AppMotion.emphasizedAccelerate,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, -0.45),
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
                  key: ValueKey('reader-top-controls-hidden')),
        ),
      ),
    );
  }
}

class _ReaderTopControls extends StatelessWidget {
  const _ReaderTopControls({
    required this.metrics,
    required this.bookTitle,
    required this.palette,
    required this.onBack,
    required this.onMore,
  });

  final _ReaderOverlayMetrics metrics;
  final String bookTitle;
  final ReaderPalette palette;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('reader-top-controls'),
      width: metrics.s(358),
      height: metrics.s(58),
      child: _GlassSurface(
        fill: context.readerControls.surface.panel,
        borderRadius: BorderRadius.circular(metrics.s(24)),
        shadowColor: context.readerControls.surface.chromeShadow,
        shadowOffset: Offset(0, metrics.s(10)),
        shadowBlur: metrics.s(28),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: metrics.s(12)),
          child: Row(
            children: [
              _IconTapArea(
                tooltip: '返回',
                icon: LucideIcons.chevronLeft,
                color: context.readerControls.text.primary,
                onTap: onBack,
              ),
              Expanded(
                child: Text(
                  bookTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: DudoTextStyles.sans(
                    color: context.readerControls.text.primary,
                    fontSize: metrics.s(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _IconTapArea(
                tooltip: '更多',
                icon: LucideIcons.ellipsis,
                color: context.readerControls.text.secondary,
                onTap: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
