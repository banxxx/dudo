import 'package:dudo/features/reader_engine/application/reader_engine_providers.dart';
import 'package:dudo/features/reader_engine/data/reader_content_parser.dart';
import 'package:dudo/features/reader_engine/data/reader_document_source.dart';
import 'package:dudo/features/reader_engine/data/reader_progress_repository.dart';
import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_document.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_source_type.dart';
import 'package:dudo/features/reader_engine/presentation/reader_screen.dart';
import 'package:dudo/features/reader_engine/presentation/widgets/reader_canvas_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ReaderScreen initializes reader engine UI', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerDocumentSourceProvider.overrideWithValue(
            _FakeReaderDocumentSource(),
          ),
          readerProgressRepositoryProvider.overrideWithValue(
            _MemoryProgressRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ReaderScreen(bookId: 'book-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-engine-screen')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reader-engine-slide-view')), findsOneWidget);
    expect(find.byType(ReaderCanvasPage), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-progress')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-top-controls')), findsNothing);

    await tester.tapAt(const Offset(400, 300));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-top-controls')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reader-bottom-controls')), findsOneWidget);
    expect(find.text('测试书'), findsOneWidget);
    expect(find.text('约 1 分钟'), findsOneWidget);
    expect(find.textContaining('本章'), findsNothing);
  });

  testWidgets('ReaderScreen progress percent shows chapter progress',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerDocumentSourceProvider.overrideWithValue(
            _FakeReaderDocumentSource(),
          ),
          readerProgressRepositoryProvider.overrideWithValue(
            _MemoryProgressRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ReaderScreen(bookId: 'book-1', initialChapterIndex: 1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final progressText = tester.widget<Text>(
      find.byKey(const ValueKey('reader-progress-percent')),
    );
    expect(progressText.data, '0%');
  });

  testWidgets('ReaderScreen keeps controls visible on short phones',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 698);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerDocumentSourceProvider.overrideWithValue(
            _FakeReaderDocumentSource(),
          ),
          readerProgressRepositoryProvider.overrideWithValue(
            _MemoryProgressRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ReaderScreen(bookId: 'book-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 300));
    await tester.pumpAndSettle();

    final topRect = tester.getRect(
      find.byKey(const ValueKey('reader-top-controls')),
    );
    final bottomRect = tester.getRect(
      find.byKey(const ValueKey('reader-bottom-controls')),
    );

    expect(topRect.top, greaterThanOrEqualTo(0));
    expect(topRect.bottom, lessThanOrEqualTo(698));
    expect(bottomRect.top, greaterThanOrEqualTo(0));
    expect(bottomRect.bottom, lessThanOrEqualTo(698));
    expect(topRect.top, closeTo(698 - bottomRect.bottom, 0.01));

    await tester.tapAt(
      Offset(bottomRect.left + bottomRect.width * 0.3, bottomRect.bottom - 38),
    );
    await tester.pumpAndSettle();

    final typographyRect = tester.getRect(
      find.byKey(const ValueKey('reader-typography-panel')),
    );

    expect(bottomRect.top - typographyRect.bottom, closeTo(16, 0.01));
  });

  testWidgets('ReaderScreen keeps bottom panels attached on tall phones',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerDocumentSourceProvider.overrideWithValue(
            _FakeReaderDocumentSource(),
          ),
          readerProgressRepositoryProvider.overrideWithValue(
            _MemoryProgressRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ReaderScreen(bookId: 'book-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 300));
    await tester.pumpAndSettle();

    final bottomRect = tester.getRect(
      find.byKey(const ValueKey('reader-bottom-controls')),
    );

    await tester.tapAt(
      Offset(bottomRect.left + bottomRect.width * 0.7, bottomRect.bottom - 38),
    );
    await tester.pumpAndSettle();

    final pageTurnRect = tester.getRect(
      find.byKey(const ValueKey('reader-page-turn-panel')),
    );

    expect(bottomRect.top - pageTurnRect.bottom, closeTo(16, 0.01));
  });

  testWidgets('ReaderScreen switches to scroll mode through reader controls',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerDocumentSourceProvider.overrideWithValue(
            _FakeReaderDocumentSource(),
          ),
          readerProgressRepositoryProvider.overrideWithValue(
            _MemoryProgressRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ReaderScreen(bookId: 'book-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('reader-engine-slide-view')), findsOneWidget);

    await tester.tapAt(const Offset(195, 420));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(229, 786));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-page-turn-panel')),
      findsOneWidget,
    );

    await tester.tap(find.text('滚动'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-engine-scroll-view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-slide-view')),
      findsNothing,
    );
    final chapterTop = tester.getTopLeft(
      find.byKey(const ValueKey('reader-engine-scroll-chapter-0')),
    );
    expect(chapterTop.dy, greaterThanOrEqualTo(17));
  });

  testWidgets('ReaderScreen switches to simulated mode through reader controls',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerDocumentSourceProvider.overrideWithValue(
            _FakeReaderDocumentSource(),
          ),
          readerProgressRepositoryProvider.overrideWithValue(
            _MemoryProgressRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ReaderScreen(bookId: 'book-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-engine-slide-view')),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(195, 420));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(229, 786));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-page-turn-panel')),
      findsOneWidget,
    );

    await tester.tap(find.text('仿真'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-engine-simulated-view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-slide-view')),
      findsNothing,
    );
  });

  testWidgets('ReaderScreen switches to cover mode through reader controls',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerDocumentSourceProvider.overrideWithValue(
            _FakeReaderDocumentSource(),
          ),
          readerProgressRepositoryProvider.overrideWithValue(
            _MemoryProgressRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ReaderScreen(bookId: 'book-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-engine-slide-view')),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(195, 420));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(229, 786));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-page-turn-panel')),
      findsOneWidget,
    );

    await tester.tap(find.text('覆盖'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-engine-cover-view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-slide-view')),
      findsNothing,
    );
  });

  testWidgets('ReaderScreen scroll mode progress label follows visible chapter',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerDocumentSourceProvider.overrideWithValue(
            _FakeReaderDocumentSource(),
          ),
          readerProgressRepositoryProvider.overrideWithValue(
            _MemoryProgressRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ReaderScreen(bookId: 'book-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 420));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(229, 786));
    await tester.pumpAndSettle();
    await tester.tap(find.text('滚动'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reader-progress')),
        matching: find.text('第一章'),
      ),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('reader-engine-scroll-view')),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reader-progress')),
        matching: find.text('第二章'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reader-progress')),
        matching: find.text('第一章'),
      ),
      findsNothing,
    );
  });

  testWidgets('ReaderScreen next chapter button works in scroll mode',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final progressRepository = _MemoryProgressRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerDocumentSourceProvider.overrideWithValue(
            _FakeReaderDocumentSource(),
          ),
          readerProgressRepositoryProvider.overrideWithValue(
            progressRepository,
          ),
        ],
        child: const MaterialApp(
          home: ReaderScreen(bookId: 'book-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 420));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(229, 786));
    await tester.pumpAndSettle();
    await tester.tap(find.text('滚动'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-engine-scroll-chapter-0')),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(195, 420));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(318, 719));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-engine-scroll-chapter-1')),
      findsOneWidget,
    );
    expect(progressRepository.saved?.chapterIndex, 1);
  });

  testWidgets('ReaderScreen catalog opens at the current chapter',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerDocumentSourceProvider.overrideWithValue(
            _LargeCatalogReaderDocumentSource(),
          ),
          readerProgressRepositoryProvider.overrideWithValue(
            _MemoryProgressRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ReaderScreen(
            bookId: 'book-1',
            initialChapterIndex: 35,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 420));
    await tester.pumpAndSettle();

    final bottomRect = tester.getRect(
      find.byKey(const ValueKey('reader-bottom-controls')),
    );
    await tester.tapAt(
      Offset(bottomRect.left + bottomRect.width * 0.1, bottomRect.bottom - 38),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('reader-catalog-sheet')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reader-catalog-chapter-35')),
      findsOneWidget,
    );

    final listTop =
        tester.getTopLeft(find.byKey(const ValueKey('reader-catalog-list'))).dy;
    final currentChapterTop = tester
        .getTopLeft(find.byKey(const ValueKey('reader-catalog-chapter-35')))
        .dy;
    expect(currentChapterTop, closeTo(listTop, 1));

    await tester.pumpAndSettle();
  });
}

