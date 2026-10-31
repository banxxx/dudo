/// A book that has at least one chapter downloaded for offline reading.
class OfflineCacheBook {
  const OfflineCacheBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.chapterCount,
    required this.bytes,
  });

  final String bookId;
  final String title;
  final String? author;
  final int chapterCount;
  final int bytes;
}

/// Everything the 离线缓存 page reports and can clear.
class OfflineCache {
  const OfflineCache({required this.books});

  final List<OfflineCacheBook> books;

  int get bookCount => books.length;

  int get chapterCount => books.fold(0, (sum, book) => sum + book.chapterCount);

  int get totalBytes => books.fold(0, (sum, book) => sum + book.bytes);

  bool get isEmpty => books.isEmpty;
}
