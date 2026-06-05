import '../layout/reader_layout_models.dart';
import 'reader_chapter.dart';
import 'reader_location.dart';

enum ReaderChapterLoadStatus {
  loaded,
  failed,
}

class ReaderViewportState {
  const ReaderViewportState({
    required this.center,
    required this.currentLocation,
    required this.currentLayout,
    this.previous,
    this.next,
    this.isProgrammaticChange = false,
  });

  final ReaderChapterWindowItem center;
  final ReaderLocation currentLocation;
  final ReaderChapterLayout currentLayout;
  final ReaderChapterWindowItem? previous;
  final ReaderChapterWindowItem? next;
  final bool isProgrammaticChange;
}

class ReaderChapterWindowItem {
  const ReaderChapterWindowItem({
    required this.chapter,
    required this.layout,
    required this.status,
  });

  final ReaderChapter chapter;
  final ReaderChapterLayout layout;
  final ReaderChapterLoadStatus status;
}
