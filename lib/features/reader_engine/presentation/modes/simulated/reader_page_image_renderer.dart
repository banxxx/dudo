import 'dart:ui' as ui;

import '../../../domain/reader_theme.dart';
import '../../../layout/reader_line_layout_models.dart';
import '../../widgets/reader_canvas_page.dart';
import 'page_curl_snapshot.dart';

class ReaderPageImageKey {
  const ReaderPageImageKey({
    required this.bookId,
    required this.chapterIndex,
    required this.pageIndex,
    required this.startOffset,
    required this.endOffset,
    required this.pageWidth,
    required this.pageHeight,
    required this.revisionDigest,
    required this.paletteDigest,
    required this.pixelRatio,
  });

  factory ReaderPageImageKey.fromPageLayout({
    required ReaderPageLayout pageLayout,
    required ReaderPalette palette,
    required double pixelRatio,
  }) {
    return ReaderPageImageKey(
      bookId: pageLayout.start.bookId,
      chapterIndex: pageLayout.chapterIndex,
      pageIndex: pageLayout.pageIndex,
      startOffset: pageLayout.start.offset,
      endOffset: pageLayout.end.offset,
      pageWidth: pageLayout.pageRect.width,
      pageHeight: pageLayout.pageRect.height,
      revisionDigest: [
        pageLayout.pageRect.width,
        pageLayout.pageRect.height,
        pageLayout.contentRect.left,
        pageLayout.contentRect.top,
        pageLayout.contentRect.right,
        pageLayout.contentRect.bottom,
        for (final block in pageLayout.blocks) ...[
          block.blockId,
          block.textRange.startOffset,
          block.textRange.endOffset,
          for (final line in block.lines) ...[
            line.textRange.startOffset,
            line.textRange.endOffset,
            line.x,
            line.y,
            line.width,
            line.height,
            for (final run in line.runs) ...[
              run.textRange.startOffset,
              run.textRange.endOffset,
              run.text,
              run.x,
              run.baseline,
              run.width,
              run.style.fontFamily,
              run.style.fontSize,
              run.style.fontWeight,
              run.style.height,
              run.style.letterSpacing,
            ],
          ],
        ],
      ].join('|'),
      paletteDigest: [
        palette.background.toARGB32(),
        palette.foreground.toARGB32(),
      ].join('|'),
      pixelRatio: pixelRatio,
    );
  }

  final String bookId;
  final int chapterIndex;
  final int pageIndex;
  final int startOffset;
  final int endOffset;
  final double pageWidth;
  final double pageHeight;
  final String revisionDigest;
  final String paletteDigest;
  final double pixelRatio;

  @override
  bool operator ==(Object other) {
    return other is ReaderPageImageKey &&
        other.bookId == bookId &&
        other.chapterIndex == chapterIndex &&
        other.pageIndex == pageIndex &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.pageWidth == pageWidth &&
        other.pageHeight == pageHeight &&
        other.revisionDigest == revisionDigest &&
        other.paletteDigest == paletteDigest &&
        other.pixelRatio == pixelRatio;
  }

  @override
  int get hashCode => Object.hash(
        bookId,
        chapterIndex,
        pageIndex,
        startOffset,
        endOffset,
        pageWidth,
        pageHeight,
        revisionDigest,
        paletteDigest,
        pixelRatio,
      );
}

class ReaderPageImageHandle {
  ReaderPageImageHandle._({
    required this.image,
    required void Function() release,
  }) : _release = release;

  final ui.Image image;
  final void Function() _release;
  bool _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _release();
  }
}

class ReaderPageImageCache {
  ReaderPageImageCache({this.maximumEntries = 3});

  final int maximumEntries;
  final _items = <ReaderPageImageKey, _ReaderPageImageCacheEntry>{};
  bool _disposed = false;

  int get length => _items.length;

