import 'package:dudo/features/reader_engine/domain/reader_chapter.dart';
import 'package:dudo/features/reader_engine/domain/reader_location.dart';
import 'package:dudo/features/reader_engine/domain/reader_viewport_state.dart';
import 'package:dudo/features/reader_engine/layout/reader_layout_models.dart';
import 'package:dudo/features/reader_engine/presentation/modes/reader_paged_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves current page from viewport location', () {
    final center = _item(1, pageCount: 3);
    final window = ReaderPagedWindow.fromViewport(
      ReaderViewportState(
        center: center,
        currentLocation: const ReaderLocation(
          bookId: 'book-1',
          chapterIndex: 1,
          offset: 12,
        ),
        currentLayout: center.layout,
      ),
    );

    expect(window.current.chapterIndex, 1);
    expect(window.current.pageIndex, 1);
    expect(window.previous!.pageIndex, 0);
    expect(window.next!.pageIndex, 2);
  });

  test('resolves adjacent pages across chapter boundaries', () {
    final previous = _item(0, pageCount: 2);
    final center = _item(1, pageCount: 2);
    final next = _item(2, pageCount: 2);

    final firstPageWindow = ReaderPagedWindow.fromViewport(
      ReaderViewportState(
        center: center,
        currentLocation: ReaderLocation.startOfChapter(
          bookId: 'book-1',
          chapterIndex: 1,
        ),
        currentLayout: center.layout,
        previous: previous,
        next: next,
      ),
      pageIndex: 0,
    );
    expect(firstPageWindow.previous!.chapterIndex, 0);
    expect(firstPageWindow.previous!.pageIndex, 1);
    expect(firstPageWindow.next!.chapterIndex, 1);
    expect(firstPageWindow.next!.pageIndex, 1);

    final lastPageWindow = ReaderPagedWindow.fromViewport(
      ReaderViewportState(
        center: center,
        currentLocation: ReaderLocation.startOfChapter(
          bookId: 'book-1',
          chapterIndex: 1,
        ),
        currentLayout: center.layout,
        previous: previous,
        next: next,
      ),
      pageIndex: 1,
    );
    expect(lastPageWindow.previous!.chapterIndex, 1);
    expect(lastPageWindow.previous!.pageIndex, 0);
    expect(lastPageWindow.next!.chapterIndex, 2);
    expect(lastPageWindow.next!.pageIndex, 0);
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