class _FakeReaderDocumentSource implements ReaderDocumentSource {
  @override
  Future<ReaderDocument> loadDocument(String bookId) async {
    return ReaderDocument(
      bookId: bookId,
      title: '测试书',
      sourceType: ReaderSourceType.localTxt,
      chapterCount: 2,
    );
  }

  @override
  Future<ReaderChapterMetaPage> loadChapterMetas({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    return ReaderChapterMetaPage(
      items: const [
        ReaderChapterMeta(
          id: 'chapter-0',
          bookId: 'book-1',
          index: 0,
          title: '第一章',
          normalizedContentLength: 8,
          isCached: true,
        ),
      ],
      offset: offset,
      limit: limit,
      hasMore: false,
    );
  }

  @override
  Future<ReaderChapter> loadChapter({
    required String bookId,
    required int chapterIndex,
  }) async {
    final title = chapterIndex == 0 ? '第一章' : '第二章';
    const content = '第一段正文\n第二段正文';
    return ReaderChapter(
      id: 'chapter-$chapterIndex',
      bookId: bookId,
      index: chapterIndex,
      title: title,
      rawContent: content,
      normalizedText: normalizeReaderEngineText(content),
      blocks: buildReaderContentBlocks(
        chapterIndex: chapterIndex,
        title: title,
        content: content,
      ),
    );
  }
}

class _LargeCatalogReaderDocumentSource implements ReaderDocumentSource {
  static const int _chapterCount = 60;

