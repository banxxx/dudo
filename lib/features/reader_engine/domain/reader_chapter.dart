import 'reader_content_block.dart';

class ReaderChapter {
  const ReaderChapter({
    required this.id,
    required this.bookId,
    required this.index,
    required this.title,
    required this.rawContent,
    required this.normalizedText,
    required this.blocks,
    this.metadata = const {},
  });

  final String id;
  final String bookId;
  final int index;
  final String title;
  final String rawContent;
  final String normalizedText;
  final List<ReaderContentBlock> blocks;
  final Map<String, Object?> metadata;

  int get textLength => normalizedText.length;
}
