import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_content_block.dart';
import 'package:dudo/features/reader_engine/domain/reader_insets.dart';
import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_line_layout_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterReaderLineLayoutEngine', () {
    test('lays out chapter into line-backed pages', () async {
      const engine = FlutterReaderLineLayoutEngine();
      final chapter = _chapterWithParagraph(
        '青铜鼎音震动，带着岁月的沧桑感。楚风放下手中的石块，确信这是铜碑无疑。',
      );

      final layout = await engine.layoutChapter(
        chapter: chapter,
        settings: _settings(),
        viewportSize: const Size(140, 120),
      );

      expect(layout.chapterIndex, 0);
      expect(layout.pages.length, greaterThan(1));
      expect(layout.blocks, isNotEmpty);
      expect(layout.pages.first.blocks.first.lines, isNotEmpty);
      expect(layout.pages.first.start.offset, 0);
      expect(layout.pages.last.end.offset, chapter.textLength);
      expect(layout.contentHeight, greaterThan(0));
    });

    test('applies first line indent only to the original first line', () async {
      const engine = FlutterReaderLineLayoutEngine();
      final chapter = _chapterWithParagraph(
        '这是一个很长的段落，用来确保它会跨越多行甚至多页，从而验证首行缩进不会在分页后的段落片段中重复出现。',
      );
      final settings = _settings().copyWith(firstLineIndent: 24);

      final layout = await engine.layoutChapter(
        chapter: chapter,
        settings: settings,
        viewportSize: const Size(150, 105),
      );

      final lines = [
        for (final page in layout.pages)
          for (final line in page.lines) line,
      ];

      expect(lines.length, greaterThan(2));
      expect(lines.first.x, layout.contentRect.left + 24);
      expect(
        lines.skip(1).every((line) => line.x == layout.contentRect.left),
        isTrue,
      );
      expect(
        layout.blocks.where((block) => block.blockId == 'paragraph-0').length,
        greaterThan(1),
      );
      expect(layout.blocks.first.isFirstFragmentOfBlock, isTrue);
      expect(layout.blocks.last.isFirstFragmentOfBlock, isFalse);
    });

    test('returns one empty page for empty chapters', () async {
      const engine = FlutterReaderLineLayoutEngine();

      final layout = await engine.layoutChapter(
        chapter: const ReaderChapter(
          id: 'chapter-0',
          bookId: 'book-1',
          index: 0,
          title: '空章',
          rawContent: '',
          normalizedText: '',
          blocks: [],
        ),
        settings: _settings(),
        viewportSize: const Size(140, 120),
      );

      expect(layout.pages, hasLength(1));
      expect(layout.pages.first.blocks, isEmpty);
      expect(layout.contentHeight, 0);
    });
  });
}

ReaderLayoutSettings _settings() {
  return ReaderLayoutSettings.fromReaderSettings(
    ReaderSettings.defaults().copyWith(
      fontSize: 18,
      lineHeight: 1.5,
      paragraphSpacing: 12,
      pagePadding: const ReaderInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    firstLineIndent: 36,
  );
}

ReaderChapter _chapterWithParagraph(String text) {
  return ReaderChapter(
    id: 'chapter-0',
    bookId: 'book-1',
    index: 0,
    title: '第一章',
    rawContent: text,
    normalizedText: text,
    blocks: [
      ReaderParagraphBlock(
        blockId: 'paragraph-0',
        chapterIndex: 0,
        startOffset: 0,
        endOffset: text.length,
        text: text,
        paragraphIndex: 0,
      ),
    ],
  );
}