  @override
  Future<ReaderDocument> loadDocument(String bookId) async {
    return ReaderDocument(
      bookId: bookId,
      title: 'Test Book',
      sourceType: ReaderSourceType.localTxt,
      chapterCount: _chapterCount,
    );
  }

  @override
  Future<ReaderChapterMetaPage> loadChapterMetas({
    required String bookId,
    required int offset,
    required int limit,
  }) async {
    final end = (offset + limit).clamp(0, _chapterCount).toInt();
    return ReaderChapterMetaPage(
      items: [
        for (var index = offset; index < end; index++)
          ReaderChapterMeta(
            id: 'chapter-$index',
            bookId: bookId,
            index: index,
            title: _chapterTitle(index),
            normalizedContentLength: 120,
            isCached: true,
          ),
      ],
      offset: offset,
      limit: limit,
      hasMore: end < _chapterCount,
    );
  }

  @override
  Future<ReaderChapter> loadChapter({
    required String bookId,
    required int chapterIndex,
  }) async {
    final title = _chapterTitle(chapterIndex);
    const content = 'First paragraph.\nSecond paragraph.';
    return ReaderChapter(
      id: 'chapter-$chapterIndex',
      bookId: bookId,
      index: chapterIndex,
      title: title,
      rawContent: content,
      normalizedText: normalizeReaderEngineText(content),
      blocks: buildReaderContentBlocks(
        chapterIndex: chapterIndex,
        title: title,
        content: content,
      ),
    );
  }

  String _chapterTitle(int chapterIndex) => 'Chapter ${chapterIndex + 1}';
}

class _MemoryProgressRepository implements ReaderProgressRepository {
  ReaderLocation? saved;

  @override
  Future<ReaderLocation?> loadProgress(String bookId) async => saved;

  @override
  Future<void> saveProgress(ReaderLocation location) async {
    saved = location;
  }
}
