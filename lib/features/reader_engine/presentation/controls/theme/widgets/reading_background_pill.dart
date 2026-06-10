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
    final radius = BorderRadius.circular(metrics.s(14));
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
                  Positioned(
                    left: metrics.s(8),
                    right: metrics.s(8),
                    bottom: metrics.s(6),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: DudoTextStyles.sans(
                        color: selected
                            ? controlTheme.themePicker.ink
                            : controlTheme.themePicker.secondaryText,
                        fontSize: metrics.s(11),
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: metrics.s(6),
                      right: metrics.s(6),
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
          label: selected ? '自定义' : '自定义',
          palette: palette,
          preference: effectivePreference,
          selected: selected,
          onTap: () => onTap(),
        ),
        if (!selected)
          Positioned(
            top: metrics.s(10),
            right: metrics.s(10),
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
    final assetPath = preference.assetPath;
    final filePath = preference.filePath;
    final hasImage = (assetPath != null && assetPath.isNotEmpty) ||
        (filePath != null && filePath.isNotEmpty);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.background,
                palette.backgroundEnd ?? palette.background,
              ],
            ),
          ),
        ),
        if (hasImage)
          Align(
            alignment: preference.alignment,
            child: FractionallySizedBox(
              widthFactor: _imageWidthFactor,
              heightFactor: _imageHeightFactor,
              alignment: preference.alignment,
              child: Opacity(
                opacity: _previewOpacity,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: _PreviewImage(
                    preference: preference,
                    fit: _imageFit,
                    tint: palette.accent ?? palette.foreground,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: metrics.s(10),
          top: metrics.s(12),
          right: metrics.s(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewLine(
                widthFactor: 0.78,
                metrics: metrics,
                color: palette.foreground.withValues(alpha: 0.36),
              ),
              SizedBox(height: metrics.s(5)),
              _PreviewLine(
                widthFactor: 0.62,
                metrics: metrics,
                color: palette.foreground.withValues(alpha: 0.24),
              ),
              SizedBox(height: metrics.s(5)),
              _PreviewLine(
                widthFactor: 0.48,
                metrics: metrics,
                color: palette.foreground.withValues(alpha: 0.18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double get _previewOpacity {
    if (palette.background.computeLuminance() < 0.2) {
      return (preference.opacity * 0.7).clamp(0.0, 0.14).toDouble();
    }
    return preference.opacity.clamp(0.0, 0.22).toDouble();
  }

  BoxFit get _imageFit {
    if (preference.id == ReaderBackgroundPreference.bambooId) {
      return BoxFit.contain;
    }
    return preference.fit;
  }

  double get _imageWidthFactor {
    if (preference.id == ReaderBackgroundPreference.bambooId) {
      return 0.62;
    }
    return 1;
  }

  double get _imageHeightFactor {
    if (preference.id == ReaderBackgroundPreference.bambooId) {
      return 0.62;
    }
    return 1;
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({
    required this.preference,
    required this.fit,
    required this.tint,
  });

  final ReaderBackgroundPreference preference;
  final BoxFit fit;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final assetPath = preference.assetPath;
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: fit,
        alignment: preference.alignment,
        color: tint,
        colorBlendMode: BlendMode.modulate,
      );
    }
    final filePath = preference.filePath;
    if (filePath != null && filePath.isNotEmpty) {
      return Image.file(
        File(filePath),
        fit: fit,
        alignment: preference.alignment,
        color: tint,
        colorBlendMode: BlendMode.modulate,
      );
    }
    return const SizedBox.shrink();
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.widthFactor,
    required this.metrics,
    required this.color,
  });

  final double widthFactor;
  final _ReaderOverlayMetrics metrics;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: metrics.s(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
