import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_settings.dart';
import 'package:dudo/features/reader_engine/layout/reader_line_layout_models.dart';
import 'package:dudo/features/reader_engine/presentation/modes/reader_line_page_surface.dart';
import 'package:dudo/features/reader_engine/presentation/widgets/reader_canvas_page.dart';
import 'package:dudo/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ReaderLinePageSurface renders through ReaderCanvasPage',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderLinePageSurface(
          pageLayout: _pageLayout(),
          palette: _palette,
        ),
      ),
    );

    expect(find.byType(ReaderCanvasPage), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}

const _palette = ReaderPalette(
  name: 'test',
  background: Color(0xFFF8F4EA),
  foreground: Color(0xFF25251F),
);

ReaderPageLayout _pageLayout() {
  const style = TextStyle(fontSize: 18, decoration: TextDecoration.none);
  const range = ReaderTextRange(
    chapterIndex: 0,
    startOffset: 0,
    endOffset: 4,
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
    runs: [
      ReaderTextRunLayout(
        textRange: range,
        text: '测试文本',
        x: 12,
        baseline: 34,
        width: 80,
        style: style,
      ),
    ],
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
    start: ReaderLocation(bookId: 'book-1', chapterIndex: 0, offset: 0),
    end: ReaderLocation(bookId: 'book-1', chapterIndex: 0, offset: 4),
    blocks: [block],
  );
}
