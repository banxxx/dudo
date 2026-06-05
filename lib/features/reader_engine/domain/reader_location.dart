class ReaderLocation implements Comparable<ReaderLocation> {
  const ReaderLocation({
    required this.bookId,
    required this.chapterIndex,
    required this.offset,
    this.blockId,
    this.epubHref,
    this.epubCfi,
  });

  factory ReaderLocation.startOfChapter({
    required String bookId,
    required int chapterIndex,
  }) {
    return ReaderLocation(
      bookId: bookId,
      chapterIndex: chapterIndex,
      offset: 0,
    );
  }

  final String bookId;
  final int chapterIndex;
  final int offset;
  final String? blockId;
  final String? epubHref;
  final String? epubCfi;

  ReaderLocation copyWith({
    String? bookId,
    int? chapterIndex,
    int? offset,
    String? blockId,
    String? epubHref,
    String? epubCfi,
  }) {
    return ReaderLocation(
      bookId: bookId ?? this.bookId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      offset: offset ?? this.offset,
      blockId: blockId ?? this.blockId,
      epubHref: epubHref ?? this.epubHref,
      epubCfi: epubCfi ?? this.epubCfi,
    );
  }

  ReaderLocation clamp({
    int? chapterCount,
    int? maxOffset,
  }) {
    final clampedChapterIndex = switch (chapterCount) {
      null => chapterIndex < 0 ? 0 : chapterIndex,
      <= 0 => 0,
      final count => chapterIndex.clamp(0, count - 1),
    };
    final clampedOffset = switch (maxOffset) {
      null => offset < 0 ? 0 : offset,
      < 0 => 0,
      final length => offset.clamp(0, length),
    };

    return copyWith(
      chapterIndex: clampedChapterIndex,
      offset: clampedOffset,
    );
  }

  bool isSameChapter(ReaderLocation other) {
    return bookId == other.bookId && chapterIndex == other.chapterIndex;
  }

  @override
  int compareTo(ReaderLocation other) {
    if (bookId != other.bookId) {
      throw ArgumentError('Cannot compare locations from different books.');
    }
    final chapterCompare = chapterIndex.compareTo(other.chapterIndex);
    if (chapterCompare != 0) return chapterCompare;
    return offset.compareTo(other.offset);
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderLocation &&
        other.bookId == bookId &&
        other.chapterIndex == chapterIndex &&
        other.offset == offset &&
        other.blockId == blockId &&
        other.epubHref == epubHref &&
        other.epubCfi == epubCfi;
  }

  @override
  int get hashCode => Object.hash(
        bookId,
        chapterIndex,
        offset,
        blockId,
        epubHref,
        epubCfi,
      );
}
