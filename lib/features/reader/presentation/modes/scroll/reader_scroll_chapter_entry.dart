import '../../../domain/reader_paragraph_span.dart';

class ReaderScrollChapterEntry {
  const ReaderScrollChapterEntry({
    required this.chapterIndex,
    required this.title,
    required this.text,
    required this.paragraphSpans,
  });

  final int chapterIndex;
  final String title;
  final String text;
  final List<ReaderParagraphSpan> paragraphSpans;
}
