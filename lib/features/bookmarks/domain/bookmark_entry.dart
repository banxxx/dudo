enum BookmarkEntryType {
  bookmark,
  highlight,
  note;

  String get label {
    switch (this) {
      case BookmarkEntryType.bookmark:
        return '书签';
      case BookmarkEntryType.highlight:
        return '高亮';
      case BookmarkEntryType.note:
        return '笔记';
    }
  }
}

/// A bookmark, highlight, or note as shown on the bookmarks screen.
class BookmarkEntry {
  const BookmarkEntry({
    required this.id,
    required this.type,
    required this.bookId,
    required this.bookTitle,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.offset,
    required this.preview,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final BookmarkEntryType type;
  final String bookId;
  final String bookTitle;
  final int chapterIndex;
  final String chapterTitle;

  /// Character offset of the mark inside its chapter.
  final int offset;
  final String preview;
  final String? note;
  final DateTime createdAt;

  String get chapterLabel =>
      chapterTitle.trim().isEmpty ? '第 ${chapterIndex + 1} 章' : chapterTitle;

  String get excerpt {
    final text = preview.trim();
    if (text.isNotEmpty) return text;
    return note?.trim() ?? '';
  }
}
