part of '../../reader_controls.dart';

class _TypographyPanel extends StatelessWidget {
  const _TypographyPanel({
    required this.metrics,
    required this.palette,
    required this.fontSize,
    required this.lineHeight,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final double fontSize;
  final double lineHeight;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;

  @override
  Widget build(BuildContext context) {
    final panelHeight = _panelHeight();
    return _FloatingPanel(
      key: const ValueKey('reader-typography-panel'),
      metrics: metrics,
      top: 314,
      height: panelHeight,
      palette: palette,
      padding: EdgeInsets.all(metrics.s(16)),
      child: _TypographyPanelContent(
        metrics: metrics,
        fontSize: fontSize,
        lineHeight: lineHeight,
        onFontSizeChanged: onFontSizeChanged,
        onLineHeightChanged: onLineHeightChanged,
      ),
    );
  }

  double _panelHeight() {
    final minimumTop = metrics.topControlsTop +
        metrics.layout.topControlsHeight +
        metrics.s(14);
    final available = metrics.bottomControlsTop - metrics.s(16) - minimumTop;
    return (available / metrics.scale).clamp(380.0, 520.0).toDouble();
  }
}

class _TypographyPanelContent extends StatelessWidget {
  const _TypographyPanelContent({
    required this.metrics,
    required this.fontSize,
    required this.lineHeight,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final double fontSize;
  final double lineHeight;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '阅读排版',
          style: DudoTextStyles.serif(
            color: const Color(0xFF25251F),
            fontSize: metrics.s(22),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: metrics.s(13)),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypographySectionTitle(
                  metrics: metrics,
                  icon: LucideIcons.type,
                  label: '字号',
                ),
                SizedBox(height: metrics.s(9)),
                _FontSizeStepper(
                  metrics: metrics,
                  fontSize: fontSize,
                  onFontSizeChanged: onFontSizeChanged,
                ),
                SizedBox(height: metrics.s(18)),
                _TypographySectionTitle(
                  metrics: metrics,
                  icon: LucideIcons.type,
                  label: '字体',
                ),
                SizedBox(height: metrics.s(9)),
                _CurrentFontCard(metrics: metrics),
                SizedBox(height: metrics.s(18)),
                _TypographySectionTitle(
                  metrics: metrics,
                  icon: LucideIcons.list,
                  label: '行段间距',
                ),
                SizedBox(height: metrics.s(9)),
                _TypographyValueSlider(
                  metrics: metrics,
                  label: '行间距',
                  valueText: '${lineHeight.toStringAsFixed(1)} x',
                  helperText: '可自定义，适合长时间阅读',
                  value: (lineHeight - 1.4) / 0.6,
                  onChanged: (value) =>
                      onLineHeightChanged(1.4 + value.clamp(0.0, 1.0) * 0.6),
                ),
                SizedBox(height: metrics.s(12)),
                _TypographyValueSlider(
                  metrics: metrics,
                  label: '段间距',
                  valueText: '${(fontSize * 0.78).round()} px',
                  helperText: '段落之间保留更清晰的呼吸感',
                  value: 0.45,
                  onChanged: (_) {},
                ),
                SizedBox(height: metrics.s(12)),
                Row(
                  children: [
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '紧凑',
                        selected: lineHeight < 1.62,
                        onTap: () => onLineHeightChanged(1.5),
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '舒适',
                        selected: lineHeight >= 1.62 && lineHeight < 1.82,
                        onTap: () => onLineHeightChanged(1.72),
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '宽松',
                        selected: lineHeight >= 1.82,
                        onTap: () => onLineHeightChanged(1.9),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: metrics.s(18)),
                _TypographySectionTitle(
                  metrics: metrics,
                  icon: LucideIcons.panelLeft,
                  label: '页面边距',
                ),
                SizedBox(height: metrics.s(9)),
                Row(
                  children: [
                    Expanded(
                      child: _MarginOptionCard(
                        metrics: metrics,
                        label: '窄',
                        value: '24 px',
                        selected: false,
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _MarginOptionCard(
                        metrics: metrics,
                        label: '默认',
                        value: '30 px',
                        selected: true,
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _MarginOptionCard(
                        metrics: metrics,
                        label: '宽',
                        value: '40 px',
                        selected: false,
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _MarginOptionCard(
                        metrics: metrics,
                        label: '自定义',
                        value: '可调',
                        selected: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: metrics.s(12)),
                _TypographyValueSlider(
                  metrics: metrics,
                  label: '左右间距',
                  valueText: '30 px',
                  helperText: '控制正文与屏幕两侧距离',
                  value: 0.5,
                  onChanged: (_) {},
                ),
                SizedBox(height: metrics.s(18)),
                _TypographySectionTitle(
                  metrics: metrics,
                  icon: LucideIcons.sparkles,
                  label: '辅助排版',
                ),
                SizedBox(height: metrics.s(9)),
                Row(
                  children: [
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '首行缩进',
                        selected: true,
                        onTap: () {},
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '两端对齐',
                        selected: false,
                        onTap: () {},
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '标点优化',
                        selected: true,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypographySectionTitle extends StatelessWidget {
  const _TypographySectionTitle({
    required this.metrics,
    required this.icon,
    required this.label,
  });

  final _ReaderOverlayMetrics metrics;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: metrics.s(16), color: const Color(0xFF25251F)),
        SizedBox(width: metrics.s(7)),
        Text(
          label,
          style: DudoTextStyles.sans(
            color: const Color(0xFF25251F),
            fontSize: metrics.s(14),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FontSizeStepper extends StatelessWidget {
  const _FontSizeStepper({
    required this.metrics,
    required this.fontSize,
    required this.onFontSizeChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.s(56),
      padding: EdgeInsets.symmetric(horizontal: metrics.s(8)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECDD),
        borderRadius: BorderRadius.circular(metrics.s(18)),
      ),
      child: Row(
        children: [
          _RoundStepperButton(
            metrics: metrics,
            label: 'A-',
            onTap: () => onFontSizeChanged(
              (fontSize - 1).clamp(16, 24).toDouble(),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                fontSize.round().toString(),
                style: DudoTextStyles.sans(
                  color: const Color(0xFF25251F),
                  fontSize: metrics.s(18),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _RoundStepperButton(
            metrics: metrics,
            label: 'A+',
            onTap: () => onFontSizeChanged(
              (fontSize + 1).clamp(16, 24).toDouble(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundStepperButton extends StatelessWidget {
  const _RoundStepperButton({
    required this.metrics,
    required this.label,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: metrics.s(40),
        height: metrics.s(40),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF2),
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: DudoTextStyles.sans(
            color: const Color(0xFF8A735A),
            fontSize: metrics.s(13),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CurrentFontCard extends StatelessWidget {
  const _CurrentFontCard({required this.metrics});

  final _ReaderOverlayMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.s(64),
      padding: EdgeInsets.symmetric(horizontal: metrics.s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(metrics.s(18)),
        border: Border.all(color: const Color(0xFFE7DCC8)),
      ),
      child: Row(
        children: [
          Container(
            width: metrics.s(38),
            height: metrics.s(38),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFDDE8D4),
              shape: BoxShape.circle,
            ),
            child: Text(
              'Aa',
              style: DudoTextStyles.serif(
                color: const Color(0xFF5E6F5B),
                fontSize: metrics.s(14),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: metrics.s(12)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '默认阅读字体',
                  style: DudoTextStyles.sans(
                    color: const Color(0xFF25251F),
                    fontSize: metrics.s(14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: metrics.s(3)),
                Text(
                  '跟随系统，适配长文阅读',
                  style: DudoTextStyles.sans(
                    color: const Color(0xFF8A735A),
                    fontSize: metrics.s(12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: metrics.s(30),
            padding: EdgeInsets.symmetric(horizontal: metrics.s(12)),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF25251F),
              borderRadius: AppRadius.full,
            ),
            child: Text(
              '当前',
              style: DudoTextStyles.sans(
                color: const Color(0xFFFFF8EA),
                fontSize: metrics.s(12),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypographyValueSlider extends StatelessWidget {
  const _TypographyValueSlider({
    required this.metrics,
    required this.label,
    required this.valueText,
    required this.helperText,
    required this.value,
    required this.onChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final String valueText;
  final String helperText;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Container(
      padding: EdgeInsets.all(metrics.s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(metrics.s(18)),
        border: Border.all(color: const Color(0xFFE7DCC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: DudoTextStyles.sans(
                  color: const Color(0xFF25251F),
                  fontSize: metrics.s(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                valueText,
                style: DudoTextStyles.sans(
                  color: const Color(0xFF8A735A),
                  fontSize: metrics.s(12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.s(7)),
          Text(
            helperText,
            style: DudoTextStyles.sans(
              color: const Color(0xFF8A735A),
              fontSize: metrics.s(11),
            ),
          ),
          SizedBox(height: metrics.s(12)),
          LayoutBuilder(
            builder: (context, constraints) {
              void updateFromOffset(double dx) {
                onChanged((dx / constraints.maxWidth).clamp(0.0, 1.0));
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => updateFromOffset(
                  details.localPosition.dx,
                ),
                onHorizontalDragUpdate: (details) => updateFromOffset(
                  details.localPosition.dx,
                ),
                child: SizedBox(
                  height: metrics.s(22),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: metrics.s(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD8CDBB),
                          borderRadius: AppRadius.full,
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: clamped == 0 ? 0.0001 : clamped,
                        child: Container(
                          height: metrics.s(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF5E6F5B),
                            borderRadius: AppRadius.full,
                          ),
                        ),
                      ),
                      Positioned(
                        left: ((constraints.maxWidth - metrics.s(18)) * clamped)
                            .toDouble(),
                        child: Container(
                          width: metrics.s(18),
                          height: metrics.s(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8EA),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF5E6F5B),
                              width: metrics.s(3),
                            ),
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
      ),
    );
  }
}

class _TypographyChoicePill extends StatelessWidget {
  const _TypographyChoicePill({
    required this.metrics,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: metrics.s(38),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF25251F) : const Color(0xFFF3ECDD),
          borderRadius: AppRadius.full,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DudoTextStyles.sans(
            color: selected ? const Color(0xFFFFF8EA) : const Color(0xFF8A735A),
            fontSize: metrics.s(12),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MarginOptionCard extends StatelessWidget {
  const _MarginOptionCard({
    required this.metrics,
    required this.label,
    required this.value,
    required this.selected,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final String value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.s(60),
      padding: EdgeInsets.symmetric(
        horizontal: metrics.s(8),
        vertical: metrics.s(8),
      ),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFDDE8D4) : const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(metrics.s(16)),
        border: Border.all(
          color: selected ? const Color(0xFFBFD0B5) : const Color(0xFFE7DCC8),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.sans(
              color:
                  selected ? const Color(0xFF1B2918) : const Color(0xFF25251F),
              fontSize: metrics.s(12),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: metrics.s(3)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DudoTextStyles.sans(
              color:
                  selected ? const Color(0xFF5E6F5B) : const Color(0xFF8A735A),
              fontSize: metrics.s(10),
            ),
          ),
        ],
      ),
    );
  }
}
