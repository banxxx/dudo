import 'package:dudo/features/reader_engine/data/reader_content_parser.dart';
import 'package:dudo/features/reader_engine/data/reader_document_source.dart';
import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_document.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/domain/reader_source_type.dart';
import 'package:dudo/features/reader_engine/domain/reader_turn_mode.dart';
import 'package:dudo/features/reader_engine/domain/reader_viewport_state.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_engine.dart';
import 'package:dudo/features/reader_engine/presentation/modes/scroll_reader_view.dart';
import 'package:dudo/features/reader_engine/domain/reader_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScrollReaderView positions center chapter at the top directly',
      (tester) async {
    final settings = _scrollSettings();
    final previous = await _windowItem(0, settings);
    final center = await _windowItem(1, settings);
    final next = await _windowItem(2, settings);
    final reportedLocations = <ReaderLocation>[];
    const viewportSize = Size(320, 520);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: viewportSize.width,
          height: viewportSize.height,
          child: ScrollReaderView(
            bookId: 'book-1',
            chapterCount: 4,
            source: _FakeReaderDocumentSource(),
            layoutEngine: const FlutterReaderLayoutEngine(),
            viewportSize: viewportSize,
            viewport: ReaderViewportState(
              center: center,
              currentLocation: ReaderLocation.startOfChapter(
                bookId: 'book-1',
                chapterIndex: 1,
              ),
              currentLayout: center.layout,
              previous: previous,
              next: next,
            ),
            settings: settings,
            palette: ReaderTheme.parchment,
            onContentTap: () {},
            onLocationChanged: reportedLocations.add,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('reader-engine-scroll-chapter-1')),
        findsOneWidget);

    final centerTop = tester.getTopLeft(
      find.byKey(const ValueKey('reader-engine-scroll-chapter-1')),
    );
    expect(centerTop.dy, closeTo(settings.pagePadding.top, 1));
  });

  testWidgets('ScrollReaderView reports adjacent chapter after natural scroll',
      (tester) async {
    final settings = _scrollSettings();
    final previous = await _windowItem(0, settings);
    final center = await _windowItem(1, settings);
    final next = await _windowItem(2, settings);
    final reportedLocations = <ReaderLocation>[];
    const viewportSize = Size(320, 520);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: viewportSize.width,
          height: viewportSize.height,
          child: ScrollReaderView(
            bookId: 'book-1',
            chapterCount: 4,
            source: _FakeReaderDocumentSource(),
            layoutEngine: const FlutterReaderLayoutEngine(),
            viewportSize: viewportSize,
            viewport: ReaderViewportState(
              center: center,
              currentLocation: ReaderLocation.startOfChapter(
                bookId: 'book-1',
                chapterIndex: 1,
              ),
              currentLayout: center.layout,
              previous: previous,
              next: next,
            ),
            settings: settings,
            palette: ReaderTheme.parchment,
            onContentTap: () {},
            onLocationChanged: reportedLocations.add,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('reader-engine-scroll-view')),
      Offset(0, -(center.layout.contentHeight + 160)),
    );
    await tester.pumpAndSettle();

    expect(reportedLocations.map((location) => location.chapterIndex),
        contains(2));
  });

  testWidgets('ScrollReaderView programmatic jump paints target chapter first',
      (tester) async {
    final settings = _scrollSettings();
    final previous = await _windowItem(19, settings);
    final center = await _windowItem(20, settings);
    final next = await _windowItem(21, settings);
    final reportedLocations = <ReaderLocation>[];
    const viewportSize = Size(320, 520);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: viewportSize.width,
          height: viewportSize.height,
          child: ScrollReaderView(
            bookId: 'book-1',
            chapterCount: 30,
            source: _FakeReaderDocumentSource(),
            layoutEngine: const FlutterReaderLayoutEngine(),
            viewportSize: viewportSize,
            viewport: ReaderViewportState(
              center: center,
              currentLocation: ReaderLocation.startOfChapter(
                bookId: 'book-1',
                chapterIndex: 20,
              ),
              currentLayout: center.layout,
              previous: previous,
              next: next,
            ),
            settings: settings,
            palette: ReaderTheme.parchment,
            onContentTap: () {},
            onLocationChanged: reportedLocations.add,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('reader-engine-scroll-chapter-20')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-scroll-chapter-19')),
      findsNothing,
    );
    final centerTop = tester.getTopLeft(
      find.byKey(const ValueKey('reader-engine-scroll-chapter-20')),
    );
    expect(centerTop.dy, closeTo(settings.pagePadding.top, 1));
  });
}

ReaderSettings _scrollSettings() {
  return ReaderSettings.defaults().copyWith(turnMode: ReaderTurnMode.scroll);
}

Future<ReaderChapterWindowItem> _windowItem(
  int chapterIndex,
  ReaderSettings settings,
) async {
  final chapter = _chapter(chapterIndex);
  final layout = await const FlutterReaderLayoutEngine().layoutChapter(
    chapter: chapter,
    settings: settings,
    viewportSize: const Size(320, 520),
  );
  return ReaderChapterWindowItem(
    chapter: chapter,
    layout: layout,
    status: ReaderChapterLoadStatus.loaded,
  );
}

class _FakeReaderDocumentSource implements ReaderDocumentSource {
  @override
  Future<ReaderDocument> loadDocument(String bookId) async {
    return ReaderDocument(
      bookId: bookId,
      title: 'Test Book',
      sourceType: ReaderSourceType.localTxt,
      chapterCount: 4,
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
        for (var index = offset; index < offset + limit && index < 4; index++)
          ReaderChapterMeta(
            id: 'chapter-$index',
            bookId: bookId,
            index: index,
            title: 'Chapter $index',
            normalizedContentLength: 120,
            isCached: true,
          ),
      ],
      offset: offset,
      limit: limit,
      hasMore: offset + limit < 4,
    );
  }

  @override
  Future<ReaderChapter> loadChapter({
    required String bookId,
    required int chapterIndex,
  }) async {
    return _chapter(chapterIndex);
  }
}

ReaderChapter _chapter(int chapterIndex) {
  final title = '第 $chapterIndex 章';
  final content = List.generate(12, (index) => '第 $index 段正文').join('\n');
  return ReaderChapter(
    id: 'chapter-$chapterIndex',
    bookId: 'book-1',
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
