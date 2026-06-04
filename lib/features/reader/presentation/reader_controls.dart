import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../domain/reader_catalog_item.dart';
import '../domain/reader_overlay_mode.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_tokens.dart';

class ReaderControls extends StatelessWidget {
  const ReaderControls({
    super.key,
    required this.mode,
    required this.bookTitle,
    required this.chapterLabel,
    required this.chapterTitle,
    required this.progress,
    required this.remainingText,
    required this.palette,
    required this.fontSize,
    required this.lineHeight,
    required this.brightness,
    required this.pageTurnMode,
    required this.isListening,
    required this.currentChapterIndex,
    required this.chapterCount,
    required this.catalogItems,
    this.catalogHasMore = false,
    this.catalogIsLoadingMore = false,
    this.onCatalogLoadMore,
    required this.onBack,
    required this.onClose,
    required this.onModeChanged,
    required this.onChapterSelected,
    required this.onPreviousChapter,
    required this.onNextChapter,
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
  final String remainingText;
  final ReaderPalette palette;
  final double fontSize;
  final double lineHeight;
  final double brightness;
  final String pageTurnMode;
  final bool isListening;
  final int currentChapterIndex;
  final int chapterCount;
  final List<ReaderCatalogItem> catalogItems;
  final bool catalogHasMore;
  final bool catalogIsLoadingMore;
  final VoidCallback? onCatalogLoadMore;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final ValueChanged<ReaderOverlayMode> onModeChanged;
  final ValueChanged<int> onChapterSelected;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
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

          children
            ..add(
              _ReaderTopControlsSlot(
                metrics: metrics,
                visible: _showsBars,
                child: _ReaderTopControls(
                  metrics: metrics,
                  bookTitle: bookTitle,
                  palette: palette,
                  onBack: onBack,
                  onMore: () => onModeChanged(ReaderOverlayMode.more),
                ),
              ),
            )
            ..add(
              _ReaderBottomControlsSlot(
                metrics: metrics,
                visible: _showsBars,
                child: _ReaderBottomControls(
                  metrics: metrics,
                  mode: mode,
                  chapterLabel: chapterLabel,
                  progress: progress,
                  remainingText: remainingText,
                  palette: palette,
                  onCatalog: () => onModeChanged(ReaderOverlayMode.catalog),
                  onPreviousChapter: onPreviousChapter,
                  onNextChapter: onNextChapter,
                  onTypography: () =>
                      onModeChanged(ReaderOverlayMode.typography),
                  onTheme: () => onModeChanged(ReaderOverlayMode.theme),
                  onListening: () => onModeChanged(ReaderOverlayMode.listening),
                  onPageTurn: () => onModeChanged(ReaderOverlayMode.pageTurn),
                ),
              ),
            );

          switch (mode) {
            case ReaderOverlayMode.catalog:
              children.add(
                _CatalogBottomSheet(
                  metrics: metrics,
                  bookTitle: bookTitle,
                  chapterTitle: chapterTitle,
                  chapterCount: chapterCount,
                  currentChapterIndex: currentChapterIndex,
                  chapters: catalogItems,
                  hasMore: catalogHasMore,
                  isLoadingMore: catalogIsLoadingMore,
                  palette: palette,
                  onClose: () => onModeChanged(ReaderOverlayMode.controls),
                  onChapterSelected: onChapterSelected,
                  onLoadMore: onCatalogLoadMore,
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
                  chapterTitle: chapterTitle,
                  remainingText: remainingText,
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
    this.shadowColor = const Color(0x3325251F),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: shadowBlur,
            offset: shadowOffset,
          ),
          const BoxShadow(
            color: Color(0x12FFFFFF),
            blurRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: borderRadius,
            border: Border.all(color: const Color(0xFFE7DCC8)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ReaderTopControlsSlot extends StatelessWidget {
  const _ReaderTopControlsSlot({
    required this.metrics,
    required this.visible,
    required this.child,
  });

  final _ReaderOverlayMetrics metrics;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('reader-top-controls-slot'),
      left: metrics.x(16),
      top: metrics.y(74),
      width: metrics.s(358),
      height: metrics.s(58),
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSwitcher(
          duration: AppMotion.medium,
          reverseDuration: AppMotion.medium,
          switchInCurve: AppMotion.emphasizedDecelerate,
          switchOutCurve: AppMotion.emphasizedAccelerate,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, -0.45),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: visible
              ? child
              : const SizedBox.shrink(
                  key: ValueKey('reader-top-controls-hidden')),
        ),
      ),
    );
  }
}

class _ReaderBottomControlsSlot extends StatelessWidget {
  const _ReaderBottomControlsSlot({
    required this.metrics,
    required this.visible,
    required this.child,
  });

  final _ReaderOverlayMetrics metrics;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('reader-bottom-controls-slot'),
      left: metrics.x(16),
      top: metrics.y(700),
      width: metrics.s(358),
      height: metrics.s(124),
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSwitcher(
          duration: AppMotion.medium,
          reverseDuration: AppMotion.medium,
          switchInCurve: AppMotion.emphasizedDecelerate,
          switchOutCurve: AppMotion.emphasizedAccelerate,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, 0.32),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: visible
              ? child
              : const SizedBox.shrink(
                  key: ValueKey('reader-bottom-controls-hidden')),
        ),
      ),
    );
  }
}

