part of '../../../reader_controls.dart';

// 主题样式区块：负责组装样式选项与阅读背景入口，不承载具体主题替换逻辑。

class _ThemeStyleGroup extends StatelessWidget {
  const _ThemeStyleGroup({
    required this.metrics,
    required this.palette,
    required this.backgroundPreference,
    required this.customBackgroundPreference,
    required this.onPaletteChanged,
    required this.onBackgroundChanged,
    required this.onCustomBackgroundImport,
    required this.onCustomBackgroundEdit,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final ReaderBackgroundPreference backgroundPreference;
  final ReaderBackgroundPreference? customBackgroundPreference;
  final ValueChanged<ReaderPalette> onPaletteChanged;
  final ValueChanged<ReaderBackgroundPreference> onBackgroundChanged;
  final Future<void> Function() onCustomBackgroundImport;
  final VoidCallback onCustomBackgroundEdit;

  @override
  Widget build(BuildContext context) {
    final effectiveCustomBackground =
        backgroundPreference.type == ReaderBackgroundType.customImage
            ? backgroundPreference
            : customBackgroundPreference;
    final customSelected =
        backgroundPreference.type == ReaderBackgroundType.customImage;

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
          height: metrics.s(34),
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
                  preference: effectiveCustomBackground,
                  selected: customSelected,
                  onTap: customSelected
                      ? () async => onCustomBackgroundEdit()
                      : effectiveCustomBackground != null
                          ? () async =>
                              onBackgroundChanged(effectiveCustomBackground)
                          : onCustomBackgroundImport,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
