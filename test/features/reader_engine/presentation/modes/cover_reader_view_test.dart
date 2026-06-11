import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_background.dart';
import 'package:dudo/features/reader_engine/domain/reader_content_block.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/domain/reader_viewport_state.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_models.dart';
import 'package:dudo/features/reader_engine/presentation/modes/cover_reader_view.dart';
import 'package:dudo/features/reader_engine/presentation/widgets/reader_background.dart';
import 'package:dudo/features/reader_engine/domain/reader_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CoverReaderView covers current page with the next page',
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
          child: CoverReaderView(
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

    expect(
      find.byKey(const ValueKey('reader-engine-cover-view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-cover-current-0-0')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('reader-engine-cover-view')),
      const Offset(-140, 0),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('reader-engine-cover-current-0-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-cover-target-0-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-cover-moving-current')),
      findsOneWidget,
    );

    await tester.pumpAndSettle();

    expect(reportedLocations, hasLength(1));
    expect(reportedLocations.single.chapterIndex, 0);
    expect(reportedLocations.single.offset, 10);
    expect(
      find.byKey(const ValueKey('reader-engine-cover-current-0-1')),
      findsOneWidget,
    );
  });

  testWidgets('CoverReaderView reveals previous page behind the current page',
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
          child: CoverReaderView(
            viewport: ReaderViewportState(
              center: center,
              currentLocation: const ReaderLocation(
                bookId: 'book-1',
                chapterIndex: 0,
                offset: 10,
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

    await tester.drag(
      find.byKey(const ValueKey('reader-engine-cover-view')),
      const Offset(140, 0),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('reader-engine-cover-target-0-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-cover-current-0-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-cover-moving-target')),
      findsOneWidget,
    );

    await tester.pumpAndSettle();

    expect(reportedLocations, hasLength(1));
    expect(reportedLocations.single.chapterIndex, 0);
    expect(reportedLocations.single.offset, 0);
  });

  testWidgets('CoverReaderView keeps reading backgrounds on covered pages',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 520);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final center = _item(0, pageCount: 2);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 520,
          child: CoverReaderView(
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
            backgroundPreference: ReaderBackgroundPreference.bamboo(),
            controlsVisible: false,
            onContentTap: () {},
            onPreviousBoundary: () {},
            onNextBoundary: () {},
            onLocationChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(ReaderBackgroundLayer), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('reader-engine-cover-view')),
      const Offset(-140, 0),
    );
    await tester.pump();

    expect(find.byType(ReaderBackgroundLayer), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('reader-engine-cover-target-0-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-cover-moving-current')),
      findsOneWidget,
    );

    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('reader-engine-cover-view')),
      const Offset(140, 0),
    );
    await tester.pump();

    expect(find.byType(ReaderBackgroundLayer), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('reader-engine-cover-current-0-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-cover-moving-target')),
      findsOneWidget,
    );
  });

  testWidgets('CoverReaderView locks direction during one drag gesture',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 520);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final center = _item(0, pageCount: 3);
    final reportedLocations = <ReaderLocation>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 520,
          child: CoverReaderView(
            viewport: ReaderViewportState(
              center: center,
              currentLocation: const ReaderLocation(
                bookId: 'book-1',
                chapterIndex: 0,
                offset: 10,
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

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('reader-engine-cover-view'))),
    );
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('reader-engine-cover-target-0-2')),
      findsOneWidget,
    );

    await gesture.moveBy(const Offset(260, 0));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('reader-engine-cover-target-0-0')),
      findsNothing,
    );

    await gesture.up();
    await tester.pumpAndSettle();

    expect(reportedLocations, isEmpty);
    expect(
      find.byKey(const ValueKey('reader-engine-cover-current-0-1')),
      findsOneWidget,
    );
  });

  testWidgets('CoverReaderView ignores a new drag while settling back',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 520);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final center = _item(0, pageCount: 3);
    final reportedLocations = <ReaderLocation>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 520,
          child: CoverReaderView(
            viewport: ReaderViewportState(
              center: center,
              currentLocation: const ReaderLocation(
                bookId: 'book-1',
                chapterIndex: 0,
                offset: 10,
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

    await tester.drag(
      find.byKey(const ValueKey('reader-engine-cover-view')),
      const Offset(-60, 0),
    );
    await tester.pump(const Duration(milliseconds: 60));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('reader-engine-cover-view'))),
    );
    await gesture.moveBy(const Offset(180, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reportedLocations, isEmpty);
    expect(
      find.byKey(const ValueKey('reader-engine-cover-current-0-1')),
      findsOneWidget,
    );
  });

  testWidgets(
      'CoverReaderView settles active commit before handling external request',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 520);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final center = _item(0, pageCount: 3);
    final reportedLocations = <ReaderLocation>[];
    var requestId = 0;

    Widget buildView() {
      return MaterialApp(
        home: SizedBox(
          width: 320,
          height: 520,
          child: CoverReaderView(
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
            externalPageTurnRequestId: requestId,
            externalPageTurnDirection: 1,
            onContentTap: () {},
            onPreviousBoundary: () {},
            onNextBoundary: () {},
            onLocationChanged: reportedLocations.add,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildView());

    await tester.drag(
      find.byKey(const ValueKey('reader-engine-cover-view')),
      const Offset(-140, 0),
    );
    await tester.pump(const Duration(milliseconds: 60));

    requestId = 1;
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    expect(reportedLocations, hasLength(2));
    expect(reportedLocations[0].offset, 10);
    expect(reportedLocations[1].offset, 20);
    expect(
      find.byKey(const ValueKey('reader-engine-cover-current-0-2')),
      findsOneWidget,
    );
  });

  testWidgets('CoverReaderView advances on rapid repeated taps',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 520);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final center = _item(0, pageCount: 3);
    final reportedLocations = <ReaderLocation>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 520,
          child: CoverReaderView(
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

    await tester.tapAt(const Offset(280, 260));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(const Offset(280, 260));
    await tester.pumpAndSettle();

    expect(reportedLocations, hasLength(2));
    expect(reportedLocations[0].offset, 10);
    expect(reportedLocations[1].offset, 20);
    expect(
      find.byKey(const ValueKey('reader-engine-cover-current-0-2')),
      findsOneWidget,
    );
  });

  testWidgets('CoverReaderView keeps adjacent chapter page after commit',
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
          child: CoverReaderView(
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
      find.byKey(const ValueKey('reader-engine-cover-view')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();

    expect(reportedLocations, hasLength(1));
    expect(reportedLocations.single.chapterIndex, 1);
    expect(find.byKey(const ValueKey('reader-engine-cover-committed-1-0')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('reader-engine-cover-current-0-0')),
        findsNothing);
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
          blocks: [
            ReaderParagraphBlock(
              blockId: 'p-$chapterIndex-$pageIndex',
              chapterIndex: chapterIndex,
              startOffset: pageIndex * 10,
              endOffset: pageIndex * 10 + 9,
              text: 'Chapter $chapterIndex Page $pageIndex',
              paragraphIndex: pageIndex,
            ),
          ],
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
