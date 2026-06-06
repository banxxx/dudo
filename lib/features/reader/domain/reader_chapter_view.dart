import '../../../core/database/app_database.dart';
import 'reader_paragraph_span.dart';
import 'reader_reading_time.dart';
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
    required this.paragraphSpans,
    required this.currentChapterIndex,
    required this.chapterCount,
    required this.previousChapterIndex,
    required this.nextChapterIndex,
    required this.contentMissing,
  });

  final String bookTitle;
  final String chapterLabel;
  final String chapterTitle;
  final String remainingText;
  final int chapterOrdinal;
  final String text;
  final List<String> paragraphs;
  final List<ReaderParagraphSpan> paragraphSpans;
  final int currentChapterIndex;
  final int chapterCount;
  final int? previousChapterIndex;
  final int? nextChapterIndex;
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

  factory ReaderChapterView.fromChapter({
    required Book book,
    required Chapter chapterMeta,
    required Chapter currentChapter,
    required int chapterCount,
  }) {
    final rawContent = currentChapter.content ?? '';
    final text = normalizeReaderText(rawContent);
    final paragraphSpans = buildReaderParagraphSpans(rawContent);
    final paragraphs = [for (final span in paragraphSpans) span.text];
    final isSingleLocalChapter = book.localPath != null && chapterCount == 1;
    final chapterLabel = isSingleLocalChapter ? '全文' : chapterMeta.title;
    final chapterIndex = chapterMeta.chapterIndex;

    return ReaderChapterView(
      bookTitle: book.title,
      chapterLabel: chapterLabel,
      chapterTitle: chapterMeta.title,
      remainingText: estimateReaderReadingTimeText(text),
      chapterOrdinal: chapterIndex.clamp(0, chapterCount - 1),
      text: text,
      paragraphs: paragraphs,
      paragraphSpans: paragraphSpans,
      currentChapterIndex: chapterIndex,
      chapterCount: chapterCount,
      previousChapterIndex: chapterIndex > 0 ? chapterIndex - 1 : null,
      nextChapterIndex:
          chapterIndex + 1 < chapterCount ? chapterIndex + 1 : null,
      contentMissing: text.isEmpty,
    );
  }
}
