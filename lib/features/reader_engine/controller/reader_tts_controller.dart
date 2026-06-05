import '../domain/reader_chapter.dart';
import '../domain/reader_content_block.dart';
import '../domain/reader_location.dart';
import '../domain/reader_range.dart';

class ReaderTtsSegment {
  const ReaderTtsSegment({
    required this.id,
    required this.range,
    required this.text,
    required this.paragraphIndex,
    this.sentenceIndex,
  });

  final String id;
  final ReaderRange range;
  final String text;
  final int paragraphIndex;
  final int? sentenceIndex;
}

abstract interface class ReaderSentenceSegmenter {
  List<ReaderTtsSegment> segment(ReaderContentBlock block);
}

class ReaderTtsController {
  const ReaderTtsController();

  List<ReaderTtsSegment> buildChapterSegments(ReaderChapter chapter) {
    final segments = <ReaderTtsSegment>[];
    for (final block in chapter.blocks) {
      if (block case ReaderParagraphBlock(:final text, :final paragraphIndex)) {
        segments.add(
          ReaderTtsSegment(
            id: block.blockId,
            range: ReaderRange(
              start: ReaderLocation(
                bookId: chapter.bookId,
                chapterIndex: chapter.index,
                offset: block.startOffset,
                blockId: block.blockId,
              ),
              end: ReaderLocation(
                bookId: chapter.bookId,
                chapterIndex: chapter.index,
                offset: block.endOffset,
                blockId: block.blockId,
              ),
            ),
            text: text,
            paragraphIndex: paragraphIndex,
          ),
        );
      }
    }
    return segments;
  }
}
