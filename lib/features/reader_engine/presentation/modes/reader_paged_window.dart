import '../../domain/reader_viewport_state.dart';
import '../../layout/reader_layout_models.dart';
import '../../layout/reader_position_mapper.dart';

class ReaderResolvedPage {
  const ReaderResolvedPage({
    required this.item,
    required this.page,
  });

  final ReaderChapterWindowItem item;
  final ReaderPageSlice page;

  int get chapterIndex => page.chapterIndex;
  int get pageIndex => page.pageIndex;
}

class ReaderPagedWindow {
  const ReaderPagedWindow._({
    required this.current,
    required this.previous,
    required this.next,
  });

  factory ReaderPagedWindow.fromViewport(
    ReaderViewportState viewport, {
    int? pageIndex,
  }) {
    final currentPages = viewport.currentLayout.pages;
    final resolvedPageIndex = _clampedPageIndex(
      pages: currentPages,
      pageIndex: pageIndex ??
          ReaderPositionMapper.pageIndexForLocation(
            layout: viewport.currentLayout,
            location: viewport.currentLocation,
          ),
    );
    final current = ReaderResolvedPage(
      item: viewport.center,
      page: currentPages[resolvedPageIndex],
    );

    return ReaderPagedWindow._(
      current: current,
      previous: _previousPageFor(viewport, resolvedPageIndex),
      next: _nextPageFor(viewport, resolvedPageIndex),
    );
  }

  final ReaderResolvedPage current;
  final ReaderResolvedPage? previous;
  final ReaderResolvedPage? next;

  ReaderResolvedPage? pageForDirection(int direction) {
    if (direction < 0) return previous;
    if (direction > 0) return next;
    return current;
  }

  static ReaderResolvedPage? _previousPageFor(
    ReaderViewportState viewport,
    int pageIndex,
  ) {
    if (pageIndex > 0) {
      return ReaderResolvedPage(
        item: viewport.center,
        page: viewport.currentLayout.pages[pageIndex - 1],
      );
    }

    final previous = viewport.previous;
    if (previous == null || previous.layout.pages.isEmpty) return null;
    return ReaderResolvedPage(
      item: previous,
      page: previous.layout.pages.last,
    );
  }

  static ReaderResolvedPage? _nextPageFor(
    ReaderViewportState viewport,
    int pageIndex,
  ) {
    final pages = viewport.currentLayout.pages;
    if (pageIndex + 1 < pages.length) {
      return ReaderResolvedPage(
        item: viewport.center,
        page: pages[pageIndex + 1],
      );
    }

    final next = viewport.next;
    if (next == null || next.layout.pages.isEmpty) return null;
    return ReaderResolvedPage(
      item: next,
      page: next.layout.pages.first,
    );
  }

  static int _clampedPageIndex({
    required List<ReaderPageSlice> pages,
    required int pageIndex,
  }) {
    if (pages.isEmpty) return 0;
    return pageIndex.clamp(0, pages.length - 1);
  }
}
