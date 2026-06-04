import 'package:flutter/material.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../domain/reader_chapter_view.dart';
import '../layout/reader_page_layout.dart';
import '../layout/reader_page_metrics.dart';

class ReadingArticle extends StatelessWidget {
  const ReadingArticle({
    super.key,
    required this.metrics,
    required this.palette,
    required this.chapter,
    required this.fontSize,
    required this.lineHeight,
    required this.top,
    required this.height,
    required this.pageIndex,
    required this.pages,
    required this.scrollController,
    required this.scrollable,
    required this.interactive,
    required this.preview,
    required this.onScrollPositionChanged,
    required this.onTap,
  });

  final ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final ReaderChapterView chapter;
  final double fontSize;
  final double lineHeight;
  final double top;
  final double height;
  final int pageIndex;
  final List<ReaderPageSlice> pages;
  final ScrollController scrollController;
  final bool scrollable;
  final bool interactive;
  final bool preview;
  final ValueChanged<int> onScrollPositionChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = DudoTextStyles.serif(
      color: palette.foreground,
      fontSize: metrics.s(fontSize),
      height: lineHeight,
      letterSpacing: 0.4,
    );
    final currentPage = pages[pageIndex.clamp(0, pages.length - 1).toInt()];

    return Positioned(
      key: const ValueKey('reader-article'),
      left: metrics.x(30),
      top: top,
      width: metrics.s(330),
      height: height,
      child: IgnorePointer(
        ignoring: !interactive,
        child: Opacity(
          opacity: preview ? 0.42 : 1,
          child: scrollable
              ? NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    final maxScrollExtent =
                        notification.metrics.maxScrollExtent;
                    final ratio = maxScrollExtent <= 0
                        ? 0.0
                        : notification.metrics.pixels / maxScrollExtent;
                    onScrollPositionChanged(
                      (chapter.text.length * ratio.clamp(0.0, 1.0)).round(),
                    );
                    return false;
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onTap,
                    child: SingleChildScrollView(
                      key: const ValueKey('reader-scroll-view'),
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: metrics.s(32)),
                        child: Text(chapter.text, style: style),
                      ),
                    ),
                  ),
                )
              : ClipRect(
                  child: Text(
                    currentPage.text,
                    key: ValueKey('reader-page-text-$pageIndex'),
                    overflow: TextOverflow.clip,
                    style: style,
                  ),
                ),
        ),
      ),
    );
  }
}
