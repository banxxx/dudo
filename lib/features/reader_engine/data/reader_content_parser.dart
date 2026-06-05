import '../domain/reader_content_block.dart';

String normalizeReaderEngineText(String content, {String? title}) {
  return readerEngineParagraphsForChapter(
    title: title,
    content: content,
  ).join('\n\n');
}

List<String> splitReaderEngineParagraphs(String content) {
  return content
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map((paragraph) => paragraph.trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList();
}

List<String> readerEngineParagraphsForChapter({
  required String? title,
  required String content,
}) {
  return withoutDuplicateReaderEngineTitleParagraph(
    title: title,
    paragraphs: splitReaderEngineParagraphs(content),
  );
}

List<String> withoutDuplicateReaderEngineTitleParagraph({
  required String? title,
  required List<String> paragraphs,
}) {
  if (title == null || paragraphs.isEmpty) return paragraphs;
  final normalizedTitle = _normalizedTitleForCompare(title);
  if (normalizedTitle.isEmpty) return paragraphs;
  final normalizedFirst = _normalizedTitleForCompare(paragraphs.first);
  final duplicated = normalizedFirst == normalizedTitle ||
      (normalizedFirst.startsWith(normalizedTitle) &&
          normalizedFirst.length <= normalizedTitle.length + 4);
  return duplicated ? paragraphs.skip(1).toList(growable: false) : paragraphs;
}

List<ReaderContentBlock> buildReaderContentBlocks({
  required int chapterIndex,
  required String title,
  required String content,
}) {
  final paragraphs = readerEngineParagraphsForChapter(
    title: title,
    content: content,
  );
  final blocks = <ReaderContentBlock>[
    ReaderHeadingBlock(
      blockId: 'c$chapterIndex-heading',
      chapterIndex: chapterIndex,
      startOffset: 0,
      endOffset: 0,
      text: title,
    ),
  ];

  var offset = 0;
  for (var i = 0; i < paragraphs.length; i++) {
    final paragraph = paragraphs[i];
    final startOffset = offset;
    final endOffset = startOffset + paragraph.length;
    blocks.add(
      ReaderParagraphBlock(
        blockId: 'c$chapterIndex-p$i',
        chapterIndex: chapterIndex,
        startOffset: startOffset,
        endOffset: endOffset,
        text: paragraph,
        paragraphIndex: i,
      ),
    );
    offset = endOffset;
    if (i + 1 < paragraphs.length) offset += 2;
  }

  return blocks;
}

String _normalizedTitleForCompare(String value) {
  return value.trim().replaceAll(RegExp(r'[\s　:：。！？?.]+'), '').toLowerCase();
}
