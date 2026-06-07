import '../domain/reader_location.dart';
import 'reader_line_layout_models.dart';

class ReaderLinePositionMapper {
  const ReaderLinePositionMapper._();

  static int pageIndexForLocation({
    required ReaderLineChapterLayout layout,
    required ReaderLocation location,
  }) {
    if (layout.pages.isEmpty) return 0;
    final page = layout.pages.firstWhere(
      (page) {
        final isLastPage = page.pageIndex == layout.pages.last.pageIndex;
        final startsInPage = location.offset >= page.start.offset;
        final endsInPage = isLastPage
            ? location.offset <= page.end.offset
            : location.offset < page.end.offset;
        return startsInPage && endsInPage;
      },
      orElse: () {
        if (location.offset <= layout.pages.first.start.offset) {
          return layout.pages.first;
        }
        return layout.pages.last;
      },
    );
    return page.pageIndex;
  }

  static List<ReaderLineLayout> linesForRange({
    required ReaderLineChapterLayout layout,
    required ReaderTextRange range,
  }) {
    return [
      for (final block in layout.blocks)
        for (final line in block.lines)
          if (line.textRange.intersects(range)) line,
    ];
  }
}
