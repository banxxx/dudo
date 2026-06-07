import 'dart:async';

import 'package:dudo/features/reader_engine/application/reader_engine_state.dart';
import 'package:dudo/features/reader_engine/controller/reader_navigation_controller.dart';
import 'package:dudo/features/reader_engine/controller/reader_session_controller.dart';
import 'package:dudo/features/reader_engine/controller/reader_viewport_controller.dart';
import 'package:dudo/features/reader_engine/data/reader_content_parser.dart';
import 'package:dudo/features/reader_engine/data/reader_document_source.dart';
import 'package:dudo/features/reader_engine/data/reader_progress_repository.dart';
import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_document.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/domain/reader_source_type.dart';
import 'package:dudo/features/reader_engine/domain/reader_viewport_state.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_cache.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_engine.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_models.dart';
import 'package:dudo/features/reader_engine/layout/reader_text_measure.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderSessionController', () {
    test('catalog jump switches center chapter directly and saves progress',
        () async {
      final source = _FakeReaderDocumentSource(chapterCount: 4);
      final progress = _MemoryProgressRepository();
      final controller = _sessionController(source: source, progress: progress);

      await controller.initialize();
      controller.state = controller.state.copyWith(
        overlay: const ReaderOverlayState(controlsVisible: true),
      );
      await controller.jumpToChapter(2);

      expect(controller.state.loadStatus, ReaderLoadStatus.ready);
      expect(controller.state.location!.chapterIndex, 2);
      expect(controller.state.location!.offset, 0);
      expect(controller.state.overlay.controlsVisible, isFalse);
      expect(controller.state.viewport!.center.chapter.index, 2);
      expect(controller.state.viewport!.previous!.chapter.index, 1);
      expect(controller.state.viewport!.next!.chapter.index, 3);
      expect(progress.savedLocations.last.chapterIndex, 2);
    });

    test('settings changes relayout current location without saving progress',
        () async {
      final source = _FakeReaderDocumentSource(chapterCount: 3);
      final progress = _MemoryProgressRepository(
        saved: const ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 1,
          offset: 3,
        ),
      );
      final controller = _sessionController(source: source, progress: progress);

      await controller.initialize();
      final saveCount = progress.savedLocations.length;
      await controller.updateSettings(
        controller.state.settings.copyWith(fontSize: 22),
      );

      expect(controller.state.loadStatus, ReaderLoadStatus.ready);
      expect(controller.state.location!.chapterIndex, 1);
      expect(controller.state.location!.offset, 3);
      expect(progress.savedLocations, hasLength(saveCount));
    });

    test('initialize shows center chapter before adjacent warmup completes',
        () async {
      final adjacentGate = Completer<void>();
      final source = _BlockingAdjacentReaderDocumentSource(
        chapterCount: 3,
        blockedChapterIndexes: {0, 2},
        gate: adjacentGate,
      );
      final progress = _MemoryProgressRepository(
        saved: const ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 1,
          offset: 0,
        ),
      );
      late ReaderSessionController controller;
      final warmed = Completer<void>();
      controller = _sessionController(
        source: source,
        progress: progress,
        onStateChanged: () {
          final viewport = controller.state.viewport;
          if (viewport?.previous != null &&
              viewport?.next != null &&
              !warmed.isCompleted) {
            warmed.complete();
          }
        },
      );

      await controller.initialize();

      expect(controller.state.loadStatus, ReaderLoadStatus.ready);
      expect(controller.state.viewport!.center.chapter.index, 1);
      expect(controller.state.viewport!.previous, isNull);
      expect(controller.state.viewport!.next, isNull);

      adjacentGate.complete();
      await warmed.future.timeout(const Duration(seconds: 1));

      expect(controller.state.viewport!.previous!.chapter.index, 0);
      expect(controller.state.viewport!.next!.chapter.index, 2);
    });

    test('scroll boundary switches viewport center chapter and saves progress',
        () async {
      final source = _FakeReaderDocumentSource(chapterCount: 4);
      final progress = _MemoryProgressRepository();
      final controller = _sessionController(source: source, progress: progress);

      await controller.initialize();
      await controller.scrollToLocation(
        const ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 1,
          offset: 3,
        ),
      );

      expect(controller.state.loadStatus, ReaderLoadStatus.ready);
      expect(controller.state.location!.chapterIndex, 1);
      expect(controller.state.location!.offset, 3);
      expect(controller.state.viewport!.center.chapter.index, 1);
      expect(controller.state.viewport!.previous!.chapter.index, 0);
      expect(controller.state.viewport!.next!.chapter.index, 2);
      expect(progress.savedLocations.last.chapterIndex, 1);
      expect(progress.savedLocations.last.offset, 3);
    });

    test('adjacent preload failure does not fail current viewport', () async {
      final source = _FakeReaderDocumentSource(
        chapterCount: 3,
        failingChapterIndexes: {2},
      );
      final viewportController = ReaderViewportController(
        source: source,
        layoutEngine: _layoutEngine(),
      );

      final viewport = await viewportController.loadAtLocation(
        location: const ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 1,
          offset: 0,
        ),
        settings: ReaderSettings.defaults(),
        viewportSize: const Size(320, 640),
        chapterCount: 3,
        cause: ReaderNavigationCause.restoreProgress,
      );

      expect(viewport.center.status, ReaderChapterLoadStatus.loaded);
      expect(viewport.previous, isNotNull);
      expect(viewport.next, isNull);
    });

    test('viewport controller reuses cached chapter layouts', () async {
      final source = _FakeReaderDocumentSource(chapterCount: 1);
      final layoutEngine = _CountingLayoutEngine(_layoutEngine());
      final viewportController = ReaderViewportController(
        source: source,
        layoutEngine: layoutEngine,
        layoutCache: ReaderLayoutCache(),
      );
      const location = ReaderLocation(
        bookId: 'book-1',
        chapterIndex: 0,
        offset: 0,
      );

      final first = await viewportController.loadAtLocation(
        location: location,
        settings: ReaderSettings.defaults(),
        viewportSize: const Size(320, 640),
        chapterCount: 1,
        cause: ReaderNavigationCause.restoreProgress,
        preloadAdjacent: false,
      );
      final second = await viewportController.loadAtLocation(
        location: location,
        settings: ReaderSettings.defaults(),
        viewportSize: const Size(320, 640),
        chapterCount: 1,
        cause: ReaderNavigationCause.restoreProgress,
        preloadAdjacent: false,
      );

      expect(layoutEngine.layoutCalls, 1);
      expect(second.currentLayout, same(first.currentLayout));
    });
  });
}

