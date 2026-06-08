import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_content_block.dart';
import 'package:dudo/features/reader_engine/domain/reader_insets.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/domain/reader_turn_mode.dart';
import 'package:dudo/features/reader_engine/domain/reader_viewport_state.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_models.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_line_layout_models.dart';
import 'package:dudo/features/reader_engine/presentation/modes/reader_paged_window.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/reader_line_page_snapshot.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/reader_page_image_renderer.dart';
import 'package:dudo/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderLinePageSnapshotController', () {
    test('captures line-backed pages at device pixel ratio', () async {
      const controller = ReaderLinePageSnapshotController();

      final pair = await controller.capturePair(
        currentPage: _pageLayout(text: '当前页'),
        targetPage: _pageLayout(text: '目标页'),
        palette: _palette,
        devicePixelRatio: 2.5,
      );

      expect(pair, isNotNull);
      expect(pair!.current.width, 300);
      expect(pair.current.height, 400);
      expect(pair.target.width, 300);
      expect(pair.target.height, 400);
      pair.dispose();
    });
  });

  group('ReaderPageImageRenderer', () {
    test('reuses cached page images until evicted', () async {
      final cache = ReaderPageImageCache(maximumEntries: 1);
      final renderer = ReaderPageImageRenderer(cache: cache);

      final first = await renderer.renderPage(
        pageLayout: _pageLayout(text: 'cached page'),
        palette: _palette,
        pixelRatio: 1,
      );
      first.release();

      final second = await renderer.renderPage(
        pageLayout: _pageLayout(text: 'cached page'),
        palette: _palette,
        pixelRatio: 1,
      );
      expect(identical(first.image, second.image), isTrue);
      second.release();

      final other = await renderer.renderPage(
        pageLayout: _pageLayout(text: 'other page', pageIndex: 1),
        palette: _palette,
        pixelRatio: 1,
      );
      other.release();

      final third = await renderer.renderPage(
        pageLayout: _pageLayout(text: 'cached page'),
        palette: _palette,
        pixelRatio: 1,
      );
      expect(identical(first.image, third.image), isFalse);
      third.release();

      cache.dispose();
    });
  });

  group('ReaderPageSliceSnapshotController', () {
    test('captures old page slices through Canvas rasterization', () async {
      const controller = ReaderPageSliceSnapshotController();

      final pair = await controller.capturePair(
        currentPage: _resolvedPage('当前页内容', pageIndex: 0),
        targetPage: _resolvedPage('目标页内容', pageIndex: 1),
        settings: const ReaderSettings(
          paletteId: 'test',
          fontFamily: 'Noto Serif SC',
          fontSize: 18,
          lineHeight: 1.5,
          turnMode: ReaderTurnMode.simulated,
          paragraphSpacing: 8,
          pagePadding: ReaderInsets.all(12),
        ),
        palette: _palette,
        viewportSize: const Size(120, 160),
        devicePixelRatio: 2,
      );

      expect(pair, isNotNull);
      expect(pair!.current.width, 240);
      expect(pair.current.height, 320);
      expect(pair.target.width, 240);
      expect(pair.target.height, 320);
      pair.dispose();
    });

    test('warms current and target page images into cache', () async {
      final cache = ReaderPageImageCache(maximumEntries: 3);
      final controller = ReaderPageSliceSnapshotController(
        lineSnapshotController: ReaderLinePageSnapshotController(
          renderer: ReaderPageImageRenderer(cache: cache),
        ),
      );
      const settings = ReaderSettings(
        paletteId: 'test',
        fontFamily: 'Noto Serif SC',
        fontSize: 18,
        lineHeight: 1.5,
        turnMode: ReaderTurnMode.simulated,
        paragraphSpacing: 8,
        pagePadding: ReaderInsets.all(12),
      );
      final current = _resolvedPage('current page content', pageIndex: 0);
      final target = _resolvedPage('target page content', pageIndex: 1);

      await controller.warmPages(
        pages: [current, target],
        settings: settings,
        palette: _palette,
        viewportSize: const Size(120, 160),
        devicePixelRatio: 1,
      );

      expect(cache.length, 2);

      final pair = await controller.capturePair(
        currentPage: current,
        targetPage: target,
        settings: settings,
        palette: _palette,
        viewportSize: const Size(120, 160),
        devicePixelRatio: 1,
      );

      expect(pair, isNotNull);
      expect(cache.length, 2);
      pair!.dispose();
      cache.dispose();
    });
  });
}

const _palette = ReaderPalette(
  name: 'test',
  background: Color(0xFFF8F4EA),
  foreground: Color(0xFF25251F),
);

ReaderPageLayout _pageLayout({required String text, int pageIndex = 0}) {
  const style = TextStyle(fontSize: 18, decoration: TextDecoration.none);
  final range = ReaderTextRange(
    chapterIndex: 0,
    startOffset: 0,
    endOffset: text.length,
  );
  final line = ReaderLineLayout(
    textRange: range,
    x: 12,
    y: 10,
    width: 80,
    height: 28,
    baseline: 34,
    isFirstLineOfBlock: true,
    isLastLineOfBlock: true,
    isLastLineOfParagraph: true,
    align: ReaderTextAlign.start,
    runs: [
      ReaderTextRunLayout(
        textRange: range,
        text: text,
        x: 12,
        baseline: 34,
        width: 80,
        style: style,
      ),
    ],
  );
  final block = ReaderPageBlockLayout(
    blockId: 'block-1',
    type: ReaderPageBlockType.paragraph,
    chapterIndex: 0,
    textRange: range,
    rect: const Rect.fromLTWH(12, 10, 80, 28),
    style: style,
    lines: [line],
    isFirstFragmentOfBlock: true,
    isLastFragmentOfBlock: true,
  );
  return ReaderPageLayout(
    chapterIndex: 0,
    pageIndex: pageIndex,
    pageRect: const Rect.fromLTWH(0, 0, 120, 160),
    contentRect: const Rect.fromLTWH(12, 10, 96, 140),
    start: const ReaderLocation(bookId: 'book-1', chapterIndex: 0, offset: 0),
    end: ReaderLocation(
      bookId: 'book-1',
      chapterIndex: 0,
      offset: text.length,
    ),
    blocks: [block],
  );
}

ReaderResolvedPage _resolvedPage(String text, {required int pageIndex}) {
  final block = ReaderParagraphBlock(
    blockId: 'paragraph-$pageIndex',
    chapterIndex: 0,
    startOffset: 0,
    endOffset: text.length,
    text: text,
    paragraphIndex: 0,
  );
  final chapter = ReaderChapter(
    id: 'chapter-$pageIndex',
    bookId: 'book-1',
    index: 0,
    title: '第一章',
    rawContent: text,
    normalizedText: text,
    blocks: [block],
  );
  final page = ReaderPageSlice(
    chapterIndex: 0,
    pageIndex: pageIndex,
    start: const ReaderLocation(
      bookId: 'book-1',
      chapterIndex: 0,
      offset: 0,
    ),
    end: ReaderLocation(
      bookId: 'book-1',
      chapterIndex: 0,
      offset: text.length,
    ),
    blocks: [block],
  );
  final layout = ReaderChapterLayout(
    chapterIndex: 0,
    revision: ReaderLayoutRevision(
      contentHash: text.hashCode,
      settingsDigest: 'test',
    ),
    contentHeight: 100,
    blockLayouts: const [],
    pages: [page],
  );
  return ReaderResolvedPage(
    item: ReaderChapterWindowItem(
      chapter: chapter,
      layout: layout,
      status: ReaderChapterLoadStatus.loaded,
    ),
    page: page,
  );
}
