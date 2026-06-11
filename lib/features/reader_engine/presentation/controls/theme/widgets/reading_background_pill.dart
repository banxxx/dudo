part of '../../../reader_controls.dart';

class _ReadingBackgroundTile extends StatelessWidget {
  const _ReadingBackgroundTile({
    required this.metrics,
    required this.label,
    required this.palette,
    required this.preference,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final ReaderPalette palette;
  final ReaderBackgroundPreference preference;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controlTheme = context.readerControls;
    final radius = BorderRadius.circular(metrics.s(8));
    return Semantics(
      button: true,
      selected: selected,
      label: '阅读背景$label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            key: ValueKey('reader-background-${preference.id}'),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? controlTheme.themePicker.green
                    : controlTheme.themePicker.surfaceLine,
                width: selected ? metrics.s(2) : metrics.s(1),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: controlTheme.themePicker.green
                            .withValues(alpha: 0.16),
                        blurRadius: metrics.s(10),
                        offset: Offset(0, metrics.s(3)),
                      ),
                    ]
                  : const [],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ReadingBackgroundPreview(
                    metrics: metrics,
                    palette: palette,
                    preference: preference,
                  ),
                  if (selected)
                    Positioned(
                      top: metrics.s(5),
                      right: metrics.s(5),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: controlTheme.themePicker.green,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(metrics.s(2)),
                          child: Icon(
                            LucideIcons.check,
                            size: metrics.s(12),
                            color: controlTheme.themePicker.panel,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingBackgroundCustomTile extends StatelessWidget {
  const _ReadingBackgroundCustomTile({
    required this.metrics,
    required this.palette,
    required this.preference,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final ReaderBackgroundPreference? preference;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final effectivePreference =
        preference ?? ReaderBackgroundPreference.defaults();
    final controlTheme = context.readerControls;
    return Stack(
      fit: StackFit.expand,
      children: [
        _ReadingBackgroundTile(
          metrics: metrics,
          label: selected ? '自定义' : '添加',
          palette: palette,
          preference: effectivePreference,
          selected: selected,
          onTap: () {
            onTap();
          },
        ),
        if (!selected)
          Positioned(
            top: metrics.s(6),
            right: metrics.s(6),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: controlTheme.themePicker.panel.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: controlTheme.themePicker.surfaceLine,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(metrics.s(4)),
                  child: Icon(
                    LucideIcons.plus,
                    size: metrics.s(14),
                    color: controlTheme.themePicker.green,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReadingBackgroundPreview extends StatelessWidget {
  const _ReadingBackgroundPreview({
    required this.metrics,
    required this.palette,
    required this.preference,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final ReaderBackgroundPreference preference;

  @override
  Widget build(BuildContext context) {
    return ReaderBackgroundLayer(
      palette: palette,
      background: preference,
      decorationImageScale: _usesDecorationImage ? 1.72 : 1,
      imageOpacityMultiplier: _usesDecorationImage ? 2.2 : 1,
    );
  }

  bool get _usesDecorationImage {
    return preference.id == ReaderBackgroundPreference.bambooId ||
        preference.id == ReaderBackgroundPreference.bambooCornerId;
  }
}
