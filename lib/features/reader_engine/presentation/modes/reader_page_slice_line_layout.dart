import 'package:flutter/painting.dart';

import '../../domain/reader_chapter.dart';
import '../../domain/reader_content_block.dart';
import '../../domain/reader_settings.dart';
import '../../layout/reader_layout_settings.dart';
import '../../layout/reader_line_layout_engine.dart';
import '../../layout/reader_line_layout_models.dart';
import 'reader_paged_window.dart';

class ReaderPageSliceLineLayoutResolver {
  const ReaderPageSliceLineLayoutResolver({
    this.lineLayoutEngine = const FlutterReaderLineLayoutEngine(),
  });

  static const int _maxCachedPages = 32;
  static final Map<String, ReaderPageLayout> _pageCache =
      <String, ReaderPageLayout>{};

  final ReaderLineLayoutEngine lineLayoutEngine;

  String cacheKeyForPage({
    required ReaderResolvedPage resolvedPage,
    required ReaderSettings settings,
    required Size viewportSize,
  }) {
    final page = resolvedPage.page;
    final layoutSettings = ReaderLayoutSettings.fromReaderSettings(settings);
    return [
      resolvedPage.item.chapter.id,
      resolvedPage.item.chapter.index,
      page.pageIndex,
      page.start.offset,
      page.end.offset,
      viewportSize.width,
      viewportSize.height,
      layoutSettings.digest,
      for (final block in page.blocks) ...[
        block.blockId,
        block.startOffset,
        block.endOffset,
        if (block is ReaderParagraphBlock) block.startsAtParagraphStart,
      ],
    ].join('|');
  }

  ReaderPageLayout? cachedPage({
    required ReaderResolvedPage resolvedPage,
    required ReaderSettings settings,
    required Size viewportSize,
  }) {
    return _pageCache[cacheKeyForPage(
      resolvedPage: resolvedPage,
      settings: settings,
      viewportSize: viewportSize,
    )];
  }

  Future<ReaderPageLayout> resolvePage({
    required ReaderResolvedPage resolvedPage,
    required ReaderSettings settings,
    required Size viewportSize,
  }) async {
    final key = cacheKeyForPage(
      resolvedPage: resolvedPage,
      settings: settings,
      viewportSize: viewportSize,
    );
    final cached = _pageCache[key];
    if (cached != null) return cached;

    final pageChapter = _pageChapterFor(resolvedPage);
    final layout = await lineLayoutEngine.layoutChapter(
      chapter: pageChapter,
      settings: ReaderLayoutSettings.fromReaderSettings(settings),
      viewportSize: viewportSize,
    );
    final pageLayout = layout.pages.first;
    _pageCache[key] = pageLayout;
    while (_pageCache.length > _maxCachedPages) {
      _pageCache.remove(_pageCache.keys.first);
    }
    return pageLayout;
  }

  ReaderChapter _pageChapterFor(ReaderResolvedPage resolvedPage) {
    final sourceChapter = resolvedPage.item.chapter;
    final page = resolvedPage.page;
    return ReaderChapter(
      id: '${sourceChapter.id}:page-${page.pageIndex}',
      bookId: sourceChapter.bookId,
      index: sourceChapter.index,
      title: sourceChapter.title,
      rawContent: sourceChapter.rawContent,
      normalizedText: sourceChapter.normalizedText,
      blocks: page.blocks,
      metadata: sourceChapter.metadata,
    );
  }
}
