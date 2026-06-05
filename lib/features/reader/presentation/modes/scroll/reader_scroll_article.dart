import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_fonts.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../domain/reader_chapter_view.dart';
import '../../layout/reader_page_metrics.dart';
import '../../layout/reader_scroll_position_mapper.dart';

class ReaderScrollArticle extends StatelessWidget {
  const ReaderScrollArticle({
    super.key,
    required this.metrics,
    required this.palette,
    required this.chapter,
    required this.fontSize,
    required this.lineHeight,
    required this.top,
    required this.height,
    required this.paragraphLayoutRanges,
    required this.scrollController,
    required this.interactive,
    required this.preview,
    required this.onScrollNotification,
    required this.onTap,
  });

  final ReaderPageMetrics metrics;
  final ReaderPalette palette;
  final ReaderChapterView chapter;
  final double fontSize;
  final double lineHeight;
  final double top;
  final double height;
  final List<ReaderParagraphLayoutRange> paragraphLayoutRanges;
  final ScrollController scrollController;
  final bool interactive;
  final bool preview;
  final bool Function(ScrollNotification notification, int readPosition)
      onScrollNotification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = DudoTextStyles.serif(
      color: palette.foreground,
      fontSize: metrics.s(fontSize),
      height: lineHeight,
      letterSpacing: 0.4,
    );

    return Positioned(
      key: const ValueKey('reader-scroll-article'),
      left: metrics.x(30),
      top: top,
      width: metrics.s(330),
      height: height,
      child: IgnorePointer(
        ignoring: !interactive,
        child: Opacity(
          opacity: preview ? 0.42 : 1,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final readPosition =
                  ReaderScrollPositionMapper.readPositionForScrollOffset(
                ranges: paragraphLayoutRanges,
                scrollOffset: notification.metrics.pixels,
              );
              return onScrollNotification(notification, readPosition);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              child: ListView.builder(
                key: const ValueKey('reader-scroll-view'),
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: metrics.s(32)),
                itemCount: chapter.paragraphSpans.length,
                itemBuilder: (context, index) {
                  final span = chapter.paragraphSpans[index];
                  return Padding(
                    key: ValueKey('reader-paragraph-$index'),
                    padding: EdgeInsets.only(
                      bottom: index + 1 == chapter.paragraphSpans.length
                          ? 0
                          : metrics.s(fontSize * lineHeight),
                    ),
                    child: Text(span.text, style: style),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
