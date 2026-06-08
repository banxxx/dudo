import '../domain/reader_settings.dart';
import 'reader_layout_models.dart';

class ReaderLayoutCacheKey {
  const ReaderLayoutCacheKey({
    required this.bookId,
    required this.chapterIndex,
    required this.contentHash,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.settingsDigest,
  });

  factory ReaderLayoutCacheKey.fromSettings({
    required String bookId,
    required int chapterIndex,
    required int contentHash,
    required double viewportWidth,
    required double viewportHeight,
    required ReaderSettings settings,
  }) {
    return ReaderLayoutCacheKey(
      bookId: bookId,
      chapterIndex: chapterIndex,
      contentHash: contentHash,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      settingsDigest: [
        settings.paletteId,
        settings.fontFamily,
        settings.fontSize,
        settings.lineHeight,
        settings.turnMode.name,
        settings.paragraphSpacing,
        settings.firstLineIndentEnabled,
        settings.pagePadding.left,
        settings.pagePadding.top,
        settings.pagePadding.right,
        settings.pagePadding.bottom,
      ].join('|'),
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
    return other is ReaderLayoutCacheKey &&
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

class ReaderLayoutCache {
  ReaderLayoutCache({this.maximumEntries = 32});

  final int maximumEntries;
  final _items = <ReaderLayoutCacheKey, ReaderChapterLayout>{};

  ReaderChapterLayout? get(ReaderLayoutCacheKey key) => _items[key];

  void put(ReaderLayoutCacheKey key, ReaderChapterLayout layout) {
    if (!_items.containsKey(key) && _items.length >= maximumEntries) {
      _items.remove(_items.keys.first);
    }
    _items[key] = layout;
  }

  void clear() => _items.clear();
}
