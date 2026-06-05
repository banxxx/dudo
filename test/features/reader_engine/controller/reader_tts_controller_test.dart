import 'package:dudo/features/reader_engine/controller/reader_tts_controller.dart';
import 'package:dudo/features/reader_engine/data/reader_content_parser.dart';
import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReaderTtsController builds paragraph segments with reader ranges', () {
    const content = '第一段\n第二段';
    final chapter = ReaderChapter(
      id: 'chapter-1',
      bookId: 'book-1',
      index: 0,
      title: '第一章',
      rawContent: content,
      normalizedText: normalizeReaderEngineText(content),
      blocks: buildReaderContentBlocks(
        chapterIndex: 0,
        title: '第一章',
        content: content,
      ),
    );

    final segments = const ReaderTtsController().buildChapterSegments(chapter);

    expect(segments, hasLength(2));
    expect(segments.first.text, '第一段');
    expect(segments.first.range.start.offset, 0);
    expect(segments.first.range.end.offset, 3);
    expect(segments.last.text, '第二段');
    expect(segments.last.range.start.offset, 5);
    expect(segments.last.range.end.offset, 8);
  });
}
