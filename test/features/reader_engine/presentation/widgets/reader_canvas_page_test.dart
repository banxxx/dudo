import 'dart:io';
import 'dart:ui' as ui;

import 'package:dudo/features/reader_engine/domain/reader_background.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_line_layout_models.dart';
import 'package:dudo/features/reader_engine/presentation/widgets/reader_canvas_highlight.dart';
import 'package:dudo/features/reader_engine/presentation/widgets/reader_canvas_page.dart';
import 'package:dudo/features/reader_engine/domain/reader_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderCanvasPage', () {
    testWidgets('paints a line-backed page without building Text widgets',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReaderCanvasPage(
            pageLayout: _pageLayout(),
            palette: _palette,
            paintBackground: true,
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is ReaderPagePainter,
        ),
        findsOneWidget,
      );
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('passes highlights to the canvas painter', (tester) async {
      const highlights = [
        ReaderPageHighlight(
          range: ReaderTextRange(
            chapterIndex: 0,
            startOffset: 1,
            endOffset: 3,
          ),
          color: Color(0x5580CBC4),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ReaderCanvasPage(
            pageLayout: _pageLayout(),
            palette: _palette,
            highlights: highlights,
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is ReaderPagePainter,
        ),
      );
      final painter = customPaint.painter! as ReaderPagePainter;

      expect(painter.highlights, highlights);
    });
  });

  group('ReaderPagePainter', () {
    test('repaints when highlights change', () {
      final pageLayout = _pageLayout();
      final oldPainter = ReaderPagePainter(
        pageLayout: pageLayout,
        palette: _palette,
      );
      final newPainter = ReaderPagePainter(
        pageLayout: pageLayout,
        palette: _palette,
        highlights: const [
          ReaderPageHighlight(
            range: ReaderTextRange(
              chapterIndex: 0,
              startOffset: 1,
              endOffset: 3,
            ),
            color: Color(0x5580CBC4),
          ),
        ],
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });
  });

  group('ReaderPageRasterizer', () {
    test('renders a high-density image from a page layout', () async {
      const rasterizer = ReaderPageRasterizer();

      final image = await rasterizer.renderImage(
        pageLayout: _pageLayout(),
        palette: _palette,
        pixelRatio: 2,
      );

      expect(image.width, 240);
      expect(image.height, 320);
      image.dispose();
    });

    test('renders highlighted ranges into a high-density image', () async {
      const rasterizer = ReaderPageRasterizer();

      final image = await rasterizer.renderImage(
        pageLayout: _pageLayout(),
        palette: _palette,
        pixelRatio: 2,
        highlights: const [
          ReaderPageHighlight(
            range: ReaderTextRange(
              chapterIndex: 0,
              startOffset: 1,
              endOffset: 3,
            ),
            color: Color(0x5580CBC4),
          ),
        ],
      );

      expect(image.width, 240);
      expect(image.height, 320);
      image.dispose();
    });

    test('renders custom image reading background into page image', () async {
      const rasterizer = ReaderPageRasterizer();
      final backgroundFile = await _createSolidPngFile(Colors.red);

      final image = await rasterizer.renderImage(
        pageLayout: _pageLayout(),
        palette: _palette,
        pixelRatio: 1,
        background: ReaderBackgroundPreference(
          type: ReaderBackgroundType.customImage,
          id: 'custom_red_test',
          filePath: backgroundFile.path,
          opacity: 1,
          alignment: Alignment.center,
          fit: BoxFit.fill,
          tintEnabled: false,
        ),
      );

      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(bytes, isNotNull);
      final offset =
          ((image.width * (image.height ~/ 2)) + image.width ~/ 2) * 4;
      final red = bytes!.getUint8(offset);
      final green = bytes.getUint8(offset + 1);
      final blue = bytes.getUint8(offset + 2);

      expect(red, greaterThan(green + 120));
      expect(red, greaterThan(blue + 120));

      image.dispose();
      await backgroundFile.delete();
    });
  });
}

const _palette = ReaderPalette(
  name: 'test',
  background: Color(0xFFF8F4EA),
  foreground: Color(0xFF25251F),
);

Future<File> _createSolidPngFile(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint()..color = color);
  final picture = recorder.endRecording();
  final image = await picture.toImage(4, 4);
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File(
    '${Directory.systemTemp.path}/reader-background-${DateTime.now().microsecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
  return file;
}

ReaderPageLayout _pageLayout() {
  const style = TextStyle(
    fontFamily: 'Noto Serif SC',
    fontSize: 18,
    height: 1.5,
    decoration: TextDecoration.none,
  );
  const range = ReaderTextRange(
    chapterIndex: 0,
    startOffset: 0,
    endOffset: 4,
  );
  const run = ReaderTextRunLayout(
    textRange: range,
    text: '测试文本',
    x: 12,
    baseline: 34,
    width: 80,
    style: style,
  );
  const line = ReaderLineLayout(
    textRange: range,
    x: 12,
    y: 10,
    width: 80,
    height: 28,
    baseline: 34,
    isFirstLineOfBlock: true,
    isLastLineOfBlock: true,
    isLastLineOfParagraph: true,
    align: ReaderTextAlign.start,
    runs: [run],
  );
  const block = ReaderPageBlockLayout(
    blockId: 'block-1',
    type: ReaderPageBlockType.paragraph,
    chapterIndex: 0,
    textRange: range,
    rect: Rect.fromLTWH(12, 10, 80, 28),
    style: style,
    lines: [line],
    isFirstFragmentOfBlock: true,
    isLastFragmentOfBlock: true,
  );
  return const ReaderPageLayout(
    chapterIndex: 0,
    pageIndex: 0,
    pageRect: Rect.fromLTWH(0, 0, 120, 160),
    contentRect: Rect.fromLTWH(12, 10, 96, 140),
    start: ReaderLocation(
      bookId: 'book-1',
      chapterIndex: 0,
      offset: 0,
    ),
    end: ReaderLocation(
      bookId: 'book-1',
      chapterIndex: 0,
      offset: 4,
    ),
    blocks: [block],
  );
}
