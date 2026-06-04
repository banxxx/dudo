class ReaderParagraphSpan {
  const ReaderParagraphSpan({
    required this.index,
    required this.text,
    required this.startOffset,
    required this.endOffset,
  });

  final int index;
  final String text;
  final int startOffset;
  final int endOffset;

  int get length => endOffset - startOffset;
}
