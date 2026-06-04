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

int normalizedReaderTextLength(String content) {
  return normalizeReaderText(content).length;
}
