import '../../../../../shared/theme/app_fonts.dart';
import '../../../domain/reader_chapter_view.dart';
import '../../layout/reader_page_metrics.dart';
import '../../layout/reader_scroll_position_mapper.dart';

class ReaderScrollPositionCache {
  ReaderScrollLayoutKey? _key;
  List<ReaderParagraphLayoutRange>? _ranges;

  List<ReaderParagraphLayoutRange> rangesFor({
    required String bookId,
    required ReaderChapterView view,
    required ReaderPageMetrics metrics,
    required double fontSize,
    required double lineHeight,
  }) {
    final contentWidth = metrics.s(330);
    final key = ReaderScrollLayoutKey(
      bookId: bookId,
      chapterIndex: view.currentChapterIndex,
      textLength: view.text.length,
      textHash: view.text.hashCode,
      contentWidth: contentWidth,
      fontSize: fontSize,
      lineHeight: lineHeight,
    );
    final cachedRanges = _ranges;
    if (_key == key && cachedRanges != null) return cachedRanges;

    final style = DudoTextStyles.serif(
      fontSize: metrics.s(fontSize),
      height: lineHeight,
      letterSpacing: 0.4,
    );
    final ranges = ReaderScrollPositionMapper.buildRanges(
      spans: view.paragraphSpans,
      style: style,
      width: contentWidth,
      paragraphSpacing: metrics.s(fontSize * lineHeight),
    );
    _key = key;
    _ranges = ranges;
    return ranges;
  }

  void clear() {
    _key = null;
    _ranges = null;
  }
}

class ReaderScrollLayoutKey {
  const ReaderScrollLayoutKey({
    required this.bookId,
    required this.chapterIndex,
    required this.textLength,
    required this.textHash,
    required this.contentWidth,
    required this.fontSize,
    required this.lineHeight,
  });

  final String bookId;
  final int chapterIndex;
  final int textLength;
  final int textHash;
  final double contentWidth;
  final double fontSize;
  final double lineHeight;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReaderScrollLayoutKey &&
            other.bookId == bookId &&
            other.chapterIndex == chapterIndex &&
            other.textLength == textLength &&
            other.textHash == textHash &&
            other.contentWidth == contentWidth &&
            other.fontSize == fontSize &&
            other.lineHeight == lineHeight;
  }

  @override
  int get hashCode => Object.hash(
        bookId,
        chapterIndex,
        textLength,
        textHash,
        contentWidth,
        fontSize,
        lineHeight,
      );
}
