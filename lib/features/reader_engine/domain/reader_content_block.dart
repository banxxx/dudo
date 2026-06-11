sealed class ReaderContentBlock {
  const ReaderContentBlock({
    required this.blockId,
    required this.chapterIndex,
    required this.startOffset,
    required this.endOffset,
  });

  final String blockId;
  final int chapterIndex;
  final int startOffset;
  final int endOffset;

  int get length => endOffset - startOffset;
}

class ReaderHeadingBlock extends ReaderContentBlock {
  const ReaderHeadingBlock({
    required super.blockId,
    required super.chapterIndex,
    required super.startOffset,
    required super.endOffset,
    required this.text,
    this.level = 1,
  });

  final String text;
  final int level;
}

class ReaderParagraphBlock extends ReaderContentBlock {
  const ReaderParagraphBlock({
    required super.blockId,
    required super.chapterIndex,
    required super.startOffset,
    required super.endOffset,
    required this.text,
    required this.paragraphIndex,
    this.addBottomSpacing = true,
    this.startsAtParagraphStart = true,
  });

  final String text;
  final int paragraphIndex;
  final bool addBottomSpacing;
  final bool startsAtParagraphStart;
}

class ReaderImageBlock extends ReaderContentBlock {
  const ReaderImageBlock({
    required super.blockId,
    required super.chapterIndex,
    required super.startOffset,
    required super.endOffset,
    required this.source,
    this.alt,
  });

  final Uri source;
  final String? alt;
}
