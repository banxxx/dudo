import 'dart:ui';

import '../data/reader_document_source.dart';
import '../domain/reader_chapter.dart';
import '../domain/reader_location.dart';
import '../domain/reader_settings.dart';
import '../domain/reader_viewport_state.dart';
import '../layout/reader_layout_cache.dart';
import '../layout/reader_layout_engine.dart';
import '../layout/reader_layout_models.dart';
import 'reader_navigation_controller.dart';

class ReaderViewportController {
  const ReaderViewportController({
    required this.source,
    required this.layoutEngine,
    this.layoutCache,
  });

  final ReaderDocumentSource source;
  final ReaderLayoutEngine layoutEngine;
  final ReaderLayoutCache? layoutCache;

  Future<ReaderViewportState> loadAtLocation({
    required ReaderLocation location,
    required ReaderSettings settings,
    required Size viewportSize,
    required int chapterCount,
    required ReaderNavigationCause cause,
    bool preloadAdjacent = true,
  }) async {
    final chapter = await source.loadChapter(
      bookId: location.bookId,
      chapterIndex: location.chapterIndex,
    );
    final clampedLocation = location.clamp(
      chapterCount: chapterCount,
      maxOffset: chapter.textLength,
    );
    final layout = await _layoutChapter(
      chapter: chapter,
      settings: settings,
      viewportSize: viewportSize,
    );
    final center = ReaderChapterWindowItem(
      chapter: chapter,
      layout: layout,
      status: ReaderChapterLoadStatus.loaded,
    );

    ReaderChapterWindowItem? previous;
    ReaderChapterWindowItem? next;
    if (preloadAdjacent) {
      previous = await _tryLoadAdjacent(
        bookId: location.bookId,
        chapterIndex: location.chapterIndex - 1,
        chapterCount: chapterCount,
        settings: settings,
        viewportSize: viewportSize,
      );
      next = await _tryLoadAdjacent(
        bookId: location.bookId,
        chapterIndex: location.chapterIndex + 1,
        chapterCount: chapterCount,
        settings: settings,
        viewportSize: viewportSize,
      );
    }

    return ReaderViewportState(
      center: center,
      currentLocation: clampedLocation,
      currentLayout: layout,
      previous: previous,
      next: next,
      isProgrammaticChange: cause != ReaderNavigationCause.scrollBoundary,
    );
  }

  Future<ReaderAdjacentChapters> loadAdjacent({
    required String bookId,
    required int chapterIndex,
    required int chapterCount,
    required ReaderSettings settings,
    required Size viewportSize,
  }) async {
    final previous = await _tryLoadAdjacent(
      bookId: bookId,
      chapterIndex: chapterIndex - 1,
      chapterCount: chapterCount,
      settings: settings,
      viewportSize: viewportSize,
    );
    final next = await _tryLoadAdjacent(
      bookId: bookId,
      chapterIndex: chapterIndex + 1,
      chapterCount: chapterCount,
      settings: settings,
      viewportSize: viewportSize,
    );
    return ReaderAdjacentChapters(previous: previous, next: next);
  }

  Future<ReaderChapterWindowItem?> _tryLoadAdjacent({
    required String bookId,
    required int chapterIndex,
    required int chapterCount,
    required ReaderSettings settings,
    required Size viewportSize,
  }) async {
    if (chapterIndex < 0 || chapterIndex >= chapterCount) return null;
    try {
      final chapter = await source.loadChapter(
        bookId: bookId,
        chapterIndex: chapterIndex,
      );
      final layout = await _layoutChapter(
        chapter: chapter,
        settings: settings,
        viewportSize: viewportSize,
      );
      return ReaderChapterWindowItem(
        chapter: chapter,
        layout: layout,
        status: ReaderChapterLoadStatus.loaded,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ReaderChapterLayout> _layoutChapter({
    required ReaderChapter chapter,
    required ReaderSettings settings,
    required Size viewportSize,
  }) async {
    final cache = layoutCache;
    if (cache == null) {
      return layoutEngine.layoutChapter(
        chapter: chapter,
        settings: settings,
        viewportSize: viewportSize,
      );
    }

    final key = ReaderLayoutCacheKey.fromSettings(
      bookId: chapter.bookId,
      chapterIndex: chapter.index,
      contentHash: chapter.normalizedText.hashCode,
      viewportWidth: viewportSize.width,
      viewportHeight: viewportSize.height,
      settings: settings,
    );
    final cached = cache.get(key);
    if (cached != null) return cached;

    final layout = await layoutEngine.layoutChapter(
      chapter: chapter,
      settings: settings,
      viewportSize: viewportSize,
    );
    cache.put(key, layout);
    return layout;
  }
}

class ReaderAdjacentChapters {
  const ReaderAdjacentChapters({
    this.previous,
    this.next,
  });

  final ReaderChapterWindowItem? previous;
  final ReaderChapterWindowItem? next;
}
