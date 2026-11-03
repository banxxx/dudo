import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/http_client.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../data/book_mockup_cache.dart';
import '../../data/cover_image_tools.dart';
import '../../domain/book_cover_style.dart';
import 'book_cover_palette.dart';
import 'book_mockup_composer.dart';

/// Everything one photoreal book render depends on.
///
/// [spineColor] is null when the reader has not chosen one: the spine then
/// takes the dominant colour of the book's own artwork. Only a book with no
/// cover at all falls back to the palette's default spine.
class BookArtworkSpec {
  const BookArtworkSpec({
    required this.title,
    required this.width,
    required this.height,
    required this.devicePixelRatio,
    this.author,
    this.coverPath,
    this.coverUrl,
    this.pendingBytes,
    this.spineColor,
    this.spineWidth = CoverSpineWidth.standard,
    this.showSpineText = true,
    this.showCoverType = true,
    this.previewStartColor,
    this.previewEndColor,
  });

  /// The detail page hero: a book with reading progress carries a shorter
  /// hero, so the height/width differ by the same rule the page uses.
  factory BookArtworkSpec.bookDetail(
    Book book, {
    required double devicePixelRatio,
    double? width,
    double? height,
  }) {
    final started = book.lastChapterIndex > 0 || book.lastReadPosition > 0;
    final custom = book.customCoverPath;
    final hasCustom = custom != null && custom.isNotEmpty;
    final url = book.coverUrl?.trim();
    final storedColor = book.coverSpineColor;
    // Without a saved cover the shelf paints this book's generated gradient;
    // reuse it for the hero's first frame so the colour carries over.
    final palette = hasCustom ? null : bookCoverPaletteFor(book);
    return BookArtworkSpec(
      title: book.title,
      author: book.author,
      coverPath: hasCustom ? custom : null,
      coverUrl: hasCustom || url == null || url.isEmpty ? null : url,
      spineColor: storedColor == null ? null : Color(storedColor),
      spineWidth: CoverSpineWidth.fromStorage(book.coverSpineWidth),
      showSpineText: book.coverShowText,
      showCoverType: hasCustom && book.coverShowText,
      width: width ?? (started ? 170 : 190),
      height: height ?? (started ? 224 : 250),
      devicePixelRatio: devicePixelRatio,
      previewStartColor: palette?.start,
      previewEndColor: palette?.end,
    );
  }

  final String title;
  final String? author;
  final String? coverPath;
  final String? coverUrl;
  final Uint8List? pendingBytes;

  /// Null means "derive the dominant colour from the cover".
  final Color? spineColor;
  final CoverSpineWidth spineWidth;
  final bool showSpineText;
  final bool showCoverType;
  final double width;
  final double height;
  final double devicePixelRatio;

  /// The shelf gradient this book wears before its cover is ready. Only used
  /// by the placeholder; it never changes the composite.
  final Color? previewStartColor;
  final Color? previewEndColor;

  String get cacheKey {
    final pending = pendingBytes;
    return [
      coverPath ?? '',
      coverUrl?.trim() ?? '',
      pending == null ? '' : '${identityHashCode(pending)}:${pending.length}',
      spineColor?.toARGB32().toString() ?? 'auto',
      spineWidth.storageValue,
      width.toStringAsFixed(1),
      height.toStringAsFixed(1),
      devicePixelRatio.toStringAsFixed(2),
      title,
      author ?? '',
      showSpineText ? '1' : '0',
      showCoverType ? '1' : '0',
      // The generated paper cover and the default spine are palette-driven.
      DudoColors.surfaceHigh.toARGB32(),
      DudoColors.primary.toARGB32(),
    ].join('|');
  }
}

/// Renders composited book covers and deduplicates the work.
///
/// Tapping a shelf tile starts the composite before the detail route builds;
/// the hero then finds the finished bitmap in [BookMockupCache] and paints it
/// on its first frame instead of flashing a blank block. Concurrent requests
/// for the same spec share one run, so prewarming and the page never compose
/// the same book twice.
class BookArtworkRenderer {
  const BookArtworkRenderer._();