ReaderSessionController _sessionController({
  required _FakeReaderDocumentSource source,
  required _MemoryProgressRepository progress,
  void Function()? onStateChanged,
}) {
  return ReaderSessionController(
    bookId: 'book-1',
    source: source,
    viewportController: ReaderViewportController(
      source: source,
      layoutEngine: _layoutEngine(),
    ),
    progressRepository: progress,
    initialSettings: ReaderSettings.defaults(),
    viewportSize: const Size(320, 640),
    onStateChanged: onStateChanged,
  );
}

ReaderLayoutEngine _layoutEngine() {
  return const FlutterReaderLayoutEngine(
    textMeasure: _FixedTextMeasure(height: 20),
  );
}

class _FakeReaderDocumentSource implements ReaderDocumentSource {
  _FakeReaderDocumentSource({
    required this.chapterCount,
    this.failingChapterIndexes = const {},
  });

  final int chapterCount;
  final Set<int> failingChapterIndexes;

  @override
  Future<ReaderDocument> loadDocument(String bookId) async {
    return ReaderDocument(
      bookId: bookId,
      title: '测试书',
      sourceType: ReaderSourceType.localTxt,
      chapterCount: chapterCount,
    );
  }

  @override
  Future<ReaderChapterMetaPage> loadChapterMetas({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    return ReaderChapterMetaPage(
      items: [
        for (var i = offset; i < (offset + limit).clamp(0, chapterCount); i++)
          ReaderChapterMeta(
            id: 'chapter-$i',
            bookId: bookId,
            index: i,
            title: '第 $i 章',
            normalizedContentLength: 8,
            isCached: true,
          ),
      ],
      offset: offset,
      limit: limit,
      hasMore: offset + limit < chapterCount,
    );
  }

  @override
  Future<ReaderChapter> loadChapter({
    required String bookId,
    required int chapterIndex,
  }) async {
    if (failingChapterIndexes.contains(chapterIndex)) {
      throw StateError('chapter $chapterIndex failed');
    }
    final content = '第 $chapterIndex 章正文\n第二段';
    return ReaderChapter(
      id: 'chapter-$chapterIndex',
      bookId: bookId,
      index: chapterIndex,
      title: '第 $chapterIndex 章',
      rawContent: content,
      normalizedText: normalizeReaderEngineText(content),
      blocks: buildReaderContentBlocks(
        chapterIndex: chapterIndex,
        title: '第 $chapterIndex 章',
        content: content,
      ),
    );
  }
}

class _BlockingAdjacentReaderDocumentSource extends _FakeReaderDocumentSource {
  _BlockingAdjacentReaderDocumentSource({
    required super.chapterCount,
    required this.blockedChapterIndexes,
    required this.gate,
  });

  final Set<int> blockedChapterIndexes;
  final Completer<void> gate;

  @override
  Future<ReaderChapter> loadChapter({
    required String bookId,
    required int chapterIndex,
  }) async {
    if (blockedChapterIndexes.contains(chapterIndex)) {
      await gate.future;
    }
    return super.loadChapter(bookId: bookId, chapterIndex: chapterIndex);
  }
}

class _MemoryProgressRepository implements ReaderProgressRepository {
  _MemoryProgressRepository({this.saved});

  ReaderLocation? saved;
  final savedLocations = <ReaderLocation>[];

  @override
  Future<ReaderLocation?> loadProgress(String bookId) async => saved;

  @override
  Future<void> saveProgress(ReaderLocation location) async {
    saved = location;
    savedLocations.add(location);
  }
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

class _CountingLayoutEngine implements ReaderLayoutEngine {
  _CountingLayoutEngine(this.delegate);

  final ReaderLayoutEngine delegate;
  int layoutCalls = 0;

  @override
  Future<ReaderChapterLayout> layoutChapter({
    required ReaderChapter chapter,
    required ReaderSettings settings,
    required Size viewportSize,
  }) {
    layoutCalls += 1;
    return delegate.layoutChapter(
      chapter: chapter,
      settings: settings,
      viewportSize: viewportSize,
    );
  }
}
