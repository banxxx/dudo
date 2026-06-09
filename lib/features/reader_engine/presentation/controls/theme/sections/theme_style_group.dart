part of '../../../reader_controls.dart';

// 主题样式区块：负责组装样式选项与阅读背景入口，不承载具体主题替换逻辑。

class _ThemeStyleGroup extends StatelessWidget {
  const _ThemeStyleGroup({
    required this.metrics,
    required this.palette,
    required this.onPaletteChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final ValueChanged<ReaderPalette> onPaletteChanged;

  @override
  Widget build(BuildContext context) {
    final themeOptions = [
      _ThemeStyleOption(
        label: '纸页',
        palette: ReaderTheme.parchment,
        swatchColor: context.readerControls.themePicker.paper,
        fillColor: context.readerControls.themePicker.paper,
        textColor: context.readerControls.themePicker.ink,
        selectedTextColor: context.readerControls.themePicker.ink,
        borderColor: context.readerControls.themePicker.green,
      ),
      _ThemeStyleOption(
        label: '护眼',
        palette: ReaderTheme.eyeCare,
        swatchColor: context.readerControls.themePicker.greenSoft,
        fillColor: context.readerControls.themePicker.greenSoft,
        textColor: context.readerControls.themePicker.secondaryText,
        selectedTextColor: context.readerControls.themePicker.ink,
        borderColor: context.readerControls.themePicker.greenLine,
      ),
      _ThemeStyleOption(
        label: '暖棕',
        palette: ReaderTheme.warmBrown,
        swatchColor: context.readerControls.themePicker.warmBrown,
        fillColor: context.readerControls.themePicker.warmBrown,
        textColor: context.readerControls.themePicker.secondaryText,
        selectedTextColor: context.readerControls.themePicker.ink,
        borderColor: context.readerControls.themePicker.warmBrownLine,
      ),
      _ThemeStyleOption(
        label: '夜读',
        palette: ReaderTheme.night,
        swatchColor: context.readerControls.themePicker.ink,
        fillColor: context.readerControls.themePicker.ink,
        textColor: context.readerControls.themePicker.surfaceLine,
        selectedTextColor: context.readerControls.themePicker.panel,
        borderColor: context.readerControls.themePicker.muted,
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
          height: metrics.s(36),
          child: Row(
            children: [
              Expanded(
                child: _ReadingBackgroundPill(
                  metrics: metrics,
                  label: '纯色',
                  selected: true,
                  fillColor: context.readerControls.themePicker.ink,
                ),
              ),
              SizedBox(width: metrics.s(8)),
              Expanded(
                child: _ReadingBackgroundPill(
                  metrics: metrics,
                  label: '纸纹',
                  fillColor: context.readerControls.action.paperTexture,
                ),
              ),
              SizedBox(width: metrics.s(8)),
              Expanded(
                child: _ReadingBackgroundPill(
                  metrics: metrics,
                  label: '柔光',
                  fillColor: context.readerControls.themePicker.greenSoft,
                ),
              ),
              SizedBox(width: metrics.s(8)),
              Expanded(
                child: _ReadingBackgroundPill(
                  metrics: metrics,
                  label: '深色',
                  fillColor: context.readerControls.themePicker.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
