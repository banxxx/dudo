import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_tokens.dart';

enum ReaderOverlayMode {
  hidden,
  controls,
  catalog,
  typography,
  theme,
  listening,
  more,
  pageTurn,
}

class ReaderControls extends StatelessWidget {
  const ReaderControls({
    super.key,
    required this.mode,
    required this.bookTitle,
    required this.chapterLabel,
    required this.chapterTitle,
    required this.progress,
    required this.palette,
    required this.fontSize,
    required this.lineHeight,
    required this.brightness,
    required this.pageTurnMode,
    required this.isListening,
    required this.onBack,
    required this.onClose,
    required this.onModeChanged,
    required this.onPaletteChanged,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
    required this.onBrightnessChanged,
    required this.onPageTurnModeChanged,
    required this.onListeningChanged,
  });

  final ReaderOverlayMode mode;
  final String bookTitle;
  final String chapterLabel;
  final String chapterTitle;
  final double progress;
  final ReaderPalette palette;
  final double fontSize;
  final double lineHeight;
  final double brightness;
  final String pageTurnMode;
  final bool isListening;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final ValueChanged<ReaderOverlayMode> onModeChanged;
  final ValueChanged<ReaderPalette> onPaletteChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<String> onPageTurnModeChanged;
  final ValueChanged<bool> onListeningChanged;

  bool get _showsBars => mode != ReaderOverlayMode.hidden;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _ReaderOverlayMetrics.fromSize(constraints.biggest);
          final children = <Widget>[];

          if (mode == ReaderOverlayMode.catalog) {
            children.add(
              Positioned.fill(
                child: GestureDetector(
                  onTap: onClose,
                  child: const ColoredBox(color: Color(0x3325251F)),
                ),
              ),
            );
          }

          if (_showsBars) {
            children
              ..add(
                _ReaderTopControls(
                  metrics: metrics,
                  bookTitle: bookTitle,
                  chapterLabel: chapterLabel,
                  chapterTitle: chapterTitle,
                  palette: palette,
                  onBack: onBack,
                  onMore: () => onModeChanged(ReaderOverlayMode.more),
                ),
              )
              ..add(
                _ReaderBottomControls(
                  metrics: metrics,
                  chapterLabel: chapterLabel,
                  progress: progress,
                  palette: palette,
                  onCatalog: () => onModeChanged(ReaderOverlayMode.catalog),
                  onTypography: () =>
                      onModeChanged(ReaderOverlayMode.typography),
                  onTheme: () => onModeChanged(ReaderOverlayMode.theme),
                  onListening: () => onModeChanged(ReaderOverlayMode.listening),
                  onPageTurn: () => onModeChanged(ReaderOverlayMode.pageTurn),
                ),
              );
          }

          switch (mode) {
            case ReaderOverlayMode.catalog:
              children.add(
                _CatalogBottomSheet(
                  metrics: metrics,
                  chapterTitle: chapterTitle,
                  palette: palette,
                  onClose: () => onModeChanged(ReaderOverlayMode.controls),
                ),
              );
            case ReaderOverlayMode.typography:
              children.add(
                _TypographyPanel(
                  metrics: metrics,
                  palette: palette,
                  fontSize: fontSize,
                  lineHeight: lineHeight,
                  onFontSizeChanged: onFontSizeChanged,
                  onLineHeightChanged: onLineHeightChanged,
                ),
              );
            case ReaderOverlayMode.theme:
              children.add(
                _ThemePanel(
                  metrics: metrics,
                  palette: palette,
                  brightness: brightness,
                  onPaletteChanged: onPaletteChanged,
                  onBrightnessChanged: onBrightnessChanged,
                ),
              );
            case ReaderOverlayMode.listening:
              children.add(
                _ListeningPanel(
                  metrics: metrics,
                  palette: palette,
                  isListening: isListening,
                  onListeningChanged: onListeningChanged,
                ),
              );
            case ReaderOverlayMode.more:
              children.add(
                _MoreMenuPopover(
                  metrics: metrics,
                  palette: palette,
                  onPageTurn: () => onModeChanged(ReaderOverlayMode.pageTurn),
                ),
              );
            case ReaderOverlayMode.pageTurn:
              children.add(
                _PageTurnPanel(
                  metrics: metrics,
                  palette: palette,
                  selectedMode: pageTurnMode,
                  onModeChanged: onPageTurnModeChanged,
                ),
              );
            case ReaderOverlayMode.hidden:
            case ReaderOverlayMode.controls:
              break;
          }

