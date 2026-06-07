import 'dart:async';
import 'dart:ui';

import '../application/reader_engine_state.dart';
import '../data/reader_document_source.dart';
import '../data/reader_progress_repository.dart';
import '../domain/reader_location.dart';
import '../domain/reader_settings.dart';
import '../domain/reader_viewport_state.dart';
import 'reader_navigation_controller.dart';
import 'reader_progress_controller.dart';
import 'reader_viewport_controller.dart';

class ReaderSessionController {
  ReaderSessionController({
    required this.bookId,
    required this.source,
    required this.viewportController,
    required ReaderProgressRepository progressRepository,
    required ReaderSettings initialSettings,
    required this.viewportSize,
    this.onStateChanged,
  })  : _progressController = ReaderProgressController(progressRepository),
        state = ReaderSessionState.initial(initialSettings);

  final String bookId;
  final ReaderDocumentSource source;
  final ReaderViewportController viewportController;
  final ReaderProgressController _progressController;
  final Size viewportSize;
  final void Function()? onStateChanged;

  ReaderSessionState state;
  int _loadGeneration = 0;

  Future<void> initialize() async {
    final generation = ++_loadGeneration;
    _updateState(state.copyWith(loadStatus: ReaderLoadStatus.loading));
    try {
      final document = await source.loadDocument(bookId);
      final saved = await _progressController.repository.loadProgress(bookId);
      final location = (saved ??
              ReaderLocation.startOfChapter(
                bookId: bookId,
                chapterIndex: 0,
              ))
          .clamp(chapterCount: document.chapterCount);
      final viewport = await _progressController.runWithoutSaving(
        () => viewportController.loadAtLocation(
          location: location,
          settings: state.settings,
          viewportSize: viewportSize,
          chapterCount: document.chapterCount,
          cause: ReaderNavigationCause.restoreProgress,
          preloadAdjacent: false,
        ),
      );
      if (generation != _loadGeneration) return;
      _updateState(state.copyWith(
        document: document,
        location: viewport.currentLocation,
        viewport: viewport,
        overlay: state.overlay.hideAll(),
        loadStatus: ReaderLoadStatus.ready,
      ));
      unawaited(_warmAdjacentChapters(
        generation: generation,
        documentChapterCount: document.chapterCount,
        centerLocation: viewport.currentLocation,
      ));
    } catch (error) {
      if (generation != _loadGeneration) return;
      _updateState(state.copyWith(
        loadStatus: ReaderLoadStatus.error,
        error: error,
      ));
    }
  }

  Future<void> jumpToChapter(int chapterIndex) async {
    final document = state.document ?? await source.loadDocument(bookId);
    final location = ReaderLocation.startOfChapter(
      bookId: bookId,
      chapterIndex: chapterIndex,
    ).clamp(chapterCount: document.chapterCount);

    await _loadLocation(
      documentChapterCount: document.chapterCount,
      location: location,
      cause: ReaderNavigationCause.catalogJump,
      preloadAdjacent: true,
      saveProgress: true,
    );
  }

  Future<void> goToNextChapter() async {
    final current = state.location;
    final document = state.document;
    if (current == null || document == null) return;
    if (current.chapterIndex + 1 >= document.chapterCount) return;

    await _loadLocation(
      documentChapterCount: document.chapterCount,
      location: ReaderLocation.startOfChapter(
        bookId: bookId,
        chapterIndex: current.chapterIndex + 1,
      ),
      cause: ReaderNavigationCause.nextButton,
      preloadAdjacent: true,
      saveProgress: true,
    );
  }

  Future<void> goToPreviousChapter() async {
    final current = state.location;
    final document = state.document;
    if (current == null || document == null || current.chapterIndex == 0) {
      return;
    }

    await _loadLocation(
      documentChapterCount: document.chapterCount,
      location: ReaderLocation.startOfChapter(
        bookId: bookId,
        chapterIndex: current.chapterIndex - 1,
      ),
      cause: ReaderNavigationCause.previousButton,
      preloadAdjacent: true,
      saveProgress: true,
    );
  }

