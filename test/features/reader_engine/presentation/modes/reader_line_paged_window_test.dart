import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_content_block.dart';
import 'package:dudo/features/reader_engine/domain/reader_insets.dart';
import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_line_layout_engine.dart';
import 'package:dudo/features/reader_engine/presentation/modes/reader_line_paged_window.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderLinePagedWindow', () {
    test('resolves current previous and next line-backed pages', () async {
      const engine = FlutterReaderLineLayoutEngine();
      final chapter = _chapter(
        index: 0,
        text: '这是一个很长的段落，用来生成多个页面，并验证行级窗口可以找到当前页、上一页和下一页。',
      );
      final layout = await engine.layoutChapter(
        chapter: chapter,
        settings: _settings(),
        viewportSize: const Size(150, 105),
      );

      final window = ReaderLinePagedWindow.fromLayouts(
        center: ReaderLineChapterWindowItem(
          chapter: chapter,
          layout: layout,
        ),
        location: layout.pages[1].start,
      );

      expect(window.current.pageIndex, 1);
      expect(window.previous?.pageIndex, 0);
      expect(window.next, isNotNull);
    });

    test('uses adjacent chapter pages at boundaries', () async {
      const engine = FlutterReaderLineLayoutEngine();
      final previousChapter = _chapter(index: 0, text: '上一章正文。');
      final currentChapter = _chapter(index: 1, text: '当前章正文。');
      final settings = _settings();
      final previousLayout = await engine.layoutChapter(
        chapter: previousChapter,
        settings: settings,
        viewportSize: const Size(180, 140),
      );
      final currentLayout = await engine.layoutChapter(
        chapter: currentChapter,
        settings: settings,
        viewportSize: const Size(180, 140),
      );

      final window = ReaderLinePagedWindow.fromLayouts(
        center: ReaderLineChapterWindowItem(
          chapter: currentChapter,
          layout: currentLayout,
        ),
        previousChapter: ReaderLineChapterWindowItem(
          chapter: previousChapter,
          layout: previousLayout,
        ),
        location: currentLayout.pages.first.start,
      );

      expect(window.previous?.chapter.index, 0);
      expect(window.current.chapter.index, 1);
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
  );
}

ReaderChapter _chapter({
  required int index,
  required String text,
}) {
  return ReaderChapter(
    id: 'chapter-$index',
    bookId: 'book-1',
    index: index,
    title: '第$index章',
    rawContent: text,
    normalizedText: text,
    blocks: [
      ReaderParagraphBlock(
        blockId: 'paragraph-$index',
        chapterIndex: index,
        startOffset: 0,
        endOffset: text.length,
        text: text,
        paragraphIndex: 0,
      ),
    ],
  );
}
