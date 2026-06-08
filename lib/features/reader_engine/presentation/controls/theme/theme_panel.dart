part of '../../reader_controls.dart';

class _ThemePanel extends StatelessWidget {
  const _ThemePanel({
    required this.metrics,
    required this.palette,
    required this.brightness,
    required this.onPaletteChanged,
    required this.onBrightnessChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final double brightness;
  final ValueChanged<ReaderPalette> onPaletteChanged;
  final ValueChanged<double> onBrightnessChanged;

  @override
  Widget build(BuildContext context) {
    final items = <ReaderPalette>[
      ReaderTheme.parchment,
      ReaderTheme.eyeCare,
      ReaderTheme.night,
    ];
    final displayNames = <String, String>{
      ReaderTheme.parchment.name: '纸页',
      ReaderTheme.eyeCare.name: '护眼',
      ReaderTheme.night.name: '夜读',
    };
    return _FloatingPanel(
      key: const ValueKey('reader-theme-panel'),
      metrics: metrics,
      top: 410,
      height: 270,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('阅读主题',
              style: DudoTextStyles.serif(
                  color: const Color(0xFF25251F),
                  fontSize: metrics.s(22),
                  fontWeight: FontWeight.w700)),
          SizedBox(height: metrics.s(11)),
          SizedBox(
            height: metrics.s(104),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) SizedBox(width: metrics.s(10)),
                  Expanded(
                    child: _ThemeSwatchCard(
                      metrics: metrics,
                      item: items[i],
                      label: displayNames[items[i].name] ?? items[i].name,
                      selected: items[i].name == palette.name,
                      onTap: () => onPaletteChanged(items[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: metrics.s(11)),
          _BrightnessRow(
            metrics: metrics,
            brightness: brightness,
            onBrightnessChanged: onBrightnessChanged,
          ),
          SizedBox(height: metrics.s(11)),
          SizedBox(
            height: metrics.s(32),
            child: Row(
              children: [
                Expanded(
                  child: _ThemeFooterPill(
                    metrics: metrics,
                    label: '跟随系统',
                    background: const Color(0xFFF3ECDD),
                    foreground: const Color(0xFF8A735A),
                    onTap: () => onBrightnessChanged(1),
                  ),
                ),
                SizedBox(width: metrics.s(8)),
                Expanded(
                  child: _ThemeFooterPill(
                    metrics: metrics,
                    label: '护眼增强',
                    background: const Color(0xFFDDE8D4),
                    foreground: const Color(0xFF5E6F5B),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSwatchCard extends StatelessWidget {
  const _ThemeSwatchCard({
    required this.metrics,
    required this.item,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette item;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF5E6F5B)
        : (item.outline ?? const Color(0xFFBFD0B5));
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(metrics.s(10)),
        decoration: BoxDecoration(
          color: item.background,
          borderRadius: BorderRadius.circular(metrics.s(20)),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: DudoTextStyles.sans(
                    color: item.foreground,
                    fontSize: metrics.s(13),
                    fontWeight: FontWeight.w600)),
            SizedBox(height: metrics.s(8)),
            Container(
              height: metrics.s(4),
              decoration: BoxDecoration(
                color: item.foreground.withValues(alpha: 0.4),
                borderRadius: AppRadius.full,
              ),
            ),
            SizedBox(height: metrics.s(8)),
            Container(
              width: metrics.s(42),
              height: metrics.s(4),
              decoration: BoxDecoration(
                color: item.foreground.withValues(alpha: 0.27),
                borderRadius: AppRadius.full,
              ),
            ),
            const Spacer(),
            if (selected)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: metrics.s(18),
                  height: metrics.s(18),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5E6F5B),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.check,
                      size: metrics.s(12), color: const Color(0xFFFFF8EA)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrightnessRow extends StatelessWidget {
  const _BrightnessRow({
    required this.metrics,
    required this.brightness,
    required this.onBrightnessChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final double brightness;
  final ValueChanged<double> onBrightnessChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = brightness.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('亮度',
                style: DudoTextStyles.sans(
                    color: const Color(0xFF25251F),
                    fontSize: metrics.s(14),
                    fontWeight: FontWeight.w600)),
            Text('${(clamped * 100).round()}%',
                style: DudoTextStyles.sans(
                    color: const Color(0xFF8A735A), fontSize: metrics.s(13))),
          ],
        ),
        SizedBox(height: metrics.s(8)),
        LayoutBuilder(
          builder: (context, constraints) {
            void updateFromOffset(double dx) {
              final ratio = (dx / constraints.maxWidth).clamp(0.0, 1.0);
              onBrightnessChanged(ratio);
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => updateFromOffset(d.localPosition.dx),
              onHorizontalDragUpdate: (d) =>
                  updateFromOffset(d.localPosition.dx),
              child: Container(
                height: metrics.s(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFD8CDBB),
                  borderRadius: AppRadius.full,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: clamped == 0 ? 0.0001 : clamped,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF5E6F5B),
                        borderRadius: AppRadius.full,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ThemeFooterPill extends StatelessWidget {
  const _ThemeFooterPill({
    required this.metrics,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(metrics.s(15)),
        ),
        child: Text(label,
            style: DudoTextStyles.sans(
                color: foreground,
                fontSize: metrics.s(12),
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
