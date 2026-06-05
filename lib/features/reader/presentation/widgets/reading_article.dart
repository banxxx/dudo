import 'package:flutter/material.dart';

import '../../../../shared/theme/app_fonts.dart';
import '../../../../shared/theme/app_theme.dart';
import '../layout/reader_page_layout.dart';
import '../layout/reader_page_metrics.dart';

class ReadingArticle extends StatelessWidget {
  const ReadingArticle({
    super.key,
    required this.metrics,
    required this.palette,
    required this.fontSize,
    required this.lineHeight,
    required this.top,
    required this.height,
    required this.pageIndex,
    required this.pages,
    required this.interactive,
    required this.preview,
  });

  final ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final double fontSize;
  final double lineHeight;
  final double top;
  final double height;
  final int pageIndex;
  final List<ReaderPageSlice> pages;
  final bool interactive;
  final bool preview;

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
          child: ClipRect(
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
