import 'dart:ui';

import '../data/reader_document_source.dart';
import '../domain/reader_location.dart';
import '../domain/reader_settings.dart';
import '../domain/reader_viewport_state.dart';
import '../layout/reader_layout_engine.dart';
import 'reader_navigation_controller.dart';

class ReaderViewportController {
  const ReaderViewportController({
    required this.source,
    required this.layoutEngine,
  });

  final ReaderDocumentSource source;
  final ReaderLayoutEngine layoutEngine;

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
    final layout = await layoutEngine.layoutChapter(
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
      final layout = await layoutEngine.layoutChapter(
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
}