  static final Map<String, Future<BookMockupEntry?>> _inFlight = {};

  static Future<BookMockupEntry?> render(BookArtworkSpec spec) {
    final key = spec.cacheKey;
    final cached = BookMockupCache.get(key);
    if (cached != null) return Future.value(cached);

    final running = _inFlight[key];
    if (running != null) return running;

    final future = _render(spec, key);
    _inFlight[key] = future;
    return future.whenComplete(() {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    });
  }

  /// Fire-and-forget warm-up fired at navigation time. It is deliberately
  /// silent: a failure simply leaves the hero to compose on its own.
  static void prewarm(BookArtworkSpec spec) {
    if (BookMockupCache.get(spec.cacheKey) != null) return;
    unawaited(render(spec));
  }

  /// Cover bytes in priority order: the editor's pending crop, the saved
  /// local cover, then the remote cover. Null means "paint the generated
  /// paper cover".
  static Future<Uint8List?> readCoverBytes(BookArtworkSpec spec) async {
    final pending = spec.pendingBytes;
    if (pending != null) return pending;

    final path = spec.coverPath;
    if (path != null && path.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) return await file.readAsBytes();
      } catch (_) {
        // Unreadable file: fall through to the remote artwork.
      }
    }

    final url = spec.coverUrl?.trim();
    if (url == null || url.isEmpty) return null;
    return RemoteCoverBytes.load(url);
  }

  static Future<BookMockupEntry?> _render(
    BookArtworkSpec spec,
    String key,
  ) async {
    final cover = await _decodeCover(spec);
    try {
      final spineColor = spec.spineColor ??
          (cover == null
              ? DudoColors.primary
              : await dominantColorOfImage(cover));
      final image = await BookMockupComposer.compose(
        stageSize: Size(spec.width, spec.height),
        devicePixelRatio: spec.devicePixelRatio,
        cover: cover,
        spineColor: spineColor,
        spineWidth: spec.spineWidth,
        title: spec.title,
        author: spec.author,
        showCoverType: spec.showCoverType,
      );
      final entry = BookMockupEntry(image: image, spineColor: spineColor);
      BookMockupCache.put(key, entry);
      return entry;
    } catch (_) {
      // A failed composite must never break the page; the caller falls back.
      return null;
    } finally {
      cover?.dispose();
    }
  }

  static Future<ui.Image?> _decodeCover(BookArtworkSpec spec) async {
    try {
      final bytes = await readCoverBytes(spec);
      if (bytes == null) return null;
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 900);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }
}

/// Small LRU of downloaded cover bytes, so reopening a book does not hit the
/// network again; the composited image is cached separately.
class RemoteCoverBytes {
  const RemoteCoverBytes._();

  static const int _maxEntries = 8;
  static final Map<String, Uint8List> _bytes = {};
  static final List<String> _order = [];
  static final Map<String, Future<Uint8List?>> _inFlight = {};

  static Future<Uint8List?> load(String url) {
    final cached = _bytes[url];
    if (cached != null) return Future.value(cached);
    final running = _inFlight[url];
    if (running != null) return running;

    final future = _download(url);
    _inFlight[url] = future;
    return future.whenComplete(() => _inFlight.remove(url));
  }

  static Future<Uint8List?> _download(String url) async {
    try {
      final response = await HttpClient.instance.dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final data = response.data;
      if (data == null || data.isEmpty) return null;
      final bytes = data is Uint8List ? data : Uint8List.fromList(data);
      _bytes[url] = bytes;
      _order.add(url);
      while (_order.length > _maxEntries) {
        _bytes.remove(_order.removeAt(0));
      }
      return bytes;
    } catch (_) {
      // Hotlink-protected or offline: compose the generated cover instead.
      return null;
    }
  }
}
