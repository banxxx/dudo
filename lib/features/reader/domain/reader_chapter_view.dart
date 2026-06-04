import '../../../core/database/app_database.dart';
import 'reader_catalog_item.dart';
import 'reader_text_normalizer.dart';

class ReaderChapterView {
  const ReaderChapterView({
    required this.bookTitle,
    required this.chapterLabel,
    required this.chapterTitle,
    required this.remainingText,
    required this.chapterOrdinal,
    required this.text,
    required this.paragraphs,
    required this.currentChapterIndex,
    required this.chapterCount,
    required this.previousChapterIndex,
    required this.nextChapterIndex,
    required this.catalogItems,
    required this.contentMissing,
  });

  final String bookTitle;
  final String chapterLabel;
  final String chapterTitle;
  final String remainingText;
  final int chapterOrdinal;
  final String text;
  final List<String> paragraphs;
  final int currentChapterIndex;
  final int chapterCount;
  final int? previousChapterIndex;
  final int? nextChapterIndex;
  final List<ReaderCatalogItem> catalogItems;
  final bool contentMissing;

  bool get hasPrevious => previousChapterIndex != null;
  bool get hasNext => nextChapterIndex != null;

  double chapterProgressForPosition(int readPosition) {
    if (text.isEmpty) return 0.0;
    return (readPosition.clamp(0, text.length).toDouble() / text.length)
        .clamp(0, 1)
        .toDouble();
  }

  double bookProgressForPosition(int readPosition) {
    final chapterProgress = chapterProgressForPosition(readPosition);
    return ((chapterOrdinal + chapterProgress) / chapterCount)
        .clamp(0, 1)
        .toDouble();
  }

  factory ReaderChapterView.fromBook({
    required Book book,
    required List<Chapter> chapters,
    required int requestedChapterIndex,
  }) {
    final clampedPosition = requestedChapterIndex.clamp(0, chapters.length - 1);
    final exactIndex = chapters.indexWhere(
      (chapter) => chapter.chapterIndex == requestedChapterIndex,
    );
    final position = exactIndex >= 0 ? exactIndex : clampedPosition;
    final chapter = chapters[position];
    final rawContent = chapter.content ?? '';
    final text = normalizeReaderText(rawContent);
    final paragraphs = splitReaderParagraphs(rawContent);
    final isSingleLocalChapter = book.localPath != null && chapters.length == 1;
    final chapterLabel = isSingleLocalChapter ? '全文' : chapter.title;

    return ReaderChapterView(
      bookTitle: book.title,
      chapterLabel: chapterLabel,
      chapterTitle: chapter.title,
      remainingText: _estimateReadingTimeText(text),
      chapterOrdinal: position,
      text: text,
      paragraphs: paragraphs,
      currentChapterIndex: chapter.chapterIndex,
      chapterCount: chapters.length,
      previousChapterIndex:
          position > 0 ? chapters[position - 1].chapterIndex : null,
      nextChapterIndex: position + 1 < chapters.length
          ? chapters[position + 1].chapterIndex
          : null,
      catalogItems: [
        for (var i = 0; i < chapters.length; i++)
          ReaderCatalogItem(
            chapterIndex: chapters[i].chapterIndex,
            title: chapters[i].title,
            subtitle: i == position ? '正在阅读' : '已缓存',
          ),
      ],
      contentMissing: text.isEmpty,
    );
  }
}

String _estimateReadingTimeText(String content) {
  final readableLength = content.replaceAll(RegExp(r'\s+'), '').length;
  if (readableLength == 0) return '暂无进度';
  final minutes = (readableLength / 450).ceil().clamp(1, 9999);
  return '约 $minutes 分钟';
}