class _ReaderTopControls extends StatelessWidget {
  const _ReaderTopControls({
    required this.metrics,
    required this.bookTitle,
    required this.palette,
    required this.onBack,
    required this.onMore,
  });

  final _ReaderOverlayMetrics metrics;
  final String bookTitle;
  final ReaderPalette palette;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('reader-top-controls'),
      width: metrics.s(358),
      height: metrics.s(58),
      child: _GlassSurface(
        fill: const Color(0xFFFFF8EA),
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
                color: const Color(0xFF25251F),
                onTap: onBack,
              ),
              Expanded(
                child: Text(
                  bookTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: DudoTextStyles.sans(
                    color: const Color(0xFF25251F),
                    fontSize: metrics.s(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _IconTapArea(
                tooltip: '更多',
                icon: LucideIcons.ellipsis,
                color: const Color(0xFF8A735A),
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
    required this.mode,
    required this.chapterLabel,
    required this.progress,
    required this.remainingText,
    required this.palette,
    required this.onCatalog,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.onTypography,
    required this.onTheme,
    required this.onListening,
    required this.onPageTurn,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderOverlayMode mode;
  final String chapterLabel;
  final double progress;
  final String remainingText;
  final ReaderPalette palette;
  final VoidCallback onCatalog;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final VoidCallback onTypography;
  final VoidCallback onTheme;
  final VoidCallback onListening;
  final VoidCallback onPageTurn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('reader-bottom-controls'),
      width: metrics.s(358),
      height: metrics.s(124),
      child: _GlassSurface(
        fill: const Color(0xFFFFF8EA),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SmallPillButton(
                      label: '上一章',
                      icon: LucideIcons.chevronLeft,
                      palette: palette,
                      onTap: onPreviousChapter ?? () {},
                    ),
                    Text(
                      remainingText,
                      style: DudoTextStyles.sans(
                        color: const Color(0xFF6F6B61),
                        fontSize: metrics.s(12),
                      ),
                    ),
                    _SmallPillButton(
                      label: '下一章',
                      icon: LucideIcons.chevronRight,
                      palette: palette,
                      onTap: onNextChapter ?? () {},
                      reversed: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: metrics.s(10)),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _ToolButton(
                          icon: LucideIcons.list,
                          label: '目录',
                          palette: palette,
                          active: mode == ReaderOverlayMode.catalog,
                          onPressed: onCatalog),
                    ),
                    Expanded(
                      child: _ToolButton(
                          icon: LucideIcons.type,
                          label: '排版',
                          palette: palette,
                          active: mode == ReaderOverlayMode.typography,
                          onPressed: onTypography),
                    ),
                    Expanded(
                      child: _ToolButton(
                          icon: LucideIcons.palette,
                          label: '主题',
                          palette: palette,
                          active: mode == ReaderOverlayMode.theme,
                          onPressed: onTheme),
                    ),
                    Expanded(
                      child: _ToolButton(
                          icon: LucideIcons.panelsTopLeft,
                          label: '翻页',
                          palette: palette,
                          active: mode == ReaderOverlayMode.pageTurn,
                          onPressed: onPageTurn),
                    ),
                    Expanded(
                      child: _ToolButton(
                          icon: LucideIcons.volume2,
                          label: '朗读',
                          palette: palette,
                          active: mode == ReaderOverlayMode.listening,
                          onPressed: onListening),
                    ),
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
    required this.bookTitle,
    required this.chapterTitle,
    required this.chapterCount,
    required this.currentChapterIndex,
    required this.chapters,
    required this.hasMore,
    required this.isLoadingMore,
    required this.palette,
    required this.onClose,
    required this.onChapterSelected,
    this.onLoadMore,
  });

  final _ReaderOverlayMetrics metrics;
  final String bookTitle;
  final String chapterTitle;
  final int chapterCount;
  final int currentChapterIndex;
  final List<ReaderCatalogItem> chapters;
  final bool hasMore;
  final bool isLoadingMore;
  final ReaderPalette palette;
  final VoidCallback onClose;
  final ValueChanged<int> onChapterSelected;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('reader-catalog-sheet'),
      left: metrics.left,
      top: metrics.height - metrics.s(608),
      width: metrics.width,
      height: metrics.s(608),
      child: _GlassSurface(
        fill: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(metrics.s(28)),
          topRight: Radius.circular(metrics.s(28)),
          bottomLeft: Radius.circular(metrics.s(32)),
          bottomRight: Radius.circular(metrics.s(32)),
        ),
        shadowColor: const Color(0x2625251F),
        shadowOffset: Offset(0, -metrics.s(12)),
        shadowBlur: metrics.s(34),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$bookTitle · 共 $chapterCount 章',
                        style: DudoTextStyles.sans(
                          color: const Color(0xFF8A735A),
                          fontSize: metrics.s(12),
                        ),
                      ),
                      SizedBox(height: metrics.s(4)),
                      Text(
                        '目录',
                        style: DudoTextStyles.serif(
                          color: const Color(0xFF25251F),
                          fontSize: metrics.s(26),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '倒序',
                    style: DudoTextStyles.sans(
                      color: const Color(0xFF5E6F5B),
                      fontSize: metrics.s(13),
                      fontWeight: FontWeight.w600,
                    ),
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
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter < metrics.s(160) &&
                        hasMore &&
                        !isLoadingMore) {
                      onLoadMore?.call();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    key: const ValueKey('reader-catalog-list'),
                    padding: EdgeInsets.zero,
                    itemCount:
                        chapters.length + (hasMore || isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => SizedBox(height: metrics.s(8)),
                    itemBuilder: (context, index) {
                      if (index >= chapters.length) {
                        return _CatalogLoadingFooter(
                          metrics: metrics,
                          palette: palette,
                          isLoading: isLoadingMore,
                        );
                      }
                      final chapter = chapters[index];
                      final active =
                          chapter.chapterIndex == currentChapterIndex;
                      return GestureDetector(
                        onTap: () => onChapterSelected(chapter.chapterIndex),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: metrics.s(14),
                              vertical: metrics.s(12)),
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
                                      chapter.title,
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
                                      chapter.subtitle,
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
                                    size: metrics.s(18),
                                    color: DudoColors.primary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogLoadingFooter extends StatelessWidget {
  const _CatalogLoadingFooter({
    required this.metrics,
    required this.palette,
    required this.isLoading,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('reader-catalog-loading-footer'),
      padding: EdgeInsets.symmetric(vertical: metrics.s(12)),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: metrics.s(18),
                height: metrics.s(18),
                child: CircularProgressIndicator(
                  strokeWidth: metrics.s(2),
                  color: DudoColors.primary,
                ),
              )
            : Text(
                '继续加载目录',
                style: DudoTextStyles.sans(
                  color: palette.mutedForeground ?? DudoColors.textSecondary,
                  fontSize: metrics.s(12),
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
          Text(
            '阅读排版',
            style: DudoTextStyles.serif(
              color: const Color(0xFF25251F),
              fontSize: metrics.s(22),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: metrics.s(12)),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '字号',
                    style: DudoTextStyles.sans(
                      color: const Color(0xFF25251F),
                      fontSize: metrics.s(14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    fontSize.round().toString(),
                    style: DudoTextStyles.sans(
                      color: const Color(0xFF8A735A),
                      fontSize: metrics.s(13),
                    ),
                  ),
                ],
              ),
              SizedBox(height: metrics.s(8)),
              SizedBox(
                height: metrics.s(40),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypographyPill(
                        label: 'A-',
                        metrics: metrics,
                        selected: false,
                        onTap: () => onFontSizeChanged(
                            (fontSize - 1).clamp(16, 24).toDouble()),
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyPill(
                        label: fontSize.round().toString(),
                        metrics: metrics,
                        selected: true,
                        onTap: () {},
                      ),
                    ),
                    SizedBox(width: metrics.s(8)),
                    Expanded(
                      child: _TypographyPill(
                        label: 'A+',
                        metrics: metrics,
                        selected: false,
                        onTap: () => onFontSizeChanged(
                            (fontSize + 1).clamp(16, 24).toDouble()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.s(12)),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _TypographyOptionCard(
                    metrics: metrics,
                    title: '行距',
                    value: '舒适',
                    selected: true,
                    onTap: () => onLineHeightChanged(1.72),
                  ),
                ),
                SizedBox(width: metrics.s(10)),
                Expanded(
                  child: _TypographyOptionCard(
                    metrics: metrics,
                    title: '字体',
                    value: '宋体',
                    selected: false,
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

class _TypographyPill extends StatelessWidget {
  const _TypographyPill({
    required this.label,
    required this.metrics,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final _ReaderOverlayMetrics metrics;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.full,
      child: Container(
        height: metrics.s(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF25251F) : const Color(0xFFF3ECDD),
          borderRadius: AppRadius.full,
        ),
        child: Text(
          label,
          style: DudoTextStyles.sans(
            color: selected ? const Color(0xFFFFF8EA) : const Color(0xFF8A735A),
            fontSize: metrics.s(13),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TypographyOptionCard extends StatelessWidget {
  const _TypographyOptionCard({
    required this.metrics,
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final String title;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        selected ? const Color(0xFF1B2918) : const Color(0xFF25251F);
    final valueColor =
        selected ? const Color(0xFF5E6F5B) : const Color(0xFF8A735A);
    final sampleColor =
        selected ? const Color(0x665E6F5B) : const Color(0xFFD8CDBB);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(metrics.s(18)),
      child: Container(
        padding: EdgeInsets.all(metrics.s(12)),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDDE8D4) : const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(metrics.s(18)),
          border: Border.all(
            color: selected ? const Color(0xFFBFD0B5) : const Color(0xFFE7DCC8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: DudoTextStyles.sans(
                color: titleColor,
                fontSize: metrics.s(13),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: metrics.s(6)),
            Text(
              value,
              style: DudoTextStyles.sans(
                color: valueColor,
                fontSize: metrics.s(12),
              ),
            ),
            const Spacer(),
            Container(
              height: metrics.s(4),
              decoration: BoxDecoration(
                color: sampleColor,
                borderRadius: AppRadius.full,
              ),
            ),
          ],
        ),
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
                    onTap: () {},
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

class _ListeningPanel extends StatelessWidget {
  const _ListeningPanel({
    required this.metrics,
    required this.palette,
    required this.chapterTitle,
    required this.remainingText,
    required this.isListening,
    required this.onListeningChanged,
  });

  final _ReaderOverlayMetrics metrics;
  final ReaderPalette palette;
  final String chapterTitle;
  final String remainingText;
  final bool isListening;
  final ValueChanged<bool> onListeningChanged;

  @override
  Widget build(BuildContext context) {
    final bars = <double>[18, 34, 26, 44, 22, 38, 28, 16, 30];
    return _FloatingPanel(
      key: const ValueKey('reader-listening-panel'),
      metrics: metrics,
      top: 468,
      height: 212,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isListening ? '朗读中' : '朗读',
                      style: DudoTextStyles.serif(
                          color: const Color(0xFF25251F),
                          fontSize: metrics.s(22),
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: metrics.s(4)),
                  Text('$chapterTitle · $remainingText',
                      style: DudoTextStyles.sans(
                          color: const Color(0xFF8A735A),
                          fontSize: metrics.s(12))),
                ],
              ),
              GestureDetector(
                onTap: () => onListeningChanged(!isListening),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: metrics.s(48),
                  height: metrics.s(48),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF25251F),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isListening ? LucideIcons.pause : LucideIcons.play,
                    size: metrics.s(20),
                    color: const Color(0xFFFFF8EA),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.s(14)),
          SizedBox(
            height: metrics.s(54),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  if (i > 0) SizedBox(width: metrics.s(6)),
                  AnimatedContainer(
                    duration: AppMotion.medium,
                    width: metrics.s(8),
                    height: metrics.s(
                      isListening ? bars[i] : (16 + i % 3 * 6).toDouble(),
                    ),
                    decoration: BoxDecoration(
                      color: i == 3
                          ? const Color(0xFF5E6F5B)
                          : const Color(0xFFD8CDBB),
                      borderRadius: AppRadius.full,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: metrics.s(14)),
          SizedBox(
            height: metrics.s(38),
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) SizedBox(width: metrics.s(10)),
                  Expanded(
                    child: _ListeningPill(
                      metrics: metrics,
                      label: const ['0.8x', '1.0x', '1.2x', '定时'][i],
                      selected: i == 1,
                      onTap: () {},
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningPill extends StatelessWidget {
  const _ListeningPill({
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
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDDE8D4) : const Color(0xFFF3ECDD),
          borderRadius: BorderRadius.circular(metrics.s(19)),
        ),
        child: Text(label,
            style: DudoTextStyles.sans(
                color: selected
                    ? const Color(0xFF5E6F5B)
                    : const Color(0xFF8A735A),
                fontSize: metrics.s(13),
                fontWeight: FontWeight.w600)),
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
        fill: const Color(0xFFFFF8EA),
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
    final modes = <_PageTurnModeData>[
      const _PageTurnModeData(
        label: '仿真',
        description: '像纸书一样翻动',
        icon: LucideIcons.bookOpen,
      ),
      const _PageTurnModeData(
        label: '滑动',
        description: '左右滑动切页',
        icon: LucideIcons.moveHorizontal,
      ),
      const _PageTurnModeData(
        label: '滚动',
        description: '连续纵向阅读',
        icon: LucideIcons.scrollText,
      ),
    ];
    return _FloatingPanel(
      key: const ValueKey('reader-page-turn-panel'),
      metrics: metrics,
      top: 428,
      height: 252,
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('翻页方式',
              style: DudoTextStyles.serif(
                  color: const Color(0xFF25251F),
                  fontSize: metrics.s(22),
                  fontWeight: FontWeight.w700)),
          SizedBox(height: metrics.s(12)),
          SizedBox(
            height: metrics.s(118),
            child: Row(
              children: [
                for (var i = 0; i < modes.length; i++) ...[
                  if (i > 0) SizedBox(width: metrics.s(10)),
                  Expanded(
                    child: _PageTurnModeCard(
                      metrics: metrics,
                      data: modes[i],
                      selected: modes[i].label == selectedMode,
                      onTap: () => onModeChanged(modes[i].label),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: metrics.s(12)),
          SizedBox(
            height: metrics.s(34),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('点击区域',
                    style: DudoTextStyles.sans(
                        color: const Color(0xFF25251F),
                        fontSize: metrics.s(14),
                        fontWeight: FontWeight.w600)),
                _TapAreaSegments(
                  metrics: metrics,
                  labels: const ['左右', '上下'],
                  selected: '左右',
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTurnModeData {
  const _PageTurnModeData({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}

class _PageTurnModeCard extends StatelessWidget {
  const _PageTurnModeCard({
    required this.metrics,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _ReaderOverlayMetrics metrics;
  final _PageTurnModeData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFDDE8D4) : const Color(0xFFFFFBF2);
    final borderColor =
        selected ? const Color(0xFF5E6F5B) : const Color(0xFFE7DCC8);
    final iconColor =
        selected ? const Color(0xFF5E6F5B) : const Color(0xFF8A735A);
    final labelColor =
        selected ? const Color(0xFF1B2918) : const Color(0xFF25251F);
    final descColor =
        selected ? const Color(0xFF5E6F5B) : const Color(0xFF8A735A);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(metrics.s(10)),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(metrics.s(20)),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, size: metrics.s(20), color: iconColor),
            SizedBox(height: metrics.s(8)),
            Text(data.label,
                style: DudoTextStyles.sans(
                    color: labelColor,
                    fontSize: metrics.s(13),
                    fontWeight: FontWeight.w600)),
            SizedBox(height: metrics.s(8)),
            Text(data.description,
                style: DudoTextStyles.sans(
                    color: descColor, fontSize: metrics.s(11), height: 1.25)),
          ],
        ),
      ),
    );
  }
}

class _TapAreaSegments extends StatelessWidget {
  const _TapAreaSegments({
    required this.metrics,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final _ReaderOverlayMetrics metrics;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(metrics.s(4)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECDD),
        borderRadius: BorderRadius.circular(metrics.s(17)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) SizedBox(width: metrics.s(4)),
            GestureDetector(
              onTap: () => onSelected(labels[i]),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: metrics.s(12)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: labels[i] == selected
                      ? const Color(0xFF25251F)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(metrics.s(14)),
                ),
                child: Text(labels[i],
                    style: DudoTextStyles.sans(
                        color: labels[i] == selected
                            ? const Color(0xFFFFF8EA)
                            : const Color(0xFF8A735A),
                        fontSize: metrics.s(12),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
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
        fill: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(metrics.s(26)),
        shadowOffset: Offset(0, metrics.s(12)),
        shadowBlur: metrics.s(34),
        child: Padding(
          padding: EdgeInsets.all(metrics.s(16)),
          child: child,
        ),
      ),
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
      required this.onPressed,
      this.active = false});

  final IconData icon;
  final String label;
  final ReaderPalette palette;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final foreground =
        active ? const Color(0xFF5E6F5B) : const Color(0xFF8A735A);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFDDE8D4) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 17),
            const SizedBox(height: 3),
            Text(label,
                style: DudoTextStyles.sans(
                    color: foreground,
                    fontSize: 9,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
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
    final foreground =
        reversed ? const Color(0xFFFFF8EA) : const Color(0xFF8A735A);
    final background =
        reversed ? const Color(0xFF25251F) : const Color(0xFFF3ECDD);
    final children = [
      Icon(icon, size: 16, color: foreground),
      const SizedBox(width: 6),
      Text(label,
          style: DudoTextStyles.sans(
              color: foreground,
              fontSize: 13,
              fontWeight: reversed ? FontWeight.w600 : FontWeight.normal)),
    ];
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.full,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration:
            BoxDecoration(color: background, borderRadius: AppRadius.full),
        child: Row(children: reversed ? children.reversed.toList() : children),
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
