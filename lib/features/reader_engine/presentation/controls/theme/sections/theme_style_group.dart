part of '../../../reader_controls.dart';

// 主题样式区块：负责组装样式选项与阅读背景入口，不承载具体主题替换逻辑。

class _ThemeStyleGroup extends StatelessWidget {
  const _ThemeStyleGroup({
    required this.metrics,
    required this.palette,
    required this.backgroundPreference,
    required this.onPaletteChanged,
    required this.onBackgroundChanged,
    required this.onCustomBackgroundImport,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final ReaderBackgroundPreference backgroundPreference;
  final ValueChanged<ReaderPalette> onPaletteChanged;
  final ValueChanged<ReaderBackgroundPreference> onBackgroundChanged;
  final Future<void> Function() onCustomBackgroundImport;

  @override
  Widget build(BuildContext context) {
    // 主题卡片是四种主题的固定预览，不跟随当前已选阅读主题变色。
    const paper = Color(0xFFF8F4EA);
    const ink = Color(0xFF25251F);
    const secondaryText = Color(0xFF6F6B61);
    const surfaceLine = Color(0xFFD8CDBB);
    const panel = Color(0xFFFFF8EA);
    const green = Color(0xFF5E6F5B);
    const greenSoft = Color(0xFFDDE8D4);
    const greenLine = Color(0xFFBFD0B5);
    const warmBrown = Color(0xFFE8D7BD);
    const warmBrownLine = Color(0xFFD0B58D);
    const muted = Color(0xFF8A735A);

    const themeOptions = [
      _ThemeStyleOption(
        label: '纸页',
        palette: ReaderTheme.parchment,
        swatchColor: paper,
        fillColor: paper,
        textColor: ink,
        selectedTextColor: ink,
        borderColor: green,
      ),
      _ThemeStyleOption(
        label: '护眼',
        palette: ReaderTheme.eyeCare,
        swatchColor: greenSoft,
        fillColor: greenSoft,
        textColor: secondaryText,
        selectedTextColor: ink,
        borderColor: greenLine,
      ),
      _ThemeStyleOption(
        label: '暖棕',
        palette: ReaderTheme.warmBrown,
        swatchColor: warmBrown,
        fillColor: warmBrown,
        textColor: secondaryText,
        selectedTextColor: ink,
        borderColor: warmBrownLine,
      ),
      _ThemeStyleOption(
        label: '夜读',
        palette: ReaderTheme.night,
        swatchColor: ink,
        fillColor: ink,
        textColor: surfaceLine,
        selectedTextColor: panel,
        borderColor: muted,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThemeSectionTitle(
          metrics: metrics,
          icon: LucideIcons.palette,
          title: '主题样式',
        ),
        SizedBox(height: metrics.s(8)),
        SizedBox(
          height: metrics.s(64),
          child: Row(
            children: [
              for (var i = 0; i < themeOptions.length; i++) ...[
                if (i > 0) SizedBox(width: metrics.s(9)),
                Expanded(
                  child: _ThemeSwatchTile(
                    metrics: metrics,
                    option: themeOptions[i],
                    selected: palette.name == themeOptions[i].palette.name,
                    onTap: () => onPaletteChanged(themeOptions[i].palette),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: metrics.s(8)),
        _ThemeSectionTitle(
          metrics: metrics,
          icon: LucideIcons.image,
          title: '阅读背景',
        ),
        SizedBox(height: metrics.s(8)),
        SizedBox(
          height: metrics.s(68),
          child: Row(
            children: [
              for (var i = 0;
                  i < ReaderBackgroundCatalog.presets.length;
                  i++) ...[
                if (i > 0) SizedBox(width: metrics.s(9)),
                Expanded(
                  child: _ReadingBackgroundTile(
                    metrics: metrics,
                    label: ReaderBackgroundCatalog.presets[i].label,
                    palette: palette,
                    preference: ReaderBackgroundCatalog.presets[i].preference,
                    selected: backgroundPreference.id ==
                        ReaderBackgroundCatalog.presets[i].preference.id,
                    onTap: () => onBackgroundChanged(
                      ReaderBackgroundCatalog.presets[i].preference,
                    ),
                  ),
                ),
              ],
              SizedBox(width: metrics.s(9)),
              Expanded(
                child: _ReadingBackgroundCustomTile(
                  metrics: metrics,
                  palette: palette,
                  preference: backgroundPreference.type ==
                          ReaderBackgroundType.customImage
                      ? backgroundPreference
                      : null,
                  selected: backgroundPreference.type ==
                      ReaderBackgroundType.customImage,
                  onTap: onCustomBackgroundImport,
                ),
              ),
            ],
          ),
        ),
        if (backgroundPreference.type == ReaderBackgroundType.customImage) ...[
          SizedBox(height: metrics.s(8)),
          _CustomBackgroundControls(
            metrics: metrics,
            preference: backgroundPreference,
            onChanged: onBackgroundChanged,
          ),
        ],
      ],
    );
  }
}

class _CustomBackgroundControls extends StatelessWidget {
  const _CustomBackgroundControls({
    required this.metrics,
    required this.preference,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderBackgroundPreference preference;
  final ValueChanged<ReaderBackgroundPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    final blurValue =
        (preference.blurRadius / ReaderBackgroundPreference.maxBlurRadius)
            .clamp(0.0, 1.0)
            .toDouble();
    final opacityValue = preference.opacity.clamp(0.0, 1.0).toDouble();

    return Container(
      padding: EdgeInsets.all(metrics.s(10)),
      decoration: BoxDecoration(
        color: picker.paper,
        borderRadius: BorderRadius.circular(metrics.s(18)),
        border: Border.all(
          color: picker.surfaceLine.withValues(alpha: 0.72),
          width: metrics.s(1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CustomBackgroundToggle(
                  metrics: metrics,
                  title: '灰度',
                  enabled: preference.grayscaleEnabled,
                  onChanged: (value) => onChanged(
                    preference.copyWith(grayscaleEnabled: value),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.s(10)),
          _CustomBackgroundSlider(
            metrics: metrics,
            label: '透明',
            value: opacityValue,
            valueLabel: '${(opacityValue * 100).round()}%',
            onChanged: (value) => onChanged(
              preference.copyWith(
                opacity: value,
              ),
            ),
          ),
          SizedBox(height: metrics.s(10)),
          _CustomBackgroundSlider(
            metrics: metrics,
            label: '模糊强度',
            value: blurValue,
            valueLabel: preference.blurRadius <= 0
                ? '关'
                : preference.blurRadius.toStringAsFixed(0),
            onChanged: (value) => onChanged(
              preference.copyWith(
                blurRadius: value * ReaderBackgroundPreference.maxBlurRadius,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomBackgroundToggle extends StatelessWidget {
  const _CustomBackgroundToggle({
    required this.metrics,
    required this.title,
    required this.enabled,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final String title;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!enabled),
      child: Container(
        height: metrics.s(38),
        padding: EdgeInsets.symmetric(horizontal: metrics.s(10)),
        decoration: BoxDecoration(
          color: context.readerControls.themePicker.panel,
          borderRadius: BorderRadius.circular(metrics.s(14)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.sans(
                  color: context.readerControls.themePicker.ink,
                  fontSize: metrics.s(12),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _ThemeStaticSwitch(metrics: metrics, enabled: enabled),
          ],
        ),
      ),
    );
  }
}

class _CustomBackgroundSlider extends StatelessWidget {
  const _CustomBackgroundSlider({
    required this.metrics,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final double value;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final picker = context.readerControls.themePicker;
    final clamped = value.clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DudoTextStyles.sans(
                  color: picker.ink,
                  fontSize: metrics.s(12),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: DudoTextStyles.sans(
                color: picker.muted,
                fontSize: metrics.s(11),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: metrics.s(8)),
        LayoutBuilder(
          builder: (context, constraints) {
            void updateFromOffset(double dx) {
              onChanged((dx / constraints.maxWidth).clamp(0.0, 1.0).toDouble());
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  updateFromOffset(details.localPosition.dx),
              onHorizontalDragUpdate: (details) =>
                  updateFromOffset(details.localPosition.dx),
              child: SizedBox(
                height: metrics.s(24),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: metrics.s(7),
                      decoration: BoxDecoration(
                        color: picker.surfaceLine,
                        borderRadius: AppRadius.full,
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: clamped == 0 ? 0.0001 : clamped,
                      child: Container(
                        height: metrics.s(7),
                        decoration: BoxDecoration(
                          color: picker.green,
                          borderRadius: AppRadius.full,
                        ),
                      ),
                    ),
                    Positioned(
                      left: ((constraints.maxWidth - metrics.s(20)) * clamped)
                          .toDouble(),
                      child: Container(
                        width: metrics.s(20),
                        height: metrics.s(20),
                        decoration: BoxDecoration(
                          color: picker.panel,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: picker.green,
                            width: metrics.s(2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: picker.ink.withValues(alpha: 0.14),
                              blurRadius: metrics.s(6),
                              offset: Offset(0, metrics.s(2)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
