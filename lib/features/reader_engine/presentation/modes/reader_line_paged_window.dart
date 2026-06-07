import '../../domain/reader_chapter.dart';
import '../../domain/reader_location.dart';
import '../../layout/reader_line_layout_models.dart';
import '../../layout/reader_line_position_mapper.dart';

class ReaderLineResolvedPage {
  const ReaderLineResolvedPage({
    required this.chapter,
    required this.page,
  });

  final ReaderChapter chapter;
  final ReaderPageLayout page;

  int get chapterIndex => page.chapterIndex;
  int get pageIndex => page.pageIndex;
}

class ReaderLineChapterWindowItem {
  const ReaderLineChapterWindowItem({
    required this.chapter,
    required this.layout,
  });

  final ReaderChapter chapter;
  final ReaderLineChapterLayout layout;
}

class ReaderLinePagedWindow {
  const ReaderLinePagedWindow._({
    required this.current,
    required this.previous,
    required this.next,
  });

  factory ReaderLinePagedWindow.fromLayouts({
    required ReaderLineChapterWindowItem center,
    required ReaderLocation location,
    ReaderLineChapterWindowItem? previousChapter,
    ReaderLineChapterWindowItem? nextChapter,
    int? pageIndex,
  }) {
    final currentPages = center.layout.pages;
    final resolvedPageIndex = _clampedPageIndex(
      pages: currentPages,
      pageIndex: pageIndex ??
          ReaderLinePositionMapper.pageIndexForLocation(
            layout: center.layout,
            location: location,
          ),
    );
    final current = ReaderLineResolvedPage(
      chapter: center.chapter,
      page: currentPages[resolvedPageIndex],
    );

    return ReaderLinePagedWindow._(
      current: current,
      previous: _previousPageFor(
        center: center,
        previousChapter: previousChapter,
        pageIndex: resolvedPageIndex,
      ),
      next: _nextPageFor(
        center: center,
        nextChapter: nextChapter,
        pageIndex: resolvedPageIndex,
      ),
    );
  }

  final ReaderLineResolvedPage current;
  final ReaderLineResolvedPage? previous;
  final ReaderLineResolvedPage? next;

  ReaderLineResolvedPage? pageForDirection(int direction) {
    if (direction < 0) return previous;
    if (direction > 0) return next;
    return current;
  }

  static ReaderLineResolvedPage? _previousPageFor({
    required ReaderLineChapterWindowItem center,
    required ReaderLineChapterWindowItem? previousChapter,
    required int pageIndex,
  }) {
    if (pageIndex > 0) {
      return ReaderLineResolvedPage(
        chapter: center.chapter,
        page: center.layout.pages[pageIndex - 1],
      );
    }
    if (previousChapter == null || previousChapter.layout.pages.isEmpty) {
      return null;
    }
    return ReaderLineResolvedPage(
      chapter: previousChapter.chapter,
      page: previousChapter.layout.pages.last,
    );
  }

  static ReaderLineResolvedPage? _nextPageFor({
    required ReaderLineChapterWindowItem center,
    required ReaderLineChapterWindowItem? nextChapter,
    required int pageIndex,
  }) {
    final pages = center.layout.pages;
    if (pageIndex + 1 < pages.length) {
      return ReaderLineResolvedPage(
        chapter: center.chapter,
        page: pages[pageIndex + 1],
      );
    }
    if (nextChapter == null || nextChapter.layout.pages.isEmpty) {
      return null;
    }
    return ReaderLineResolvedPage(
      chapter: nextChapter.chapter,
      page: nextChapter.layout.pages.first,
    );
  }

  static int _clampedPageIndex({
    required List<ReaderPageLayout> pages,
    required int pageIndex,
  }) {
    if (pages.isEmpty) return 0;
    return pageIndex.clamp(0, pages.length - 1);
  }
}
