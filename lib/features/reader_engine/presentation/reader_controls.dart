import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../domain/reader_catalog_item.dart';
import '../domain/reader_overlay_mode.dart';
import '../domain/reader_settings.dart';
import '../domain/reader_turn_mode.dart';
import '../../settings/typography_settings/domain/reader_font.dart';
import '../../../shared/theme/app_fonts.dart';
import '../domain/reader_theme.dart';
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
part 'controls/theme/models/theme_style_option.dart';
part 'controls/theme/models/theme_toggle_row_data.dart';
part 'controls/theme/sections/brightness_eye_group.dart';
part 'controls/theme/sections/theme_style_group.dart';
part 'controls/theme/sections/theme_toggle_group.dart';
part 'controls/theme/theme_panel.dart';
part 'controls/theme/tokens/reader_control_theme.dart';
part 'controls/theme/widgets/reading_background_pill.dart';
part 'controls/theme/widgets/theme_brightness_slider.dart';
part 'controls/theme/widgets/theme_quick_pill.dart';
part 'controls/theme/widgets/theme_section_title.dart';
part 'controls/theme/widgets/theme_static_switch.dart';
part 'controls/theme/widgets/theme_swatch_tile.dart';
part 'controls/theme/widgets/theme_toggle_row.dart';
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
    required this.paragraphSpacing,
    required this.pageHorizontalMargin,
    required this.firstLineIndentEnabled,
    required this.textEnhancementEnabled,
    required this.fontLibraryValue,
    required this.brightness,
    required this.followSystemBrightness,
    required this.eyeComfortEnhanced,
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
    required this.onParagraphSpacingChanged,
    required this.onLineParagraphSpacingChanged,
    required this.onPageHorizontalMarginChanged,
    required this.onFontSelected,
    required this.onManageFonts,
    required this.onFirstLineIndentChanged,
    required this.onTextEnhancementChanged,
    required this.onBrightnessChanged,
    required this.onFollowSystemBrightnessChanged,
    required this.onEyeComfortEnhancedChanged,
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
  final double paragraphSpacing;
  final double pageHorizontalMargin;
  final bool firstLineIndentEnabled;
  final bool textEnhancementEnabled;
  final AsyncValue<ReaderFontLibrary> fontLibraryValue;
  final double brightness;
  final bool followSystemBrightness;
  final bool eyeComfortEnhanced;
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
  final ValueChanged<double> onParagraphSpacingChanged;
  final void Function(double lineHeight, double paragraphSpacing)
      onLineParagraphSpacingChanged;
  final ValueChanged<double> onPageHorizontalMarginChanged;
  final ValueChanged<ReaderFont> onFontSelected;
  final VoidCallback onManageFonts;
  final ValueChanged<bool> onFirstLineIndentChanged;
  final ValueChanged<bool> onTextEnhancementChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<bool> onFollowSystemBrightnessChanged;
  final ValueChanged<bool> onEyeComfortEnhancedChanged;
  final ValueChanged<ReaderTurnMode> onPageTurnModeChanged;
  final ValueChanged<bool> onVolumePageTurnChanged;
  final ValueChanged<bool> onListeningChanged;

  bool get _showsBars => mode != ReaderOverlayMode.hidden;

  @override
  Widget build(BuildContext context) {
    final controlTheme = _ReaderControlTheme.fromPalette(palette);
    return Positioned.fill(
      child: _ReaderControlThemeScope(
        theme: controlTheme,
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
                    child: ColoredBox(color: controlTheme.overlay.barrier),
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
                    onListening: () =>
                        onModeChanged(ReaderOverlayMode.listening),
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
                    paragraphSpacing: paragraphSpacing,
                    pageHorizontalMargin: pageHorizontalMargin,
                    firstLineIndentEnabled: firstLineIndentEnabled,
                    textEnhancementEnabled: textEnhancementEnabled,
                    fontLibraryValue: fontLibraryValue,
                    onFontSizeChanged: onFontSizeChanged,
                    onLineHeightChanged: onLineHeightChanged,
                    onParagraphSpacingChanged: onParagraphSpacingChanged,
                    onLineParagraphSpacingChanged:
                        onLineParagraphSpacingChanged,
                    onPageHorizontalMarginChanged:
                        onPageHorizontalMarginChanged,
                    onFontSelected: onFontSelected,
                    onManageFonts: onManageFonts,
                    onFirstLineIndentChanged: onFirstLineIndentChanged,
                    onTextEnhancementChanged: onTextEnhancementChanged,
                  ),
                );
              case ReaderOverlayMode.theme:
                children.add(
                  _ThemePanel(
                    metrics: metrics,
                    palette: palette,
                    brightness: brightness,
                    followSystemBrightness: followSystemBrightness,
                    eyeComfortEnhanced: eyeComfortEnhanced,
                    onPaletteChanged: onPaletteChanged,
                    onBrightnessChanged: onBrightnessChanged,
                    onFollowSystemBrightnessChanged:
                        onFollowSystemBrightnessChanged,
                    onEyeComfortEnhancedChanged: onEyeComfortEnhancedChanged,
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
      ),
    );
  }
}