  Future<void> updateSettings(ReaderSettings settings) async {
    final current = state.location;
    final document = state.document;
    if (current == null || document == null) {
      _updateState(state.copyWith(settings: settings));
      return;
    }

    _updateState(state.copyWith(settings: settings));
    await _loadLocation(
      documentChapterCount: document.chapterCount,
      location: current,
      cause: ReaderNavigationCause.restoreProgress,
      preloadAdjacent: false,
      saveProgress: false,
    );
  }

  Future<void> reportUserLocation(ReaderLocation location) async {
    _updateState(state.copyWith(location: location));
    await _progressController.saveIfAllowed(
      location: location,
      isProgrammaticChange: false,
    );
  }

  Future<void> scrollToLocation(ReaderLocation location) async {
    final document = state.document;
    if (document == null) return;

    final clamped = location.clamp(chapterCount: document.chapterCount);
    await _loadLocation(
      documentChapterCount: document.chapterCount,
      location: clamped,
      cause: ReaderNavigationCause.scrollBoundary,
      preloadAdjacent: true,
      saveProgress: true,
    );
  }

  Future<void> _loadLocation({
    required int documentChapterCount,
    required ReaderLocation location,
    required ReaderNavigationCause cause,
    required bool preloadAdjacent,
    required bool saveProgress,
  }) async {
    final generation = ++_loadGeneration;
    _updateState(state.copyWith(
      loadStatus:
          state.viewport == null ? ReaderLoadStatus.loading : state.loadStatus,
      overlay: state.overlay.hideAll(),
    ));
    try {
      final viewport = await _progressController.runWithoutSaving(
        () => viewportController.loadAtLocation(
          location: location,
          settings: state.settings,
          viewportSize: viewportSize,
          chapterCount: documentChapterCount,
          cause: cause,
          preloadAdjacent: preloadAdjacent,
        ),
      );
      if (generation != _loadGeneration) return;
      _updateState(state.copyWith(
        location: viewport.currentLocation,
        viewport: viewport,
        loadStatus: ReaderLoadStatus.ready,
      ));
      if (saveProgress) {
        await _progressController.saveIfAllowed(
          location: viewport.currentLocation,
          isProgrammaticChange: false,
        );
      }
      if (!preloadAdjacent) {
        unawaited(_warmAdjacentChapters(
          generation: generation,
          documentChapterCount: documentChapterCount,
          centerLocation: viewport.currentLocation,
        ));
      }
    } catch (error) {
      if (generation != _loadGeneration) return;
      _updateState(state.copyWith(
        loadStatus: ReaderLoadStatus.error,
        error: error,
      ));
    }
  }

  Future<void> _warmAdjacentChapters({
    required int generation,
    required int documentChapterCount,
    required ReaderLocation centerLocation,
  }) async {
    final viewport = state.viewport;
    if (viewport == null ||
        viewport.center.chapter.index != centerLocation.chapterIndex) {
      return;
    }

    final adjacent = await viewportController.loadAdjacent(
      bookId: centerLocation.bookId,
      chapterIndex: centerLocation.chapterIndex,
      chapterCount: documentChapterCount,
      settings: state.settings,
      viewportSize: viewportSize,
    );
    if (generation != _loadGeneration) return;

    final currentViewport = state.viewport;
    if (currentViewport == null ||
        currentViewport.center.chapter.index != centerLocation.chapterIndex) {
      return;
    }

    _updateState(state.copyWith(
      viewport: ReaderViewportState(
        center: currentViewport.center,
        currentLocation: currentViewport.currentLocation,
        currentLayout: currentViewport.currentLayout,
        previous: adjacent.previous,
        next: adjacent.next,
        isProgrammaticChange: currentViewport.isProgrammaticChange,
      ),
    ));
  }

  void _updateState(ReaderSessionState nextState) {
    state = nextState;
    onStateChanged?.call();
  }
}
