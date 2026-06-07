import 'reader_layout_settings.dart';
import 'reader_line_layout_models.dart';

class ReaderLineLayoutCacheKey {
  const ReaderLineLayoutCacheKey({
    required this.bookId,
    required this.chapterIndex,
    required this.contentHash,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.settingsDigest,
  });

  factory ReaderLineLayoutCacheKey.fromSettings({
    required String bookId,
    required int chapterIndex,
    required int contentHash,
    required double viewportWidth,
    required double viewportHeight,
    required ReaderLayoutSettings settings,
  }) {
    return ReaderLineLayoutCacheKey(
      bookId: bookId,
      chapterIndex: chapterIndex,
      contentHash: contentHash,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      settingsDigest: settings.digest,
    );
  }

  final String bookId;
  final int chapterIndex;
  final int contentHash;
  final double viewportWidth;
  final double viewportHeight;
  final String settingsDigest;

  @override
  bool operator ==(Object other) {
    return other is ReaderLineLayoutCacheKey &&
        other.bookId == bookId &&
        other.chapterIndex == chapterIndex &&
        other.contentHash == contentHash &&
        other.viewportWidth == viewportWidth &&
        other.viewportHeight == viewportHeight &&
        other.settingsDigest == settingsDigest;
  }

  @override
  int get hashCode => Object.hash(
        bookId,
        chapterIndex,
        contentHash,
        viewportWidth,
        viewportHeight,
        settingsDigest,
      );
}

class ReaderLineLayoutCache {
  ReaderLineLayoutCache({this.maximumEntries = 16});

  final int maximumEntries;
  final _items = <ReaderLineLayoutCacheKey, ReaderLineChapterLayout>{};

  ReaderLineChapterLayout? get(ReaderLineLayoutCacheKey key) => _items[key];

  void put(ReaderLineLayoutCacheKey key, ReaderLineChapterLayout layout) {
    if (!_items.containsKey(key) && _items.length >= maximumEntries) {
      _items.remove(_items.keys.first);
    }
    _items[key] = layout;
  }

  void clear() => _items.clear();
}
