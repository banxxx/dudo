import '../../../domain/reader_paragraph_span.dart';

sealed class ReaderScrollBlock {
  const ReaderScrollBlock({required this.chapterIndex});

  final int chapterIndex;
}

class ReaderScrollChapterHeader extends ReaderScrollBlock {
  const ReaderScrollChapterHeader({
    required super.chapterIndex,
    required this.title,
  });

  final String title;
}

class ReaderScrollParagraphBlock extends ReaderScrollBlock {
  const ReaderScrollParagraphBlock({
    required super.chapterIndex,
    required this.span,
  });

  final ReaderParagraphSpan span;
}

class ReaderScrollProgress {
  const ReaderScrollProgress({
    required this.chapterIndex,
    required this.readPosition,
    required this.chapterTitle,
    required this.contentLength,
  });

  final int chapterIndex;
  final int readPosition;
  final String chapterTitle;
  final int contentLength;
}
