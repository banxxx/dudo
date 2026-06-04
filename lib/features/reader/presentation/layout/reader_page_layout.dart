import 'package:flutter/material.dart';

import '../../../../shared/theme/app_fonts.dart';
import 'reader_page_metrics.dart';

class ReaderPageSlice {
  const ReaderPageSlice({
    required this.startOffset,
    required this.endOffset,
    required this.text,
  });

  final int startOffset;
  final int endOffset;
  final String text;
}

class ReaderPageLayout {
  static double pageHeight(
    ReaderPageMetrics metrics, {
    double? availableHeight,
  }) =>
      availableHeight ?? metrics.s(642);

  static List<ReaderPageSlice> paginate({
    required String text,
    required ReaderPageMetrics metrics,
    required double fontSize,
    required double lineHeight,
    double? availableHeight,
  }) {
    if (text.isEmpty) {
      return const [ReaderPageSlice(startOffset: 0, endOffset: 0, text: '')];
    }

    final style = DudoTextStyles.serif(
      fontSize: metrics.s(fontSize),
      height: lineHeight,
      letterSpacing: 0.4,
    );
    final width = metrics.s(330);
    final height = pageHeight(metrics, availableHeight: availableHeight);
    final pages = <ReaderPageSlice>[];
    var start = 0;

    while (start < text.length) {
      final end = _findPageEnd(
        text: text,
        start: start,
        width: width,
        height: height,
        style: style,
      );
      final safeEnd = end <= start ? (start + 1).clamp(0, text.length) : end;
      pages.add(
        ReaderPageSlice(
          startOffset: start,
          endOffset: safeEnd,
          text: text.substring(start, safeEnd).trimLeft(),
        ),
      );
      start = safeEnd;
      while (start < text.length && text.codeUnitAt(start) == 10) {
        start++;
      }
    }

    return pages.isEmpty
        ? const [ReaderPageSlice(startOffset: 0, endOffset: 0, text: '')]
        : pages;
  }

  static int pageIndexForPosition({
    required List<ReaderPageSlice> pages,
    required int readPosition,
  }) {
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      if (readPosition >= page.startOffset && readPosition < page.endOffset) {
        return i;
      }
    }
    return pages.length - 1;
  }

  static int _findPageEnd({
    required String text,
    required int start,
    required double width,
    required double height,
    required TextStyle style,
  }) {
    var low = start + 1;
    var high = text.length;
    var best = low;

    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      if (_fits(
        text: text.substring(start, mid),
        width: width,
        height: height,
        style: style,
      )) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (best >= text.length) return text.length;
    return _naturalBreak(text, start, best);
  }

  static bool _fits({
    required String text,
    required double width,
    required double height,
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: width);
    return painter.height <= height;
  }

  static int _naturalBreak(String text, int start, int best) {
    final minimum = start + ((best - start) * 0.72).floor();
    for (var i = best; i > minimum; i--) {
      final char = text[i - 1];
      if (char == '\n' ||
          char == '。' ||
          char == '！' ||
          char == '？' ||
          char == '；' ||
          char == '，' ||
          char == ' ') {
        return i;
      }
    }
    return best;
  }
}
