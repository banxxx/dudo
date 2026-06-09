part of '../../reader_controls.dart';

class _TypographyPanel extends StatefulWidget {
  const _TypographyPanel({
    required this.metrics,
    required this.palette,
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.pageHorizontalMargin,
    required this.firstLineIndentEnabled,
    required this.textEnhancementEnabled,
    required this.fontLibraryValue,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
    required this.onParagraphSpacingChanged,
    required this.onLineParagraphSpacingChanged,
    required this.onPageHorizontalMarginChanged,
    required this.onFontSelected,
    required this.onManageFonts,
    required this.onFirstLineIndentChanged,
    required this.onTextEnhancementChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final double pageHorizontalMargin;
  final bool firstLineIndentEnabled;
  final bool textEnhancementEnabled;
  final AsyncValue<ReaderFontLibrary> fontLibraryValue;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<double> onParagraphSpacingChanged;
  final void Function(double lineHeight, double paragraphSpacing)
      onLineParagraphSpacingChanged;
  final ValueChanged<double> onPageHorizontalMarginChanged;
  final ValueChanged<ReaderFont> onFontSelected;
  final VoidCallback onManageFonts;
  final ValueChanged<bool> onFirstLineIndentChanged;
  final ValueChanged<bool> onTextEnhancementChanged;

  @override
  State<_TypographyPanel> createState() => _TypographyPanelState();
}

class _TypographyPanelState extends State<_TypographyPanel> {
  static const _panelHeight = 360.0;

  _TypographySpacingPreset? _selectedSpacingPreset;
  _PageMarginPreset? _selectedPageMarginPreset;
  bool _showsFontChooser = false;

  @override
  void initState() {
    super.initState();
    _selectedSpacingPreset = _TypographySpacingPresetData.match(
      lineHeight: widget.lineHeight,
      paragraphSpacing: widget.paragraphSpacing,
    );
    _selectedPageMarginPreset = _PageMarginPresetData.match(
      widget.pageHorizontalMargin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FloatingPanel(
      key: const ValueKey('reader-typography-panel'),
      metrics: widget.metrics,
      top: 314,
      height: _panelHeight,
      palette: widget.palette,
      padding: EdgeInsets.all(widget.metrics.s(16)),
      child: AnimatedSwitcher(
        duration: AppMotion.medium,
        switchInCurve: AppMotion.emphasizedDecelerate,
        switchOutCurve: AppMotion.emphasizedAccelerate,
        transitionBuilder: (child, animation) {
          final isFontChooser =
              child.key == const ValueKey('reader-font-chooser-page');
          final begin =
              isFontChooser ? const Offset(1, 0) : const Offset(-1, 0);
          return ClipRect(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: begin,
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _showsFontChooser
            ? _FontChooserPage(
                key: const ValueKey('reader-font-chooser-page'),
                metrics: widget.metrics,
                libraryValue: widget.fontLibraryValue,
                onBack: () => setState(() => _showsFontChooser = false),
                onFontSelected: (font) {
                  widget.onFontSelected(font);
                  setState(() => _showsFontChooser = false);
                },
                onManageFonts: widget.onManageFonts,
              )
            : _TypographyPanelContent(
                key: const ValueKey('reader-typography-main-page'),
                metrics: widget.metrics,
                fontSize: widget.fontSize,
                lineHeight: widget.lineHeight,
                paragraphSpacing: widget.paragraphSpacing,
                pageHorizontalMargin: widget.pageHorizontalMargin,
                firstLineIndentEnabled: widget.firstLineIndentEnabled,
                textEnhancementEnabled: widget.textEnhancementEnabled,
                selectedFont: widget.fontLibraryValue.valueOrNull?.selectedFont,
                fontLoading: widget.fontLibraryValue.isLoading,
                selectedSpacingPreset: _selectedSpacingPreset,
                selectedPageMarginPreset: _selectedPageMarginPreset,
                onOpenFontChooser: () =>
                    setState(() => _showsFontChooser = true),
                onFontSizeChanged: widget.onFontSizeChanged,
                onLineHeightChanged: (value) {
                  setState(() => _selectedSpacingPreset = null);
                  widget.onLineHeightChanged(value);
                },
                onParagraphSpacingChanged: (value) {
                  setState(() => _selectedSpacingPreset = null);
                  widget.onParagraphSpacingChanged(value);
                },
                onSpacingPresetChanged: (preset) {
                  final data = _TypographySpacingPresetData.fromPreset(preset);
                  setState(() => _selectedSpacingPreset = preset);
                  widget.onLineParagraphSpacingChanged(
                    data.lineHeight,
                    data.paragraphSpacing,
                  );
                },
                onPageHorizontalMarginChanged: (value) {
                  setState(() => _selectedPageMarginPreset = null);
                  widget.onPageHorizontalMarginChanged(value);
                },
                onPageMarginPresetChanged: (preset) {
                  final data = _PageMarginPresetData.fromPreset(preset);
                  setState(() => _selectedPageMarginPreset = preset);
                  widget.onPageHorizontalMarginChanged(data.margin);
                },
                onFirstLineIndentChanged: widget.onFirstLineIndentChanged,
                onTextEnhancementChanged: widget.onTextEnhancementChanged,
              ),
      ),
    );
  }
}

enum _TypographySpacingPreset { compact, comfort, loose }

class _TypographySpacingPresetData {
  const _TypographySpacingPresetData({
    required this.preset,
    required this.lineHeight,
    required this.paragraphSpacing,
  });

  final _TypographySpacingPreset preset;
  final double lineHeight;
  final double paragraphSpacing;

  static const compact = _TypographySpacingPresetData(
    preset: _TypographySpacingPreset.compact,
    lineHeight: 1.5,
    paragraphSpacing: 8,
  );
  static const comfort = _TypographySpacingPresetData(
    preset: _TypographySpacingPreset.comfort,
    lineHeight: 1.72,
    paragraphSpacing: 15,
  );
  static const loose = _TypographySpacingPresetData(
    preset: _TypographySpacingPreset.loose,
    lineHeight: 1.9,
    paragraphSpacing: 24,
  );

  static const values = <_TypographySpacingPresetData>[
    compact,
    comfort,
    loose,
  ];

  static _TypographySpacingPresetData fromPreset(
    _TypographySpacingPreset preset,
  ) {
    return values.firstWhere((data) => data.preset == preset);
  }

  static _TypographySpacingPreset? match({
    required double lineHeight,
    required double paragraphSpacing,
  }) {
    for (final data in values) {
      final lineHeightMatches = (lineHeight - data.lineHeight).abs() < 0.01;
      final paragraphMatches =
          (paragraphSpacing - data.paragraphSpacing).abs() < 0.5;
      if (lineHeightMatches && paragraphMatches) return data.preset;
    }
    return null;
  }
}

enum _PageMarginPreset { narrow, medium, wide }

class _PageMarginPresetData {
  const _PageMarginPresetData({
    required this.preset,
    required this.margin,
  });

  final _PageMarginPreset preset;
  final double margin;

  static const narrow = _PageMarginPresetData(
    preset: _PageMarginPreset.narrow,
    margin: 24,
  );
  static const medium = _PageMarginPresetData(
    preset: _PageMarginPreset.medium,
    margin: ReaderSettings.defaultPageHorizontalMargin,
  );
  static const wide = _PageMarginPresetData(
    preset: _PageMarginPreset.wide,
    margin: 40,
  );

  static const values = <_PageMarginPresetData>[
    narrow,
    medium,
    wide,
  ];

  static _PageMarginPresetData fromPreset(_PageMarginPreset preset) {
    return values.firstWhere((data) => data.preset == preset);
  }

  static _PageMarginPreset? match(double margin) {
    for (final data in values) {
      if ((margin - data.margin).abs() < 0.5) return data.preset;
    }
    return null;
  }
}

class _TypographyPanelContent extends StatelessWidget {
  const _TypographyPanelContent({
    super.key,
    required this.metrics,
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.pageHorizontalMargin,
    required this.firstLineIndentEnabled,
    required this.textEnhancementEnabled,
    required this.selectedFont,
    required this.fontLoading,
    required this.selectedSpacingPreset,
    required this.selectedPageMarginPreset,
    required this.onOpenFontChooser,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
    required this.onParagraphSpacingChanged,
    required this.onSpacingPresetChanged,
    required this.onPageHorizontalMarginChanged,
    required this.onPageMarginPresetChanged,
    required this.onFirstLineIndentChanged,
    required this.onTextEnhancementChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final double pageHorizontalMargin;
  final bool firstLineIndentEnabled;
  final bool textEnhancementEnabled;
  final ReaderFont? selectedFont;
  final bool fontLoading;
  final _TypographySpacingPreset? selectedSpacingPreset;
  final _PageMarginPreset? selectedPageMarginPreset;
  final VoidCallback onOpenFontChooser;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<double> onParagraphSpacingChanged;
  final ValueChanged<_TypographySpacingPreset> onSpacingPresetChanged;
  final ValueChanged<double> onPageHorizontalMarginChanged;
  final ValueChanged<_PageMarginPreset> onPageMarginPresetChanged;
  final ValueChanged<bool> onFirstLineIndentChanged;
  final ValueChanged<bool> onTextEnhancementChanged;

  double get _paragraphSpacingSliderValue {
    const range =
        ReaderSettings.maxParagraphSpacing - ReaderSettings.minParagraphSpacing;
    if (range <= 0) return 0;
    return ((paragraphSpacing - ReaderSettings.minParagraphSpacing) / range)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double get _pageHorizontalMarginSliderValue {
    const range = ReaderSettings.maxPageHorizontalMargin -
        ReaderSettings.minPageHorizontalMargin;
    if (range <= 0) return 0;
    return ((pageHorizontalMargin - ReaderSettings.minPageHorizontalMargin) /
            range)
        .clamp(0.0, 1.0)
        .toDouble();
  }

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
                  icon: LucideIcons.aLargeSmall,
                  label: '字号',
                  valueText: fontSize.round().toString(),
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
                _CurrentFontCard(
                  metrics: metrics,
                  font: selectedFont,
                  loading: fontLoading,
                  onTap: onOpenFontChooser,
                ),
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
                  value: (lineHeight - 1.4) / 0.6,
                  onChanged: (value) =>
                      onLineHeightChanged(1.4 + value.clamp(0.0, 1.0) * 0.6),
                ),
                SizedBox(height: metrics.s(12)),
                _TypographyValueSlider(
                  metrics: metrics,
                  label: '段间距',
                  valueText: '${paragraphSpacing.round()} px',
                  value: _paragraphSpacingSliderValue,
                  onChanged: (value) => onParagraphSpacingChanged(
                    ReaderSettings.minParagraphSpacing +
                        value.clamp(0.0, 1.0) *
                            (ReaderSettings.maxParagraphSpacing -
                                ReaderSettings.minParagraphSpacing),
                  ),
                ),
                SizedBox(height: metrics.s(12)),
                Row(
                  children: [
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '紧凑',
                        selected: selectedSpacingPreset ==
                            _TypographySpacingPreset.compact,
                        onTap: () => onSpacingPresetChanged(
                          _TypographySpacingPreset.compact,
                        ),
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '舒适',
                        selected: selectedSpacingPreset ==
                            _TypographySpacingPreset.comfort,
                        onTap: () => onSpacingPresetChanged(
                          _TypographySpacingPreset.comfort,
                        ),
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '宽松',
                        selected: selectedSpacingPreset ==
                            _TypographySpacingPreset.loose,
                        onTap: () => onSpacingPresetChanged(
                          _TypographySpacingPreset.loose,
                        ),
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
                _TypographyValueSlider(
                  metrics: metrics,
                  label: '左右间距',
                  valueText: '${pageHorizontalMargin.round()} px',
                  helperText: '控制正文与屏幕两侧距离',
                  value: _pageHorizontalMarginSliderValue,
                  onChanged: (value) => onPageHorizontalMarginChanged(
                    ReaderSettings.minPageHorizontalMargin +
                        value.clamp(0.0, 1.0) *
                            (ReaderSettings.maxPageHorizontalMargin -
                                ReaderSettings.minPageHorizontalMargin),
                  ),
                ),
                SizedBox(height: metrics.s(12)),
                Row(
                  children: [
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '窄',
                        selected: selectedPageMarginPreset ==
                            _PageMarginPreset.narrow,
                        onTap: () => onPageMarginPresetChanged(
                          _PageMarginPreset.narrow,
                        ),
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '中等',
                        selected: selectedPageMarginPreset ==
                            _PageMarginPreset.medium,
                        onTap: () => onPageMarginPresetChanged(
                          _PageMarginPreset.medium,
                        ),
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '宽',
                        selected:
                            selectedPageMarginPreset == _PageMarginPreset.wide,
                        onTap: () => onPageMarginPresetChanged(
                          _PageMarginPreset.wide,
                        ),
                      ),
                    ),
                  ],
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
                        selected: firstLineIndentEnabled,
                        onTap: () => onFirstLineIndentChanged(
                          !firstLineIndentEnabled,
                        ),
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '文字增强',
                        selected: textEnhancementEnabled,
                        onTap: () => onTextEnhancementChanged(
                          !textEnhancementEnabled,
                        ),
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyChoicePill(
                        metrics: metrics,
                        label: '标点优化',
                        selected: false,
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

class _FontChooserPage extends StatelessWidget {
  const _FontChooserPage({
    super.key,
    required this.metrics,
    required this.libraryValue,
    required this.onBack,
    required this.onFontSelected,
    required this.onManageFonts,
  });

  final _ReaderOverlayMetrics metrics;
  final AsyncValue<ReaderFontLibrary> libraryValue;
  final VoidCallback onBack;
  final ValueChanged<ReaderFont> onFontSelected;
  final VoidCallback onManageFonts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: metrics.s(38),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _FontBackButton(metrics: metrics, onTap: onBack),
                  SizedBox(width: metrics.s(8)),
                  Text(
                    '字体选择',
                    style: DudoTextStyles.serif(
                      color: const Color(0xFF25251F),
                      fontSize: metrics.s(22),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onManageFonts,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  key: const ValueKey('reader-font-manage-button'),
                  height: metrics.s(30),
                  padding: EdgeInsets.symmetric(horizontal: metrics.s(10)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECDD),
                    borderRadius: BorderRadius.circular(metrics.s(15)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '管理',
                        style: DudoTextStyles.sans(
                          color: const Color(0xFF8A735A),
                          fontSize: metrics.s(11),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: metrics.s(4)),
                      Icon(
                        LucideIcons.settings,
                        size: metrics.s(13),
                        color: const Color(0xFF8A735A),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: metrics.s(12)),
        Expanded(
          child: libraryValue.when(
            loading: () => _FontChooserStateMessage(
              metrics: metrics,
              icon: LucideIcons.loaderCircle,
              text: '正在加载字体',
            ),
            error: (error, _) => _FontChooserStateMessage(
              metrics: metrics,
              icon: LucideIcons.circleAlert,
              text: '字体加载失败',
            ),
            data: (library) => _FontChooserList(
              metrics: metrics,
              library: library,
              onFontSelected: onFontSelected,
            ),
          ),
        ),
      ],
    );
  }
}

class _FontChooserList extends StatelessWidget {
  const _FontChooserList({
    required this.metrics,
    required this.library,
    required this.onFontSelected,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderFontLibrary library;
  final ValueChanged<ReaderFont> onFontSelected;

  @override
  Widget build(BuildContext context) {
    final selectedFont = library.selectedFont;
    final localFonts = library.importedFonts;
    final builtinFonts = library.builtinFonts;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _FontSection(
            metrics: metrics,
            title: '当前使用',
            countText: '1 个',
            children: [
              _FontOptionCard(
                metrics: metrics,
                font: selectedFont,
                selected: true,
                onTap: () => onFontSelected(selectedFont),
              ),
            ],
          ),
          SizedBox(height: metrics.s(12)),
          _FontSection(
            metrics: metrics,
            title: '本地字体',
            countText: localFonts.isEmpty ? '未导入' : '${localFonts.length} 个',
            children: localFonts.isEmpty
                ? [
                    _FontChooserStateMessage(
                      metrics: metrics,
                      icon: LucideIcons.folderOpen,
                      text: '暂无本地字体',
                      compact: true,
                    ),
                  ]
                : [
                    for (final font in localFonts) ...[
                      _FontOptionCard(
                        metrics: metrics,
                        font: font,
                        selected: font.familyKey == library.selectedFamilyKey,
                        onTap: () => onFontSelected(font),
                      ),
                      if (font != localFonts.last)
                        SizedBox(height: metrics.s(8)),
                    ],
                  ],
          ),
          SizedBox(height: metrics.s(12)),
          _FontSection(
            metrics: metrics,
            title: '内置字体',
            countText: '${builtinFonts.length} 个',
            children: [
              for (final font in builtinFonts) ...[
                _FontOptionCard(
                  metrics: metrics,
                  font: font,
                  selected: font.familyKey == library.selectedFamilyKey,
                  onTap: () => onFontSelected(font),
                ),
                if (font != builtinFonts.last) SizedBox(height: metrics.s(8)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FontChooserStateMessage extends StatelessWidget {
  const _FontChooserStateMessage({
    required this.metrics,
    required this.icon,
    required this.text,
    this.compact = false,
  });

  final _ReaderOverlayMetrics metrics;
  final IconData icon;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.s(compact ? 64 : 180),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EA),
        borderRadius: BorderRadius.circular(metrics.s(20)),
        border: Border.all(color: const Color(0xFFE7DCC8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: metrics.s(16), color: const Color(0xFF8A735A)),
          SizedBox(width: metrics.s(8)),
          Text(
            text,
            style: DudoTextStyles.sans(
              color: const Color(0xFF8A735A),
              fontSize: metrics.s(12),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FontBackButton extends StatelessWidget {
  const _FontBackButton({
    required this.metrics,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: metrics.s(32),
        height: metrics.s(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3ECDD),
          borderRadius: BorderRadius.circular(metrics.s(16)),
        ),
        child: Icon(
          LucideIcons.chevronLeft,
          size: metrics.s(17),
          color: const Color(0xFF8A735A),
        ),
      ),
    );
  }
}

class _FontSection extends StatelessWidget {
  const _FontSection({
    required this.metrics,
    required this.title,
    required this.countText,
    required this.children,
  });

  final _ReaderOverlayMetrics metrics;
  final String title;
  final String countText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: metrics.s(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: DudoTextStyles.sans(
                  color: const Color(0xFF25251F),
                  fontSize: metrics.s(13),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                countText,
                style: DudoTextStyles.sans(
                  color: const Color(0xFF8A735A),
                  fontSize: metrics.s(10),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: metrics.s(8)),
        ...children,
      ],
    );
  }
}

class _FontOptionCard extends StatelessWidget {
  const _FontOptionCard({
    required this.metrics,
    required this.font,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderFont font;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: metrics.s(70),
        padding: EdgeInsets.symmetric(horizontal: metrics.s(13)),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDDE8D4) : const Color(0xFFF8F4EA),
          borderRadius: BorderRadius.circular(metrics.s(20)),
          border: Border.all(
            color: selected ? const Color(0xFF5E6F5B) : const Color(0xFFE7DCC8),
            width: selected ? metrics.s(2) : metrics.s(1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          font.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DudoTextStyles.sans(
                            color: const Color(0xFF25251F),
                            fontSize: metrics.s(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: metrics.s(6)),
                      Text(
                        font.sourceLabel,
                        style: DudoTextStyles.sans(
                          color: selected
                              ? const Color(0xFF5E6F5B)
                              : const Color(0xFF8A735A),
                          fontSize: metrics.s(10),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: metrics.s(2)),
                  Text(
                    '旧世界的回声',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: font.familyKey,
                      color: const Color(0xFF25251F),
                      fontSize: metrics.s(17),
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: metrics.s(10)),
            Icon(
              LucideIcons.star,
              size: metrics.s(16),
              color:
                  selected ? const Color(0xFF8A735A) : const Color(0x668A735A),
            ),
            SizedBox(width: metrics.s(8)),
            Icon(
              selected ? LucideIcons.check : LucideIcons.circle,
              size: metrics.s(18),
              color:
                  selected ? const Color(0xFF5E6F5B) : const Color(0xFFD8CDBB),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypographySectionTitle extends StatelessWidget {
  const _TypographySectionTitle({
    required this.metrics,
    required this.icon,
    required this.label,
    this.valueText,
  });

  final _ReaderOverlayMetrics metrics;
  final IconData icon;
  final String label;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
        ),
        if (valueText != null)
          Text(
            valueText!,
            style: DudoTextStyles.sans(
              color: const Color(0xFF8A735A),
              fontSize: metrics.s(13),
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
    return SizedBox(
      height: metrics.s(40),
      child: Row(
        children: [
          Expanded(
            child: _FontSizeSegment(
              metrics: metrics,
              label: 'A-',
              selected: false,
              onTap: () => onFontSizeChanged(
                ReaderSettings.clampFontSize(fontSize - 1),
              ),
            ),
          ),
          SizedBox(width: metrics.s(8)),
          Expanded(
            child: _FontSizeSegment(
              metrics: metrics,
              label: fontSize.round().toString(),
              selected: true,
              onTap: () {},
            ),
          ),
          SizedBox(width: metrics.s(8)),
          Expanded(
            child: _FontSizeSegment(
              metrics: metrics,
              label: 'A+',
              selected: false,
              onTap: () => onFontSizeChanged(
                ReaderSettings.clampFontSize(fontSize + 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FontSizeSegment extends StatelessWidget {
  const _FontSizeSegment({
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
        height: metrics.s(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF25251F) : const Color(0xFFF3ECDD),
          borderRadius: BorderRadius.circular(metrics.s(20)),
        ),
        child: Text(
          label,
          style: DudoTextStyles.sans(
            color: selected ? const Color(0xFFFFF8EA) : const Color(0xFF8A735A),
            fontSize: metrics.s(13),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CurrentFontCard extends StatelessWidget {
  const _CurrentFontCard({
    required this.metrics,
    required this.font,
    required this.loading,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderFont? font;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final font = this.font;
    final displayName = loading ? '正在加载字体' : font?.displayName ?? '默认字体';
    final sourceText = font?.sourceLabel ?? '内置字体';
    final familyKey = font?.familyKey ?? ReaderSettings.defaults().fontFamily;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
                style: TextStyle(
                  fontFamily: familyKey,
                  color: const Color(0xFF5E6F5B),
                  fontSize: metrics.s(14),
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
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
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DudoTextStyles.sans(
                      color: const Color(0xFF25251F),
                      fontSize: metrics.s(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: metrics.s(3)),
                  Text(
                    '$sourceText，点击更换阅读字体',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              padding: EdgeInsets.symmetric(horizontal: metrics.s(10)),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF25251F),
                borderRadius: AppRadius.full,
              ),
              child: Row(
                children: [
                  Text(
                    '更换',
                    style: DudoTextStyles.sans(
                      color: const Color(0xFFFFF8EA),
                      fontSize: metrics.s(12),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: metrics.s(2)),
                  Icon(
                    LucideIcons.chevronRight,
                    size: metrics.s(13),
                    color: const Color(0xFFFFF8EA),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypographyValueSlider extends StatelessWidget {
  const _TypographyValueSlider({
    required this.metrics,
    required this.label,
    required this.valueText,
    required this.value,
    required this.onChanged,
    this.helperText,
  });

  final _ReaderOverlayMetrics metrics;
  final String label;
  final String valueText;
  final String? helperText;
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
          if (helperText != null) ...[
            SizedBox(height: metrics.s(7)),
            Text(
              helperText!,
              style: DudoTextStyles.sans(
                color: const Color(0xFF8A735A),
                fontSize: metrics.s(11),
              ),
            ),
          ],
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
          color: selected ? const Color(0xFFDDE8D4) : const Color(0xFFF3ECDD),
          borderRadius: AppRadius.full,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DudoTextStyles.sans(
            color: selected ? const Color(0xFF1B2918) : const Color(0xFF8A735A),
            fontSize: metrics.s(12),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
