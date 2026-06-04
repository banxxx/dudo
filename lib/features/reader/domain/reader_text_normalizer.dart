import 'reader_paragraph_span.dart';

String normalizeReaderText(String content) {
  return splitReaderParagraphs(content).join('\n\n');
}

List<String> splitReaderParagraphs(String content) {
  return content
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map((paragraph) => paragraph.trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList();
}

List<ReaderParagraphSpan> buildReaderParagraphSpans(String content) {
  final paragraphs = splitReaderParagraphs(content);
  final spans = <ReaderParagraphSpan>[];
  var offset = 0;
  for (var i = 0; i < paragraphs.length; i++) {
    final paragraph = paragraphs[i];
    final startOffset = offset;
    final endOffset = startOffset + paragraph.length;
    spans.add(
      ReaderParagraphSpan(
        index: i,
        text: paragraph,
        startOffset: startOffset,
        endOffset: endOffset,
      ),
    );
    offset = endOffset;
    if (i + 1 < paragraphs.length) offset += 2;
  }
  return spans;
}

int normalizedReaderTextLength(String content) {
  return normalizeReaderText(content).length;
}
