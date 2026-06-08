import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_content_block.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_settings.dart';
import 'package:dudo/features/reader_engine/domain/reader_viewport_state.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_models.dart';
import 'package:dudo/features/reader_engine/layout/reader_line_layout_models.dart';
import 'package:dudo/features/reader_engine/presentation/modes/reader_page_slice_canvas_surface.dart';
import 'package:dudo/features/reader_engine/presentation/modes/reader_page_slice_line_layout.dart';
import 'package:dudo/features/reader_engine/presentation/modes/reader_paged_window.dart';
import 'package:dudo/features/reader_engine/presentation/widgets/reader_canvas_highlight.dart';
import 'package:dudo/features/reader_engine/presentation/widgets/reader_canvas_page.dart';
import 'package:dudo/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders existing page slices through Canvas after layout',
      (tester) async {
    final resolvedPage = _resolvedPage(chapterId: 'chapter-cold');

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 640,
          child: ReaderPageSliceCanvasSurface(
            resolvedPage: resolvedPage,
            settings: ReaderSettings.defaults(),
            palette: _palette,
          ),
        ),
      ),
    );

    expect(find.byType(ReaderCanvasPage), findsNothing);
    await tester.pumpAndSettle();

    expect(find.byType(ReaderCanvasPage), findsOneWidget);
  });

  test('applies default first line indent in page slice layout', () async {
    const resolver = ReaderPageSliceLineLayoutResolver();
    final settings = ReaderSettings.defaults();

    final pageLayout = await resolver.resolvePage(
      resolvedPage: _resolvedPage(chapterId: 'chapter-align'),
      settings: settings,
      viewportSize: const Size(320, 640),
    );

    expect(
      pageLayout.lines.first.x,
      pageLayout.contentRect.left + settings.fontSize * 2,
    );
  });

  testWidgets('uses cached Canvas layout on the first frame', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const resolver = ReaderPageSliceLineLayoutResolver();
    final resolvedPage = _resolvedPage(chapterId: 'chapter-cached');
    await resolver.resolvePage(
      resolvedPage: resolvedPage,
      settings: ReaderSettings.defaults(),
      viewportSize: const Size(320, 640),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 640,
          child: ReaderPageSliceCanvasSurface(
            resolvedPage: resolvedPage,
            settings: ReaderSettings.defaults(),
            palette: _palette,
            layoutResolver: resolver,
          ),
        ),
      ),
    );

    expect(find.byType(ReaderCanvasPage), findsOneWidget);
  });

  testWidgets('forwards highlights to cached Canvas layout', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const highlights = [
      ReaderPageHighlight(
        range: ReaderTextRange(
          chapterIndex: 0,
          startOffset: 1,
          endOffset: 4,
        ),
        color: Color(0x5580CBC4),
      ),
    ];
    const resolver = ReaderPageSliceLineLayoutResolver();
    final resolvedPage = _resolvedPage(chapterId: 'chapter-highlight');
    await resolver.resolvePage(
      resolvedPage: resolvedPage,
      settings: ReaderSettings.defaults(),
      viewportSize: const Size(320, 640),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 640,
          child: ReaderPageSliceCanvasSurface(
            resolvedPage: resolvedPage,
            settings: ReaderSettings.defaults(),
            palette: _palette,
            highlights: highlights,
            layoutResolver: resolver,
          ),
        ),
      ),
    );

    final page = tester.widget<ReaderCanvasPage>(
      find.byType(ReaderCanvasPage),
    );

    expect(page.highlights, highlights);
  });
}

const _palette = ReaderPalette(
  name: 'test',
  background: Color(0xFFF8F4EA),
  foreground: Color(0xFF25251F),
);

ReaderResolvedPage _resolvedPage({required String chapterId}) {
  const text = '青铜鼎音震动，带着岁月的沧桑感。';
  const block = ReaderParagraphBlock(
    blockId: 'paragraph-0',
    chapterIndex: 0,
    startOffset: 0,
    endOffset: text.length,
    text: text,
    paragraphIndex: 0,
  );
  final chapter = ReaderChapter(
    id: chapterId,
    bookId: 'book-1',
    index: 0,
    title: '第一章',
    rawContent: text,
    normalizedText: text,
    blocks: [block],
  );
  const layout = ReaderChapterLayout(
    chapterIndex: 0,
    revision: ReaderLayoutRevision(contentHash: 1, settingsDigest: 's'),
    contentHeight: 100,
    blockLayouts: [],
    pages: [
      ReaderPageSlice(
        chapterIndex: 0,
        pageIndex: 0,
        start: ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 0,
          offset: 0,
        ),
        end: ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 0,
          offset: text.length,
        ),
        blocks: [block],
      ),
    ],
  );
  return ReaderResolvedPage(
    item: ReaderChapterWindowItem(
      chapter: chapter,
      layout: layout,
      status: ReaderChapterLoadStatus.loaded,
    ),
    page: layout.pages.first,
  );
}
