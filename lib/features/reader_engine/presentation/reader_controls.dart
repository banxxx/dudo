import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../domain/reader_catalog_item.dart';
import '../domain/reader_overlay_mode.dart';
import '../domain/reader_settings.dart';
import '../domain/reader_turn_mode.dart';
import '../../../shared/theme/app_fonts.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_tokens.dart';
import 'layout/reader_chrome_layout.dart';

part 'controls/shared/reader_overlay_metrics.dart';
part 'controls/shared/glass_surface.dart';
part 'controls/shared/floating_panel.dart';
part 'controls/shared/segment_tabs.dart';
part 'controls/shared/icon_tap_area.dart';
part 'controls/top_bar/reader_top_controls.dart';
part 'controls/bottom_bar/reader_bottom_controls.dart';
part 'controls/bottom_bar/tool_button.dart';
part 'controls/catalog/catalog_bottom_sheet.dart';
part 'controls/typography/typography_panel.dart';
part 'controls/theme/theme_panel.dart';
part 'controls/listening/listening_panel.dart';
part 'controls/more/more_menu_popover.dart';
part 'controls/more/menu_item.dart';
part 'controls/page_turn/page_turn_panel.dart';

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
    required this.volumePageTurnEnabled,
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
    required this.onVolumePageTurnChanged,
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
  final ReaderTurnMode pageTurnMode;
  final bool volumePageTurnEnabled;
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
  final ValueChanged<ReaderTurnMode> onPageTurnModeChanged;
  final ValueChanged<bool> onVolumePageTurnChanged;
  final ValueChanged<bool> onListeningChanged;

  bool get _showsBars => mode != ReaderOverlayMode.hidden;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _ReaderOverlayMetrics.fromLayout(
            ReaderChromeLayout.fromSize(
              constraints.biggest,
              MediaQuery.paddingOf(context),
            ),
          );
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
                  onClose: () => onModeChanged(ReaderOverlayMode.hidden),
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
                  volumePageTurnEnabled: volumePageTurnEnabled,
                  onModeChanged: onPageTurnModeChanged,
                  onVolumePageTurnChanged: onVolumePageTurnChanged,
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
