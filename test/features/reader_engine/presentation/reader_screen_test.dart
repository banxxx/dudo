import 'package:dudo/features/reader_engine/application/reader_engine_providers.dart';
import 'package:dudo/features/reader_engine/data/reader_content_parser.dart';
import 'package:dudo/features/reader_engine/data/reader_document_source.dart';
import 'package:dudo/features/reader_engine/data/reader_progress_repository.dart';
import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_document.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_source_type.dart';
import 'package:dudo/features/reader_engine/presentation/reader_screen.dart';
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
        find.byKey(const ValueKey('reader-engine-paged-view')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-progress')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-top-controls')), findsNothing);
    expect(find.text('第一章'), findsWidgets);
    final articleTitle = find.descendant(
      of: find.byKey(const ValueKey('reader-engine-paged-view')),
      matching: find.text('第一章'),
    );
    expect(tester.getTopLeft(articleTitle).dy, greaterThan(18));
    expect(tester.getTopLeft(articleTitle).dx, greaterThan(200));

    await tester.tapAt(const Offset(400, 300));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-top-controls')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reader-bottom-controls')), findsOneWidget);
    expect(find.text('测试书'), findsOneWidget);
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
        find.byKey(const ValueKey('reader-engine-paged-view')), findsOneWidget);

    await tester.tapAt(const Offset(195, 420));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(229, 786));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-page-turn-panel')),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(307, 546));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-engine-scroll-view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-paged-view')),
      findsNothing,
    );
    final chapterTop = tester.getTopLeft(
      find.byKey(const ValueKey('reader-engine-scroll-chapter-0')),
    );
    expect(chapterTop.dy, greaterThanOrEqualTo(17));
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
    await tester.tapAt(const Offset(307, 546));
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

class _MemoryProgressRepository implements ReaderProgressRepository {
  ReaderLocation? saved;

  @override
  Future<ReaderLocation?> loadProgress(String bookId) async => saved;

  @override
  Future<void> saveProgress(ReaderLocation location) async {
    saved = location;
  }
}
