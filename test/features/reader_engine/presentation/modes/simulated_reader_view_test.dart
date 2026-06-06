import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_content_block.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/domain/reader_viewport_state.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_models.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated_reader_view.dart';
import 'package:dudo/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'SimulatedReaderView animates to the next page and reports location',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 520);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final center = _item(0, pageCount: 2);
    final reportedLocations = <ReaderLocation>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 520,
          child: SimulatedReaderView(
            viewport: ReaderViewportState(
              center: center,
              currentLocation: ReaderLocation.startOfChapter(
                bookId: 'book-1',
                chapterIndex: 0,
              ),
              currentLayout: center.layout,
            ),
            settings: ReaderSettings.defaults(),
            palette: ReaderTheme.parchment,
            controlsVisible: false,
            onContentTap: () {},
            onPreviousBoundary: () {},
            onNextBoundary: () {},
            onLocationChanged: reportedLocations.add,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('reader-engine-simulated-view')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('reader-engine-simulated-current-0-0')),
        findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('reader-engine-simulated-view')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();

    expect(reportedLocations, hasLength(1));
    expect(reportedLocations.single.chapterIndex, 0);
    expect(reportedLocations.single.offset, 10);
    expect(find.byKey(const ValueKey('reader-engine-simulated-current-0-1')),
        findsOneWidget);
  });

  testWidgets('SimulatedReaderView reports adjacent chapter page after drag',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 520);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final center = _item(0, pageCount: 1);
    final next = _item(1, pageCount: 1);
    final reportedLocations = <ReaderLocation>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 520,
          child: SimulatedReaderView(
            viewport: ReaderViewportState(
              center: center,
              currentLocation: ReaderLocation.startOfChapter(
                bookId: 'book-1',
                chapterIndex: 0,
              ),
              currentLayout: center.layout,
              next: next,
            ),
            settings: ReaderSettings.defaults(),
            palette: ReaderTheme.parchment,
            controlsVisible: false,
            onContentTap: () {},
            onPreviousBoundary: () {},
            onNextBoundary: () {},
            onLocationChanged: reportedLocations.add,
          ),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('reader-engine-simulated-view')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();

    expect(reportedLocations, hasLength(1));
    expect(reportedLocations.single.chapterIndex, 1);
    expect(reportedLocations.single.offset, 0);
  });

  testWidgets('SimulatedReaderView clips oversized page content',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 220);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final center = _oversizedItem(0);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 220,
          child: SimulatedReaderView(
            viewport: ReaderViewportState(
              center: center,
              currentLocation: ReaderLocation.startOfChapter(
                bookId: 'book-1',
                chapterIndex: 0,
              ),
              currentLayout: center.layout,
            ),
            settings: ReaderSettings.defaults(),
            palette: ReaderTheme.parchment,
            controlsVisible: false,
            onContentTap: () {},
            onPreviousBoundary: () {},
            onNextBoundary: () {},
            onLocationChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

ReaderChapterWindowItem _item(int chapterIndex, {required int pageCount}) {
  final layout = ReaderChapterLayout(
    chapterIndex: chapterIndex,
    revision: const ReaderLayoutRevision(contentHash: 1, settingsDigest: 's'),
    contentHeight: pageCount * 100,
    blockLayouts: const [],
    pages: [
      for (var pageIndex = 0; pageIndex < pageCount; pageIndex++)
        ReaderPageSlice(
          chapterIndex: chapterIndex,
          pageIndex: pageIndex,
          start: ReaderLocation(
            bookId: 'book-1',
            chapterIndex: chapterIndex,
            offset: pageIndex * 10,
          ),
          end: ReaderLocation(
            bookId: 'book-1',
            chapterIndex: chapterIndex,
            offset: pageIndex * 10 + 9,
          ),
          blocks: const [],
        ),
    ],
  );
  return ReaderChapterWindowItem(
    chapter: ReaderChapter(
      id: 'chapter-$chapterIndex',
      bookId: 'book-1',
      index: chapterIndex,
      title: 'Chapter $chapterIndex',
      rawContent: '',
      normalizedText: '',
      blocks: const [],
    ),
    layout: layout,
    status: ReaderChapterLoadStatus.loaded,
  );
}

ReaderChapterWindowItem _oversizedItem(int chapterIndex) {
  const block = ReaderParagraphBlock(
    blockId: 'oversized',
    chapterIndex: 0,
    startOffset: 0,
    endOffset: 1200,
    text: '这是一段用于测试分页裁剪的长文本。这是一段用于测试分页裁剪的长文本。这是一段用于测试分页裁剪的长文本。'
        '这是一段用于测试分页裁剪的长文本。这是一段用于测试分页裁剪的长文本。这是一段用于测试分页裁剪的长文本。'
        '这是一段用于测试分页裁剪的长文本。这是一段用于测试分页裁剪的长文本。这是一段用于测试分页裁剪的长文本。',
    paragraphIndex: 0,
  );
  final layout = ReaderChapterLayout(
    chapterIndex: chapterIndex,
    revision: const ReaderLayoutRevision(contentHash: 1, settingsDigest: 's'),
    contentHeight: 1200,
    blockLayouts: const [],
    pages: [
      ReaderPageSlice(
        chapterIndex: chapterIndex,
        pageIndex: 0,
        start: ReaderLocation.startOfChapter(
          bookId: 'book-1',
          chapterIndex: chapterIndex,
        ),
        end: const ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 0,
          offset: 1200,
        ),
        blocks: const [block],
      ),
    ],
  );
  return ReaderChapterWindowItem(
    chapter: ReaderChapter(
      id: 'chapter-$chapterIndex',
      bookId: 'book-1',
      index: chapterIndex,
      title: 'Chapter $chapterIndex',
      rawContent: block.text,
      normalizedText: block.text,
      blocks: const [block],
    ),
    layout: layout,
    status: ReaderChapterLoadStatus.loaded,
  );
}
