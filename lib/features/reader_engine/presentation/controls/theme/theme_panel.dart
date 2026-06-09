part of '../../reader_controls.dart';

class _ThemePanel extends StatelessWidget {
  const _ThemePanel({
    required this.metrics,
    required this.palette,
    required this.brightness,
    required this.onPaletteChanged,
    required this.onBrightnessChanged,
  });

  static const _panelHeight = 360.0;
  static const _paper = Color(0xFFF8F4EA);
  static const _paperPanel = Color(0xFFFFF8EA);
  static const _surfaceLow = Color(0xFFF3ECDD);
  static const _surfaceLine = Color(0xFFD8CDBB);
  static const _ink = Color(0xFF25251F);
  static const _muted = Color(0xFF8A735A);
  static const _secondaryText = Color(0xFF6F6B61);
  static const _green = Color(0xFF5E6F5B);
  static const _greenSoft = Color(0xFFDDE8D4);
  static const _greenLine = Color(0xFFBFD0B5);

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final double brightness;
  final ValueChanged<ReaderPalette> onPaletteChanged;
  final ValueChanged<double> onBrightnessChanged;

  @override
  Widget build(BuildContext context) {
    return _FloatingPanel(
      key: const ValueKey('reader-theme-panel'),
      metrics: metrics,
      top: 378,
      height: _panelHeight,
      palette: palette,
      padding: EdgeInsets.all(metrics.s(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: metrics.s(34),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '阅读主题',
                style: DudoTextStyles.serif(
                  color: _ink,
                  fontSize: metrics.s(22),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: metrics.s(12)),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ThemeStyleGroup(
                    metrics: metrics,
                    palette: palette,
                    onPaletteChanged: onPaletteChanged,
                  ),
                  SizedBox(height: metrics.s(12)),
                  _BrightnessEyeGroup(
                    metrics: metrics,
                    brightness: brightness,
                    onBrightnessChanged: onBrightnessChanged,
                  ),
                  SizedBox(height: metrics.s(12)),
                  _ThemeToggleGroup(
                    metrics: metrics,
                    icon: LucideIcons.eyeOff,
                    title: '界面显示',
                    rows: const [
                      _ThemeToggleRowData(
                        title: '隐藏时间电量',
                        description: '阅读时隐藏顶部时间、电量与信号',
                        enabled: true,
                      ),
                      _ThemeToggleRowData(
                        title: '隐藏章节进度',
                        description: '不显示底部章节名和阅读进度',
                        enabled: false,
                      ),
                      _ThemeToggleRowData(
                        title: '隐藏系统状态栏',
                        description: '进入沉浸阅读时收起系统状态栏',
                        enabled: true,
                      ),
                    ],
                  ),
                  SizedBox(height: metrics.s(12)),
                  _ThemeToggleGroup(
                    metrics: metrics,
                    icon: LucideIcons.hand,
                    title: '手势控制',
                    rows: const [
                      _ThemeToggleRowData(
                        title: '屏蔽手势导航键',
                        description: '降低误触返回、主页等系统手势概率',
                        enabled: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    const themeOptions = [
      _ThemeStyleOption(
        label: '纸页',
        palette: ReaderTheme.parchment,
        swatchColor: _ThemePanel._paper,
        fillColor: _ThemePanel._paper,
        textColor: _ThemePanel._ink,
        selectedTextColor: _ThemePanel._ink,
        borderColor: _ThemePanel._green,
      ),
      _ThemeStyleOption(
        label: '护眼',
        palette: ReaderTheme.eyeCare,
        swatchColor: _ThemePanel._greenSoft,
        fillColor: _ThemePanel._greenSoft,
        textColor: _ThemePanel._secondaryText,
        selectedTextColor: _ThemePanel._ink,
        borderColor: _ThemePanel._greenLine,
      ),
      _ThemeStyleOption(
        label: '暖棕',
        palette: ReaderTheme.warmBrown,
        swatchColor: Color(0xFFE8D7BD),
        fillColor: Color(0xFFE8D7BD),
        textColor: _ThemePanel._secondaryText,
        selectedTextColor: _ThemePanel._ink,
        borderColor: Color(0xFFD0B58D),
      ),
      _ThemeStyleOption(
        label: '夜读',
        palette: ReaderTheme.night,
        swatchColor: _ThemePanel._ink,
        fillColor: _ThemePanel._ink,
        textColor: _ThemePanel._surfaceLine,
        selectedTextColor: _ThemePanel._paperPanel,
        borderColor: _ThemePanel._muted,
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
                  fillColor: _ThemePanel._ink,
                ),
              ),
              SizedBox(width: metrics.s(8)),
              Expanded(
                child: _ReadingBackgroundPill(
                  metrics: metrics,
                  label: '纸纹',
                  fillColor: const Color(0xFFEFE3CF),
                ),
              ),
              SizedBox(width: metrics.s(8)),
              Expanded(
                child: _ReadingBackgroundPill(
                  metrics: metrics,
                  label: '柔光',
                  fillColor: _ThemePanel._greenSoft,
                ),
              ),
              SizedBox(width: metrics.s(8)),
              Expanded(
                child: _ReadingBackgroundPill(
                  metrics: metrics,
                  label: '深色',
                  fillColor: _ThemePanel._ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeStyleOption {
  const _ThemeStyleOption({
    required this.label,
    required this.palette,
    required this.swatchColor,
    required this.fillColor,
    required this.textColor,
    required this.selectedTextColor,
    required this.borderColor,
  });

  final String label;
  final ReaderPalette palette;
  final Color swatchColor;
  final Color fillColor;
  final Color textColor;
  final Color selectedTextColor;
  final Color borderColor;
}

class _ThemeSwatchTile extends StatelessWidget {
  const _ThemeSwatchTile({
    required this.metrics,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final _ThemeStyleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: metrics.s(64),
      padding: EdgeInsets.symmetric(
        horizontal: metrics.s(8),
        vertical: metrics.s(7),
      ),
      decoration: BoxDecoration(
        color: option.fillColor,
        borderRadius: BorderRadius.circular(metrics.s(17)),
        border: Border.all(
          color: selected ? _ThemePanel._green : option.borderColor,
          width: metrics.s(selected ? 2 : 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: option.swatchColor,
                borderRadius: BorderRadius.circular(metrics.s(9)),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.56)
                      : option.borderColor.withValues(alpha: 0.34),
                ),
              ),
            ),
          ),
          SizedBox(height: metrics.s(3)),
          Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.sans(
              color: selected ? option.selectedTextColor : option.textColor,
              fontSize: metrics.s(10),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

class _ReadingBackgroundPill extends StatelessWidget {
  const _ReadingBackgroundPill({
    required this.metrics,
    required this.label,
    required this.fillColor,
    this.selected = false,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final Color fillColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.s(36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? _ThemePanel._ink : fillColor,
        borderRadius: BorderRadius.circular(metrics.s(16)),
        border: Border.all(
          color: selected ? _ThemePanel._ink : _ThemePanel._surfaceLine,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DudoTextStyles.sans(
          color:
              selected ? _ThemePanel._paperPanel : _ThemePanel._secondaryText,
          fontSize: metrics.s(12),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _BrightnessEyeGroup extends StatelessWidget {
  const _BrightnessEyeGroup({
    required this.metrics,
    required this.brightness,
    required this.onBrightnessChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final double brightness;
  final ValueChanged<double> onBrightnessChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = brightness.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThemeSectionTitle(
          metrics: metrics,
          icon: LucideIcons.sun,
          title: '亮度与护眼',
        ),
        SizedBox(height: metrics.s(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '阅读亮度',
              style: DudoTextStyles.sans(
                color: _ThemePanel._ink,
                fontSize: metrics.s(13),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${(clamped * 100).round()}%',
              style: DudoTextStyles.sans(
                color: _ThemePanel._muted,
                fontSize: metrics.s(12),
              ),
            ),
          ],
        ),
        SizedBox(height: metrics.s(8)),
        _ThemeBrightnessSlider(
          metrics: metrics,
          value: clamped,
          onChanged: onBrightnessChanged,
        ),
        SizedBox(height: metrics.s(8)),
        SizedBox(
          height: metrics.s(36),
          child: Row(
            children: [
              Expanded(
                child: _ThemeQuickPill(
                  metrics: metrics,
                  icon: LucideIcons.monitorSmartphone,
                  label: '跟随系统',
                  fillColor: _ThemePanel._surfaceLow,
                  foreground: _ThemePanel._secondaryText,
                  iconColor: _ThemePanel._muted,
                ),
              ),
              SizedBox(width: metrics.s(10)),
              Expanded(
                child: _ThemeQuickPill(
                  metrics: metrics,
                  icon: LucideIcons.leaf,
                  label: '护眼增强',
                  fillColor: _ThemePanel._greenSoft,
                  foreground: _ThemePanel._green,
                  iconColor: _ThemePanel._green,
                  emphasized: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeBrightnessSlider extends StatelessWidget {
  const _ThemeBrightnessSlider({
    required this.metrics,
    required this.value,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        void updateFromOffset(double dx) {
          onChanged((dx / constraints.maxWidth).clamp(0.0, 1.0).toDouble());
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => updateFromOffset(details.localPosition.dx),
          onHorizontalDragUpdate: (details) =>
              updateFromOffset(details.localPosition.dx),
          child: SizedBox(
            height: metrics.s(24),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: metrics.s(8),
                  decoration: const BoxDecoration(
                    color: _ThemePanel._surfaceLine,
                    borderRadius: AppRadius.full,
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: clamped == 0 ? 0.0001 : clamped,
                  child: Container(
                    height: metrics.s(8),
                    decoration: const BoxDecoration(
                      color: _ThemePanel._green,
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
                      color: _ThemePanel._paperPanel,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _ThemePanel._green,
                        width: metrics.s(2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _ThemePanel._ink.withValues(alpha: 0.14),
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
    );
  }
}

class _ThemeQuickPill extends StatelessWidget {
  const _ThemeQuickPill({
    required this.metrics,
    required this.icon,
    required this.label,
    required this.fillColor,
    required this.foreground,
    required this.iconColor,
    this.emphasized = false,
  });

  final _ReaderOverlayMetrics metrics;
  final IconData icon;
  final String label;
  final Color fillColor;
  final Color foreground;
  final Color iconColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.s(36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(metrics.s(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: metrics.s(15), color: iconColor),
          SizedBox(width: metrics.s(6)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DudoTextStyles.sans(
                color: foreground,
                fontSize: metrics.s(13),
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleGroup extends StatelessWidget {
  const _ThemeToggleGroup({
    required this.metrics,
    required this.icon,
    required this.title,
    required this.rows,
  });

  final _ReaderOverlayMetrics metrics;
  final IconData icon;
  final String title;
  final List<_ThemeToggleRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThemeSectionTitle(metrics: metrics, icon: icon, title: title),
        SizedBox(height: metrics.s(8)),
        for (var i = 0; i < rows.length; i++) ...[
          _ThemeToggleRow(metrics: metrics, data: rows[i]),
          if (i < rows.length - 1) SizedBox(height: metrics.s(8)),
        ],
      ],
    );
  }
}

class _ThemeToggleRowData {
  const _ThemeToggleRowData({
    required this.title,
    required this.description,
    required this.enabled,
  });

  final String title;
  final String description;
  final bool enabled;
}

class _ThemeToggleRow extends StatelessWidget {
  const _ThemeToggleRow({
    required this.metrics,
    required this.data,
  });

  final _ReaderOverlayMetrics metrics;
  final _ThemeToggleRowData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.s(46),
      padding: EdgeInsets.symmetric(horizontal: metrics.s(12)),
      decoration: BoxDecoration(
        color: _ThemePanel._paper,
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
                    color: _ThemePanel._ink,
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
                    color: _ThemePanel._muted,
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
  }
}

class _ThemeStaticSwitch extends StatelessWidget {
  const _ThemeStaticSwitch({
    required this.metrics,
    required this.enabled,
  });

  final _ReaderOverlayMetrics metrics;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: metrics.s(44),
      height: metrics.s(26),
      padding: EdgeInsets.all(metrics.s(3)),
      decoration: BoxDecoration(
        color: enabled ? _ThemePanel._green : _ThemePanel._surfaceLine,
        borderRadius: BorderRadius.circular(metrics.s(13)),
      ),
      child: Align(
        alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: metrics.s(20),
          height: metrics.s(20),
          decoration: BoxDecoration(
            color: _ThemePanel._paperPanel,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _ThemePanel._ink.withValues(alpha: 0.14),
                blurRadius: metrics.s(4),
                offset: Offset(0, metrics.s(1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSectionTitle extends StatelessWidget {
  const _ThemeSectionTitle({
    required this.metrics,
    required this.icon,
    required this.title,
  });

  final _ReaderOverlayMetrics metrics;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: metrics.s(22),
      child: Row(
        children: [
          Icon(icon, size: metrics.s(16), color: _ThemePanel._muted),
          SizedBox(width: metrics.s(7)),
          Text(
            title,
            style: DudoTextStyles.sans(
              color: _ThemePanel._ink,
              fontSize: metrics.s(13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
