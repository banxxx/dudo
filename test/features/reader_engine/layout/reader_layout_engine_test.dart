import 'package:dudo/features/reader_engine/data/reader_content_parser.dart';
import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_insets.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_cache.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_engine.dart';
import 'package:dudo/features/reader_engine/layout/reader_position_mapper.dart';
import 'package:dudo/features/reader_engine/layout/reader_text_measure.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlutterReaderLayoutEngine', () {
    test('builds scroll block layouts and page slices from chapter blocks',
        () async {
      const engine = FlutterReaderLayoutEngine(
        textMeasure: _FixedTextMeasure(height: 20),
      );
      final chapter = _chapterWithContent('A\nBCD\nEFGH\nIJKL');

      final layout = await engine.layoutChapter(
        chapter: chapter,
        settings: _settings(),
        viewportSize: const Size(320, 80),
      );

      expect(layout.chapterIndex, 0);
      expect(layout.blockLayouts, hasLength(chapter.blocks.length));
      expect(layout.contentHeight, greaterThan(0));
      expect(layout.pages.length, greaterThan(1));
      expect(layout.pages.first.start.offset, 0);
      expect(layout.pages.last.end.offset, chapter.textLength);
    });

    test('maps scroll offsets, locations and pages through one layout',
        () async {
      const engine = FlutterReaderLayoutEngine(
        textMeasure: _FixedTextMeasure(height: 20),
      );
      final chapter = _chapterWithContent('A\nBCD\nEFGH\nIJKL');
      final layout = await engine.layoutChapter(
        chapter: chapter,
        settings: _settings(),
        viewportSize: const Size(320, 80),
      );

      final location = ReaderPositionMapper.locationForScrollOffset(
        bookId: 'book-1',
        layout: layout,
        scrollOffset: layout.blockLayouts[2].scrollStart + 1,
      );
      expect(location.offset, greaterThanOrEqualTo(3));

      final scrollOffset = ReaderPositionMapper.scrollOffsetForLocation(
        layout: layout,
        location: const ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 0,
          offset: 8,
        ),
      );
      expect(scrollOffset, greaterThan(0));

      final pageIndex = ReaderPositionMapper.pageIndexForLocation(
        layout: layout,
        location: const ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 0,
          offset: 8,
        ),
      );
      expect(pageIndex, greaterThanOrEqualTo(0));
    });

    test('does not overpack page slices after a short page', () async {
      const engine = FlutterReaderLayoutEngine(
        textMeasure: _FixedTextMeasure(height: 20),
      );
      final chapter = _chapterWithContent('A\nB\nC\nD\nE\nF\nG');
      final layout = await engine.layoutChapter(
        chapter: chapter,
        settings: _settings(),
        viewportSize: const Size(320, 80),
      );

      expect(layout.pages.length, greaterThan(2));
      expect(
        layout.pages.every((page) => page.blocks.length <= 2),
        isTrue,
      );
    });
  });

  group('ReaderLayoutCache', () {
    test('uses content, viewport and setting dimensions as cache identity',
        () async {
      final settings = _settings();
      final key = ReaderLayoutCacheKey.fromSettings(
        bookId: 'book-1',
        chapterIndex: 0,
        contentHash: 1,
        viewportWidth: 320,
        viewportHeight: 640,
        settings: settings,
      );
      final changedFontKey = ReaderLayoutCacheKey.fromSettings(
        bookId: 'book-1',
        chapterIndex: 0,
        contentHash: 1,
        viewportWidth: 320,
        viewportHeight: 640,
        settings: settings.copyWith(fontSize: 22),
      );
      final cache = ReaderLayoutCache(maximumEntries: 1);
      final layout = await const FlutterReaderLayoutEngine(
        textMeasure: _FixedTextMeasure(height: 20),
      ).layoutChapter(
        chapter: _chapterWithContent('A'),
        settings: settings,
        viewportSize: const Size(320, 640),
      );

      cache.put(key, layout);

      expect(cache.get(key), same(layout));
      expect(cache.get(changedFontKey), isNull);
    });
  });
}

ReaderChapter _chapterWithContent(String content) {
  return ReaderChapter(
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
}

ReaderSettings _settings() {
  return ReaderSettings.defaults().copyWith(
    pagePadding: const ReaderInsets.all(0),
    paragraphSpacing: 10,
  );
}

class _FixedTextMeasure implements ReaderTextMeasure {
  const _FixedTextMeasure({required this.height});

  final double height;

  @override
  double measureHeight({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    return height;
  }
}
