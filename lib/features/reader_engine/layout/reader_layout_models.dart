import '../domain/reader_content_block.dart';
import '../domain/reader_location.dart';
import 'reader_line_layout_models.dart';

class ReaderLayoutRevision {
  const ReaderLayoutRevision({
    required this.contentHash,
    required this.settingsDigest,
  });

  final int contentHash;
  final String settingsDigest;
}

class ReaderChapterLayout {
  const ReaderChapterLayout({
    required this.chapterIndex,
    required this.revision,
    required this.contentHeight,
    required this.blockLayouts,
    required this.pages,
  });

  final int chapterIndex;
  final ReaderLayoutRevision revision;
  final double contentHeight;
  final List<ReaderBlockLayout> blockLayouts;
  final List<ReaderPageSlice> pages;
}

class ReaderBlockLayout {
  const ReaderBlockLayout({
    required this.blockId,
    required this.chapterIndex,
    required this.textStartOffset,
    required this.textEndOffset,
    required this.scrollStart,
    required this.scrollEnd,
    required this.pageIndex,
  });

  final String blockId;
  final int chapterIndex;
  final int textStartOffset;
  final int textEndOffset;
  final double scrollStart;
  final double scrollEnd;
  final int pageIndex;

  bool containsOffset(int offset) {
    return offset >= textStartOffset && offset <= textEndOffset;
  }

  bool containsScrollOffset(double scrollOffset) {
    return scrollOffset >= scrollStart && scrollOffset <= scrollEnd;
  }
}

class ReaderPageSlice {
  const ReaderPageSlice({
    required this.chapterIndex,
    required this.pageIndex,
    required this.start,
    required this.end,
    required this.blocks,
    this.lineLayout,
  });

  final int chapterIndex;
  final int pageIndex;
  final ReaderLocation start;
  final ReaderLocation end;
  final List<ReaderContentBlock> blocks;
  final ReaderPageLayout? lineLayout;
}