  Future<ReaderPageImageHandle> getOrRender({
    required ReaderPageImageKey key,
    required Future<ui.Image> Function() render,
  }) async {
    if (_disposed) {
      throw StateError('ReaderPageImageCache has been disposed.');
    }
    final existing = _items.remove(key);
    if (existing != null && !existing.retired) {
      _items[key] = existing;
      return _retain(key, existing);
    }

    final image = await render();
    if (_disposed) {
      image.dispose();
      throw StateError('ReaderPageImageCache has been disposed.');
    }
    final entry = _ReaderPageImageCacheEntry(image);
    _items[key] = entry;
    _evictIfNeeded();
    return _retain(key, entry);
  }

  ReaderPageImageHandle _retain(
    ReaderPageImageKey key,
    _ReaderPageImageCacheEntry entry,
  ) {
    entry.retainCount += 1;
    return ReaderPageImageHandle._(
      image: entry.image,
      release: () {
        entry.retainCount -= 1;
        if (entry.retired && entry.retainCount <= 0) {
          entry.image.dispose();
          return;
        }
        _evictIfNeeded();
      },
    );
  }

  void clear() {
    for (final entry in _items.values) {
      entry.retired = true;
      if (entry.retainCount <= 0) {
        entry.image.dispose();
      }
    }
    _items.clear();
  }

  void dispose() {
    if (_disposed) return;
    clear();
    _disposed = true;
  }

  void _evictIfNeeded() {
    if (_disposed) return;
    while (_items.length > maximumEntries) {
      MapEntry<ReaderPageImageKey, _ReaderPageImageCacheEntry>? candidate;
      for (final entry in _items.entries) {
        if (entry.value.retainCount <= 0) {
          candidate = entry;
          break;
        }
      }
      if (candidate == null) return;
      final entry = candidate.value;
      _items.remove(candidate.key);
      entry.retired = true;
      entry.image.dispose();
    }
  }
}

class ReaderPageImageRenderer {
  const ReaderPageImageRenderer({
    this.rasterizer = const ReaderPageRasterizer(),
    this.cache,
  });

  final ReaderPageRasterizer rasterizer;
  final ReaderPageImageCache? cache;

  Future<ReaderPageImageHandle> renderPage({
    required ReaderPageLayout pageLayout,
    required ReaderPalette palette,
    required double pixelRatio,
  }) {
    final key = ReaderPageImageKey.fromPageLayout(
      pageLayout: pageLayout,
      palette: palette,
      pixelRatio: pixelRatio,
    );
    final cache = this.cache;
    if (cache == null) {
      return rasterizer
          .renderImage(
            pageLayout: pageLayout,
            palette: palette,
            pixelRatio: pixelRatio,
          )
          .then(
            (image) => ReaderPageImageHandle._(
              image: image,
              release: image.dispose,
            ),
          );
    }
    return cache.getOrRender(
      key: key,
      render: () => rasterizer.renderImage(
        pageLayout: pageLayout,
        palette: palette,
        pixelRatio: pixelRatio,
      ),
    );
  }

  Future<PageCurlSnapshotPair> renderPair({
    required ReaderPageLayout currentPage,
    required ReaderPageLayout targetPage,
    required ReaderPalette palette,
    required double pixelRatio,
  }) async {
    final current = await renderPage(
      pageLayout: currentPage,
      palette: palette,
      pixelRatio: pixelRatio,
    );
    try {
      final target = await renderPage(
        pageLayout: targetPage,
        palette: palette,
        pixelRatio: pixelRatio,
      );
      return PageCurlSnapshotPair(
        current: current.image,
        target: target.image,
        onDispose: () {
          current.release();
          target.release();
        },
      );
    } catch (_) {
      current.release();
      rethrow;
    }
  }
}

class _ReaderPageImageCacheEntry {
  _ReaderPageImageCacheEntry(this.image);

  final ui.Image image;
  int retainCount = 0;
  bool retired = false;
}