          return Stack(children: children);
        },
      ),
    );
  }
}

class _ReaderOverlayMetrics {
  const _ReaderOverlayMetrics({
    required this.scale,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory _ReaderOverlayMetrics.fromSize(Size size) {
    final scale = (size.width / 390).clamp(0.92, 1.12).toDouble();
    final canvasWidth = 390 * scale;
    return _ReaderOverlayMetrics(
      scale: scale,
      left: (size.width - canvasWidth) / 2,
      top: 0,
      width: canvasWidth,
      height: size.height,
    );
  }

  final double scale;
  final double left;
  final double top;
  final double width;
  final double height;

  double x(double value) => left + value * scale;
  double y(double value) => top + value * scale;
  double s(double value) => value * scale;
  double get rightInset => left + s(16);
  double get panelWidth => width - s(32);
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.child,
    required this.borderRadius,
    required this.fill,
    this.shadowColor = const Color(0x2625251F),
    this.shadowOffset = const Offset(0, 12),
    this.shadowBlur = 34,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color fill;
  final Color shadowColor;
  final Offset shadowOffset;
  final double shadowBlur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: borderRadius,
            border: Border.all(color: const Color(0xAAFFFFFF)),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: shadowBlur,
                offset: shadowOffset,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ReaderTopControls extends StatelessWidget {
  const _ReaderTopControls({
    required this.metrics,
    required this.bookTitle,
    required this.chapterLabel,
    required this.chapterTitle,
    required this.palette,
    required this.onBack,
    required this.onMore,
  });

  final _ReaderOverlayMetrics metrics;
  final String bookTitle;
  final String chapterLabel;
  final String chapterTitle;
  final ReaderPalette palette;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('reader-top-controls'),
      left: metrics.x(16),
      top: metrics.y(74),
      width: metrics.s(358),
      height: metrics.s(58),
      child: _GlassSurface(
        fill: palette.panel ?? const Color(0xEAFFF8EA),
        borderRadius: BorderRadius.circular(metrics.s(24)),
        shadowColor: const Color(0x1F25251F),
        shadowOffset: Offset(0, metrics.s(10)),
        shadowBlur: metrics.s(28),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: metrics.s(12)),
          child: Row(
            children: [
              _IconTapArea(
                tooltip: '返回',
                icon: LucideIcons.chevronLeft,
                color: palette.foreground,
                onTap: onBack,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.sans(
                        color: palette.mutedForeground ?? DudoColors.secondary,
                        fontSize: metrics.s(12),
                      ),
                    ),
                    SizedBox(height: metrics.s(2)),
                    Text(
                      '$chapterLabel · $chapterTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DudoTextStyles.serif(
                        color: palette.foreground,
                        fontSize: metrics.s(15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _IconTapArea(
                tooltip: '更多',
                icon: LucideIcons.moreVertical,
                color: palette.foreground,
                onTap: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderBottomControls extends StatelessWidget {
  const _ReaderBottomControls({
    required this.metrics,
    required this.chapterLabel,
    required this.progress,
    required this.palette,
    required this.onCatalog,
    required this.onTypography,
    required this.onTheme,
    required this.onListening,
    required this.onPageTurn,
  });

  final _ReaderOverlayMetrics metrics;
  final String chapterLabel;
  final double progress;
  final ReaderPalette palette;
  final VoidCallback onCatalog;
  final VoidCallback onTypography;
  final VoidCallback onTheme;
  final VoidCallback onListening;
  final VoidCallback onPageTurn;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('reader-bottom-controls'),
      left: metrics.x(16),
      top: metrics.y(700),
      width: metrics.s(358),
      height: metrics.s(124),
      child: _GlassSurface(
        fill: palette.panelStrong ?? const Color(0xF0FFF8EA),
        borderRadius: BorderRadius.circular(metrics.s(28)),
        shadowOffset: Offset(0, metrics.s(14)),
        shadowBlur: metrics.s(34),
        child: Padding(
          padding: EdgeInsets.all(metrics.s(12)),
          child: Column(
            children: [
              SizedBox(
                height: metrics.s(38),
                child: Row(
                  children: [
                    _SmallPillButton(
                      label: '上一章',
                      icon: LucideIcons.chevronLeft,
                      palette: palette,
                      onTap: () {},
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            chapterLabel,
                            style: DudoTextStyles.sans(
                              color: palette.foreground,
                              fontSize: metrics.s(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '已读 ${(progress * 100).round()}%',
                            style: DudoTextStyles.numeric(
                              color: palette.mutedForeground ??
                                  DudoColors.textSecondary,
                              fontSize: metrics.s(11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SmallPillButton(
                      label: '下一章',
                      icon: LucideIcons.chevronRight,
                      palette: palette,
                      onTap: () {},
                      reversed: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: metrics.s(8)),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ToolButton(
                        icon: LucideIcons.list,
                        label: '目录',
                        palette: palette,
                        onPressed: onCatalog),
                    _ToolButton(
                        icon: LucideIcons.type,
                        label: '排版',
                        palette: palette,
                        onPressed: onTypography),
                    _ToolButton(
                        icon: LucideIcons.sunMoon,
                        label: '主题',
                        palette: palette,
                        onPressed: onTheme),
                    _ToolButton(
                        icon: LucideIcons.volume2,
                        label: '听书',
                        palette: palette,
                        onPressed: onListening),
                    _ToolButton(
                        icon: LucideIcons.bookOpen,
                        label: '翻页',
                        palette: palette,
                        onPressed: onPageTurn),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogBottomSheet extends StatelessWidget {
  const _CatalogBottomSheet({
    required this.metrics,
    required this.chapterTitle,
    required this.palette,
    required this.onClose,
  });

  final _ReaderOverlayMetrics metrics;
  final String chapterTitle;
  final ReaderPalette palette;
  final VoidCallback onClose;

  static const chapters = [
    ('第一章 · 旧世界的回声', '42% · 正在阅读'),
    ('第二章 · 未读消息', '约 18 分钟'),
    ('第三章 · 纸页背面', '约 23 分钟'),
    ('第四章 · 长夜航线', '约 19 分钟'),
    ('第五章 · 远处的钟声', '约 21 分钟'),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('reader-catalog-sheet'),
      left: metrics.left,
      top: metrics.y(236),
      width: metrics.width,
      height: metrics.height - metrics.y(236),
      child: _GlassSurface(
        fill: palette.panelStrong ?? DudoColors.surfaceHigh,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(metrics.s(28)),
          topRight: Radius.circular(metrics.s(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              metrics.s(20), metrics.s(14), metrics.s(20), metrics.s(18)),
          child: Column(
            children: [
              Container(
                width: metrics.s(42),
                height: metrics.s(4),
                decoration: BoxDecoration(
                  color: (palette.outline ?? DudoColors.outline)
                      .withValues(alpha: 0.7),
                  borderRadius: AppRadius.full,
                ),
              ),
              SizedBox(height: metrics.s(18)),
              Row(
                children: [
                  Text(
                    '目录',
                    style: DudoTextStyles.serif(
                      color: palette.foreground,
                      fontSize: metrics.s(24),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '共 42 章',
                    style: DudoTextStyles.sans(
                      color:
                          palette.mutedForeground ?? DudoColors.textSecondary,
                      fontSize: metrics.s(12),
                    ),
                  ),
                  SizedBox(width: metrics.s(8)),
                  _IconTapArea(
                    tooltip: '收起目录',
                    icon: LucideIcons.x,
                    color: palette.foreground,
                    onTap: onClose,
                  ),
                ],
              ),
              SizedBox(height: metrics.s(14)),
              _SegmentTabs(
                  metrics: metrics,
                  labels: const ['目录', '书签', '笔记'],
                  selected: 0,
                  palette: palette),
              SizedBox(height: metrics.s(14)),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: chapters.length,
                  separatorBuilder: (_, __) => SizedBox(height: metrics.s(8)),
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    final active = index == 0;
                    return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: metrics.s(14), vertical: metrics.s(12)),
                      decoration: BoxDecoration(
                        color: active
                            ? DudoColors.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(metrics.s(18)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chapter.$1,
                                  style: DudoTextStyles.sans(
                                    color: palette.foreground,
                                    fontSize: metrics.s(14),
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: metrics.s(4)),
                                Text(
                                  chapter.$2,
                                  style: DudoTextStyles.sans(
                                    color: palette.mutedForeground ??
                                        DudoColors.textSecondary,
                                    fontSize: metrics.s(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (active)
                            Icon(LucideIcons.bookOpenCheck,
                                size: metrics.s(18), color: DudoColors.primary),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return _FloatingPanel(
      key: const ValueKey('reader-typography-panel'),
      metrics: metrics,
      top: 444,
      height: 236,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
              metrics: metrics,
              palette: palette,
              title: '阅读排版',
              subtitle:
                  '字号 ${fontSize.round()} · 行高 ${lineHeight.toStringAsFixed(2)}'),
          SizedBox(height: metrics.s(12)),
          Row(
            children: [
              _RoundAction(
                  icon: LucideIcons.minus,
                  palette: palette,
                  onTap: () => onFontSizeChanged(
                      (fontSize - 1).clamp(16, 24).toDouble())),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 16,
                  max: 24,
                  divisions: 8,
                  activeColor: palette.accent ?? DudoColors.primary,
                  inactiveColor: DudoColors.outlineVariant,
                  onChanged: onFontSizeChanged,
                ),
              ),
              _RoundAction(
                  icon: LucideIcons.plus,
                  palette: palette,
                  onTap: () => onFontSizeChanged(
                      (fontSize + 1).clamp(16, 24).toDouble())),
            ],
          ),
          SizedBox(height: metrics.s(8)),
          _ChoiceRow(
            metrics: metrics,
            palette: palette,
            labels: const ['紧凑', '默认', '宽松'],
            selected: lineHeight < 1.65
                ? '紧凑'
                : lineHeight > 1.78
                    ? '宽松'
                    : '默认',
            onSelected: (label) => onLineHeightChanged(label == '紧凑'
                ? 1.55
                : label == '宽松'
                    ? 1.86
                    : 1.72),
          ),
        ],
      ),
    );
  }
}

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
    return _FloatingPanel(
      key: const ValueKey('reader-theme-panel'),
      metrics: metrics,
      top: 424,
      height: 256,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
              metrics: metrics,
              palette: palette,
              title: '阅读主题',
              subtitle: '纸张、亮度与护眼模式'),
          SizedBox(height: metrics.s(14)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final item in ReaderTheme.presets)
                GestureDetector(
                  onTap: () => onPaletteChanged(item),
                  child: Container(
                    width: metrics.s(70),
                    height: metrics.s(58),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          item.background,
                          item.backgroundEnd ?? item.background
                        ],
                      ),
                      borderRadius: BorderRadius.circular(metrics.s(18)),
                      border: Border.all(
                        color: item.name == palette.name
                            ? (palette.accent ?? DudoColors.primary)
                            : (palette.outline ?? DudoColors.outline),
                        width: item.name == palette.name ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('A',
                        style: DudoTextStyles.serif(
                            color: item.foreground,
                            fontSize: metrics.s(22),
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          SizedBox(height: metrics.s(18)),
          Row(
            children: [
              Icon(LucideIcons.sun,
                  size: metrics.s(18),
                  color: palette.mutedForeground ?? DudoColors.secondary),
              Expanded(
                child: Slider(
                  value: brightness,
                  activeColor: palette.accent ?? DudoColors.primary,
                  inactiveColor: DudoColors.outlineVariant,
                  onChanged: onBrightnessChanged,
                ),
              ),
              Text('${(brightness * 100).round()}%',
                  style: DudoTextStyles.numeric(
                      color: palette.foreground,
                      fontSize: metrics.s(12),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListeningPanel extends StatelessWidget {
  const _ListeningPanel({
    required this.metrics,
    required this.palette,
    required this.isListening,
    required this.onListeningChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final bool isListening;
  final ValueChanged<bool> onListeningChanged;

  @override
  Widget build(BuildContext context) {
    final bars = [
      18.0,
      32.0,
      24.0,
      42.0,
      28.0,
      36.0,
      20.0,
      30.0,
      46.0,
      24.0,
      34.0,
      18.0
    ];
    return _FloatingPanel(
      key: const ValueKey('reader-listening-panel'),
      metrics: metrics,
      top: 468,
      height: 212,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
              metrics: metrics,
              palette: palette,
              title: '正在听书',
              subtitle: '温柔女声 · 1.0x'),
          SizedBox(height: metrics.s(18)),
          SizedBox(
            height: metrics.s(48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < bars.length; i++)
                  AnimatedContainer(
                    duration: AppMotion.medium,
                    width: metrics.s(8),
                    height: metrics.s(
                      (isListening ? bars[i] : 14 + i % 3 * 6).toDouble(),
                    ),
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? (palette.accent ?? DudoColors.primary)
                          : DudoColors.outline,
                      borderRadius: AppRadius.full,
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundAction(
                  icon: LucideIcons.skipBack, palette: palette, onTap: () {}),
              SizedBox(width: metrics.s(18)),
              _PlayButton(
                  metrics: metrics,
                  palette: palette,
                  isPlaying: isListening,
                  onTap: () => onListeningChanged(!isListening)),
              SizedBox(width: metrics.s(18)),
              _RoundAction(
                  icon: LucideIcons.skipForward,
                  palette: palette,
                  onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreMenuPopover extends StatelessWidget {
  const _MoreMenuPopover({
    required this.metrics,
    required this.palette,
    required this.onPageTurn,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final VoidCallback onPageTurn;

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.bookmarkPlus, '加入书签', null),
      (LucideIcons.highlighter, '划线批注', null),
      (LucideIcons.share2, '分享章节', null),
      (LucideIcons.download, '缓存全书', null),
      (LucideIcons.bookOpen, '翻页设置', onPageTurn),
      (LucideIcons.messageCircleWarning, '内容反馈', null),
    ];
    return Positioned(
      key: const ValueKey('reader-more-popover'),
      left: metrics.x(146),
      top: metrics.y(136),
      width: metrics.s(228),
      height: metrics.s(266),
      child: _GlassSurface(
        fill: palette.panelStrong ?? const Color(0xF2FFF8EA),
        borderRadius: BorderRadius.circular(metrics.s(24)),
        child: Padding(
          padding: EdgeInsets.all(metrics.s(10)),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _MenuItem(
                    metrics: metrics,
                    palette: palette,
                    icon: items[i].$1,
                    label: items[i].$2,
                    active: i == 0,
                    onTap: items[i].$3 ?? () {},
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageTurnPanel extends StatelessWidget {
  const _PageTurnPanel({
    required this.metrics,
    required this.palette,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final String selectedMode;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return _FloatingPanel(
      key: const ValueKey('reader-page-turn-panel'),
      metrics: metrics,
      top: 444,
      height: 236,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
              metrics: metrics,
              palette: palette,
              title: '翻页方式',
              subtitle: '选择最贴近纸书的翻页节奏'),
          SizedBox(height: metrics.s(16)),
          _ChoiceRow(
            metrics: metrics,
            palette: palette,
            labels: const ['仿真', '滑动', '覆盖'],
            selected: selectedMode,
            onSelected: onModeChanged,
          ),
          SizedBox(height: metrics.s(18)),
          Text('点击区域',
              style: DudoTextStyles.sans(
                  color: palette.mutedForeground ?? DudoColors.textSecondary,
                  fontSize: metrics.s(12))),
          SizedBox(height: metrics.s(8)),
          _ChoiceRow(
            metrics: metrics,
            palette: palette,
            labels: const ['左右翻页', '整屏翻页'],
            selected: '左右翻页',
            onSelected: (_) {},
          ),
        ],
      ),
    );
  }
}

class _FloatingPanel extends StatelessWidget {
  const _FloatingPanel({
    super.key,
    required this.metrics,
    required this.top,
    required this.height,
    required this.palette,
    required this.child,
  });

  final _ReaderOverlayMetrics metrics;
  final double top;
  final double height;
  final ReaderPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: metrics.x(16),
      top: metrics.y(top),
      width: metrics.s(358),
      height: metrics.s(height),
      child: _GlassSurface(
        fill: palette.panelStrong ?? const Color(0xF2FFF8EA),
        borderRadius: BorderRadius.circular(metrics.s(26)),
        child: Padding(
          padding: EdgeInsets.all(metrics.s(16)),
          child: child,
        ),
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.metrics,
    required this.palette,
    required this.title,
    required this.subtitle,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: DudoTextStyles.serif(
                color: palette.foreground,
                fontSize: metrics.s(20),
                fontWeight: FontWeight.w700)),
        SizedBox(height: metrics.s(4)),
        Text(subtitle,
            style: DudoTextStyles.sans(
                color: palette.mutedForeground ?? DudoColors.textSecondary,
                fontSize: metrics.s(12))),
      ],
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs(
      {required this.metrics,
      required this.labels,
      required this.selected,
      required this.palette});

  final _ReaderOverlayMetrics metrics;
  final List<String> labels;
  final int selected;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.s(42),
      padding: EdgeInsets.all(metrics.s(4)),
      decoration: const BoxDecoration(
          color: DudoColors.surfaceLow, borderRadius: AppRadius.full),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == selected
                      ? DudoColors.surfaceHigh
                      : Colors.transparent,
                  borderRadius: AppRadius.full,
                ),
                child: Text(labels[i],
                    style: DudoTextStyles.sans(
                        color: i == selected
                            ? palette.foreground
                            : DudoColors.textSecondary,
                        fontSize: metrics.s(13),
                        fontWeight:
                            i == selected ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow(
      {required this.metrics,
      required this.palette,
      required this.labels,
      required this.selected,
      required this.onSelected});

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in labels) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(label),
              child: AnimatedContainer(
                duration: AppMotion.short,
                height: metrics.s(44),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: label == selected
                      ? DudoColors.primaryContainer
                      : DudoColors.surfaceLow.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(metrics.s(16)),
                  border: Border.all(
                      color: label == selected
                          ? DudoColors.primaryContainerStrong
                          : Colors.transparent),
                ),
                child: Text(label,
                    style: DudoTextStyles.sans(
                        color: palette.foreground,
                        fontSize: metrics.s(13),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          if (label != labels.last) SizedBox(width: metrics.s(8)),
        ],
      ],
    );
  }
}

class _IconTapArea extends StatelessWidget {
  const _IconTapArea(
      {required this.tooltip,
      required this.icon,
      required this.color,
      required this.onTap});

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton(
      {required this.icon,
      required this.label,
      required this.palette,
      required this.onPressed});

  final IconData icon;
  final String label;
  final ReaderPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 58,
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: palette.foreground, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: DudoTextStyles.sans(
                    color: palette.mutedForeground ?? DudoColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SmallPillButton extends StatelessWidget {
  const _SmallPillButton(
      {required this.label,
      required this.icon,
      required this.palette,
      required this.onTap,
      this.reversed = false});

  final String label;
  final IconData icon;
  final ReaderPalette palette;
  final VoidCallback onTap;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon,
          size: 14, color: palette.mutedForeground ?? DudoColors.secondary),
      const SizedBox(width: 2),
      Text(label,
          style: DudoTextStyles.sans(
              color: palette.mutedForeground ?? DudoColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    ];
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.full,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: DudoColors.surfaceLow.withValues(alpha: 0.68),
            borderRadius: AppRadius.full),
        child: Row(children: reversed ? children.reversed.toList() : children),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction(
      {required this.icon, required this.palette, required this.onTap});

  final IconData icon;
  final ReaderPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.full,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
            color: DudoColors.surfaceLow, borderRadius: AppRadius.full),
        child: Icon(icon, size: 18, color: palette.foreground),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton(
      {required this.metrics,
      required this.palette,
      required this.isPlaying,
      required this.onTap});

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.full,
      child: Container(
        width: metrics.s(54),
        height: metrics.s(54),
        decoration: BoxDecoration(
            color: palette.accent ?? DudoColors.primary,
            borderRadius: AppRadius.full),
        child: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play,
            size: metrics.s(24), color: Colors.white),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(
      {required this.metrics,
      required this.palette,
      required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(metrics.s(16)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: metrics.s(10)),
        decoration: BoxDecoration(
          color: active ? DudoColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(metrics.s(16)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: metrics.s(17),
                color: active
                    ? DudoColors.primary
                    : palette.mutedForeground ?? DudoColors.textSecondary),
            SizedBox(width: metrics.s(10)),
            Text(label,
                style: DudoTextStyles.sans(
                    color: palette.foreground,
                    fontSize: metrics.s(13),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
