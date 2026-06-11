import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_background.dart';
import 'package:dudo/features/reader_engine/domain/reader_content_block.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/domain/reader_viewport_state.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_models.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_controller.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_fold_geometry.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_gesture.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/page_curl_render_box.dart';
import 'package:dudo/features/reader_engine/presentation/modes/simulated/simulated_reader_view.dart';
import 'package:dudo/features/reader_engine/presentation/widgets/reader_background.dart';
import 'package:dudo/features/reader_engine/domain/reader_theme.dart';
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

  testWidgets('SimulatedReaderView paints page-local reading backgrounds',
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

    expect(find.byType(ReaderBackgroundLayer), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SimulatedReaderView defers drag cancel reset during rebuild',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 520);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final center = _item(0, pageCount: 2);
    var controlsVisible = false;

    Widget buildReader() {
      return MaterialApp(
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
            controlsVisible: controlsVisible,
            onContentTap: () {},
            onPreviousBoundary: () {},
            onNextBoundary: () {},
            onLocationChanged: (_) {},
          ),
        ),
      );
    }

    await tester.pumpWidget(buildReader());

    final gesture = await tester.startGesture(
      tester.getCenter(
          find.byKey(const ValueKey('reader-engine-simulated-view'))),
    );
    await gesture.moveBy(const Offset(-48, 0));
    await tester.pump();

    controlsVisible = true;
    await tester.pumpWidget(buildReader());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('SimulatedReaderView keeps the curl painter during page handoff',
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

    final view = find.byKey(const ValueKey('reader-engine-simulated-view'));
    final gesture = await tester.startGesture(
      tester.getCenter(view) + const Offset(140, 0),
    );

    await gesture.moveBy(const Offset(-140, 0));
    await tester.pump();
    await tester.pump();
    await gesture.up();
    for (var i = 0; i < 60 && reportedLocations.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();

    expect(reportedLocations, hasLength(1));
    expect(
      find.byKey(const ValueKey('reader-engine-simulated-current-0-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reader-engine-page-curl-painter')),
        findsOneWidget);

    for (var i = 0;
        i < 6 &&
            find
                .byKey(const ValueKey('reader-engine-page-curl-painter'))
                .evaluate()
                .isNotEmpty;
        i++) {
      await tester.pump();
    }

    expect(find.byKey(const ValueKey('reader-engine-page-curl-painter')),
        findsNothing);
  });

  testWidgets(
      'SimulatedReaderView settles active commit before handling external request',
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
      find.byKey(const ValueKey('reader-engine-simulated-view')),
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
      find.byKey(const ValueKey('reader-engine-simulated-current-0-2')),
      findsOneWidget,
    );
  });

  testWidgets('SimulatedReaderView advances on rapid repeated taps',
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

    await tester.tapAt(const Offset(280, 260));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(const Offset(280, 260));
    await tester.pumpAndSettle();

    expect(reportedLocations, hasLength(2));
    expect(reportedLocations[0].offset, 10);
    expect(reportedLocations[1].offset, 20);
    expect(
      find.byKey(const ValueKey('reader-engine-simulated-current-0-2')),
      findsOneWidget,
    );
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
    expect(
      find.byKey(const ValueKey('reader-engine-simulated-committed-1-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-engine-simulated-current-0-0')),
      findsNothing,
    );
  });

  testWidgets(
      'SimulatedReaderView animates to the previous page and reports location',
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

    expect(find.byKey(const ValueKey('reader-engine-simulated-current-0-1')),
        findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('reader-engine-simulated-view')),
      const Offset(140, 0),
    );
    await tester.pumpAndSettle();

    expect(reportedLocations, hasLength(1));
    expect(reportedLocations.single.chapterIndex, 0);
    expect(reportedLocations.single.offset, 0);
    expect(find.byKey(const ValueKey('reader-engine-simulated-current-0-0')),
        findsOneWidget);
  });

  testWidgets('SimulatedReaderView elastically pulls back without target page',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 520);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final center = _item(0, pageCount: 1);
    final reportedLocations = <ReaderLocation>[];
    var nextBoundaryCalls = 0;

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
            onNextBoundary: () => nextBoundaryCalls++,
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

    expect(reportedLocations, isEmpty);
    expect(nextBoundaryCalls, 0);
    expect(find.byKey(const ValueKey('reader-engine-simulated-current-0-0')),
        findsOneWidget);
  });

  testWidgets('SimulatedReaderView cancel clears active curl painter',
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

    await tester.drag(
      find.byKey(const ValueKey('reader-engine-simulated-view')),
      const Offset(-24, 0),
    );
    await tester.pumpAndSettle();

    expect(reportedLocations, isEmpty);
    expect(find.byKey(const ValueKey('reader-engine-page-curl-painter')),
        findsNothing);
  });

  testWidgets('SimulatedReaderView cancels short fling below commit range',
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

    await tester.fling(
      find.byKey(const ValueKey('reader-engine-simulated-view')),
      const Offset(-48, 0),
      1600,
    );
    await tester.pumpAndSettle();

    expect(reportedLocations, isEmpty);
    expect(find.byKey(const ValueKey('reader-engine-page-curl-painter')),
        findsNothing);
    expect(find.byKey(const ValueKey('reader-engine-simulated-current-0-0')),
        findsOneWidget);
  });

  testWidgets('SimulatedReaderView keeps curl painter during same-page drag',
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

    final view = find.byKey(const ValueKey('reader-engine-simulated-view'));
    final start = tester.getTopLeft(view) + const Offset(300, 260);
    final gesture = await tester.startGesture(start);

    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('reader-engine-page-curl-painter')),
        findsOneWidget);

    await gesture.moveBy(const Offset(-28, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey('reader-engine-page-curl-painter')),
        findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('SimulatedReaderView locks turn direction during one drag',
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

    final view = find.byKey(const ValueKey('reader-engine-simulated-view'));
    final start = tester.getTopLeft(view) + const Offset(300, 260);
    final gesture = await tester.startGesture(start);

    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump();
    await tester.pump();

    var renderBox = tester.renderObject<PageCurlRenderBox>(
      find.byKey(const ValueKey('reader-engine-page-curl-painter')),
    );
    expect(renderBox.turnType, PageCurlTurnType.nextPageOut);
    expect(renderBox.backPageAppearance.imageOpacity, lessThan(1));
    expect(renderBox.backPageAppearance.veilOpacity, greaterThan(0));

    await gesture.moveBy(const Offset(110, 0));
    await tester.pump();

    final curlPainter =
        find.byKey(const ValueKey('reader-engine-page-curl-painter'));
    if (curlPainter.evaluate().isNotEmpty) {
      renderBox = tester.renderObject<PageCurlRenderBox>(curlPainter);
      expect(renderBox.turnType, PageCurlTurnType.nextPageOut);
    }

    await gesture.up();
    await tester.pumpAndSettle();

    expect(reportedLocations, isEmpty);
    expect(find.byKey(const ValueKey('reader-engine-simulated-current-0-0')),
        findsOneWidget);
  });

  testWidgets('SimulatedReaderView cancels cleanly when drag returns to origin',
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

    final view = find.byKey(const ValueKey('reader-engine-simulated-view'));
    final start = tester.getTopLeft(view) + const Offset(300, 430);
    final gesture = await tester.startGesture(start);

    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('reader-engine-page-curl-painter')),
        findsOneWidget);

    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-engine-simulated-current-0-0')),
        findsOneWidget);
  });

  testWidgets('SimulatedReaderView does not commit when drag exits page',
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

    final view = find.byKey(const ValueKey('reader-engine-simulated-view'));
    final start = tester.getTopLeft(view) + const Offset(300, 260);
    final gesture = await tester.startGesture(start);

    await gesture.moveBy(const Offset(-340, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reportedLocations, isEmpty);
    expect(find.byKey(const ValueKey('reader-engine-simulated-current-0-0')),
        findsOneWidget);
  });

  testWidgets('SimulatedReaderView uses previousPageIn for previous drag',
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
          child: SimulatedReaderView(
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
            onLocationChanged: (_) {},
          ),
        ),
      ),
    );

    final view = find.byKey(const ValueKey('reader-engine-simulated-view'));
    final start = tester.getTopLeft(view) + const Offset(24, 260);
    final gesture = await tester.startGesture(start);

    await gesture.moveBy(const Offset(90, 0));
    await tester.pump();
    await tester.pump();

    final renderBox = tester.renderObject<PageCurlRenderBox>(
      find.byKey(const ValueKey('reader-engine-page-curl-painter')),
    );

    expect(renderBox.turnType, PageCurlTurnType.previousPageIn);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('SimulatedReaderView supports middle next-page curl drag',
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

    final view = find.byKey(const ValueKey('reader-engine-simulated-view'));
    final start = tester.getTopLeft(view) + const Offset(300, 260);
    final gesture = await tester.startGesture(start);

    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump();
    await tester.pump();

    final renderBox = tester.renderObject<PageCurlRenderBox>(
      find.byKey(const ValueKey('reader-engine-page-curl-painter')),
    );
    final geometry = PageCurlBezierGeometry.fromGesture(
      gesture: renderBox.gesture!,
      turnType: renderBox.turnType!,
      pageSize: renderBox.size,
    );

    expect(renderBox.turnType, PageCurlTurnType.nextPageOut);
    expect(geometry.corner, PageCurlFoldCorner.bottomRight);
    expect(geometry.touch.dy, renderBox.size.height - 1);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'SimulatedReaderView retracts middle curl to page edge after inner start cancel',
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

    final view = find.byKey(const ValueKey('reader-engine-simulated-view'));
    final start = tester.getTopLeft(view) + const Offset(270, 260);
    final gesture = await tester.startGesture(start);

    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    await tester.pump();

    var renderBox = tester.renderObject<PageCurlRenderBox>(
      find.byKey(const ValueKey('reader-engine-page-curl-painter')),
    );
    expect(renderBox.turnType, PageCurlTurnType.nextPageOut);
    expect(renderBox.gesture!.anchor, PageCurlAnchor.middle);

    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();

    renderBox = tester.renderObject<PageCurlRenderBox>(
      find.byKey(const ValueKey('reader-engine-page-curl-painter')),
    );
    expect(renderBox.turnType, PageCurlTurnType.nextPageOut);
    expect(renderBox.gesture!.current.dx, 270);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    renderBox = tester.renderObject<PageCurlRenderBox>(
      find.byKey(const ValueKey('reader-engine-page-curl-painter')),
    );
    expect(renderBox.turnType, PageCurlTurnType.nextPageOut);
    expect(renderBox.gesture!.current.dx, greaterThan(270));
    expect(renderBox.gesture!.current.dx, lessThanOrEqualTo(320));

    await tester.pumpAndSettle();

    expect(reportedLocations, isEmpty);
    expect(find.byKey(const ValueKey('reader-engine-simulated-current-0-0')),
        findsOneWidget);
  });

  testWidgets(
      'SimulatedReaderView keeps previous-page cancel curl while it exits left',
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

    final view = find.byKey(const ValueKey('reader-engine-simulated-view'));
    final start = tester.getTopLeft(view) + const Offset(24, 260);
    final gesture = await tester.startGesture(start);

    await gesture.moveBy(const Offset(90, 0));
    await tester.pump();
    await tester.pump();

    var renderBox = tester.renderObject<PageCurlRenderBox>(
      find.byKey(const ValueKey('reader-engine-page-curl-painter')),
    );
    expect(renderBox.turnType, PageCurlTurnType.previousPageIn);

    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();

    renderBox = tester.renderObject<PageCurlRenderBox>(
      find.byKey(const ValueKey('reader-engine-page-curl-painter')),
    );
    expect(renderBox.gesture!.current.dx, 14);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    renderBox = tester.renderObject<PageCurlRenderBox>(
      find.byKey(const ValueKey('reader-engine-page-curl-painter')),
    );
    expect(renderBox.turnType, PageCurlTurnType.previousPageIn);
    expect(renderBox.gesture!.current.dx, lessThan(14));
    expect(renderBox.gesture!.current.dx, greaterThan(-320));

    await tester.pumpAndSettle();

    expect(reportedLocations, isEmpty);
    expect(find.byKey(const ValueKey('reader-engine-simulated-current-0-1')),
        findsOneWidget);
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
