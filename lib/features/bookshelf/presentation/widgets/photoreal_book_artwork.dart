import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/http_client.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../domain/book_cover_style.dart';
import 'book_mockup_composer.dart';

/// A photoreal book rendered from a pre-rendered hardcover shell.
///
/// The cover, its printed type and the spine tint are composited once into a
/// device-resolution bitmap and cached, so this widget paints a single image
/// per frame. While the first composite is running a neutral book block holds
/// the hero's layout; [fallback] is only shown if compositing fails.
class PhotorealBookArtwork extends StatefulWidget {
  const PhotorealBookArtwork({
    super.key,
    required this.width,
    required this.height,
    required this.title,
    required this.spineColor,
    this.spineWidth = CoverSpineWidth.standard,
    this.author,
    this.coverPath,
    this.coverUrl,
    this.pendingBytes,
    this.showSpineText = true,
    this.showCoverType = true,
    this.fallback,
  });

  final double width;
  final double height;
  final String title;
  final String? author;
  final String? coverPath;

  /// Remote artwork. Downloaded once per URL and kept in a small in-memory
  /// cache, so books imported from a source render on the same shell.
  final String? coverUrl;
  final Uint8List? pendingBytes;
  final Color spineColor;
  final CoverSpineWidth spineWidth;

  /// Spine lettering, set by the book's cover style.
  final bool showSpineText;

  /// The printed title lockup over the artwork. Off for covers that already
  /// carry their own lettering, including the app's generated paper cover.
  final bool showCoverType;
  final Widget? fallback;

  @override
  State<PhotorealBookArtwork> createState() => _PhotorealBookArtworkState();
}

class _PhotorealBookArtworkState extends State<PhotorealBookArtwork> {
  ui.Image? _image;
  String? _renderingKey;

  /// Cache key of the composite currently being rasterised. Parent rebuilds
  /// must not start a second one: the newer run would cancel the older and pay
  /// for both.
  String? _inFlightKey;
  int _renderToken = 0;
  double _devicePixelRatio = 1;

  /// Set when the cover cannot be composited, so the caller's fallback (a
  /// fully drawn book) takes over instead of leaving a blank placeholder.
  bool _failed = false;

  /// True once the composite has faded in, after which the placeholder is
  /// dropped from the tree.
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    _ensureRendered();
  }

  @override
  void didUpdateWidget(covariant PhotorealBookArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureRendered();
  }

  String _cacheKey() {
    final bytes = widget.pendingBytes;
    return [
      widget.coverPath ?? '',
      widget.coverUrl?.trim() ?? '',
      bytes == null ? '' : '${identityHashCode(bytes)}:${bytes.length}',
      widget.spineColor.toARGB32(),
      widget.spineWidth.storageValue,
      widget.width.toStringAsFixed(1),
      widget.height.toStringAsFixed(1),
      _devicePixelRatio.toStringAsFixed(2),
      widget.title,
      widget.author ?? '',
      widget.showSpineText ? '1' : '0',
      widget.showCoverType ? '1' : '0',
      // The generated paper cover is palette-driven.
      DudoColors.surfaceHigh.toARGB32(),
    ].join('|');
  }

  Future<void> _ensureRendered() async {
    final key = _cacheKey();
    // Same inputs and the work is done (or already failed for these inputs):
    // do not redo it just because the page rebuilt.
    if (key == _renderingKey && (_image != null || _failed)) return;
    if (key == _inFlightKey) return;

    final cached = BookMockupCache.get(key);
    if (cached != null) {
      if (mounted && _image != cached) {
        setState(() => _image = cached);
      }
      _renderingKey = key;
      return;
    }

    final token = ++_renderToken;
    _renderingKey = key;
    _inFlightKey = key;
    // A book without artwork still composes: the composer paints the app's
    // generated paper cover, so every book gets the same photographic shell.
    final cover = await _decodeCover();
    if (!mounted || token != _renderToken) {
      if (_inFlightKey == key) _inFlightKey = null;
      cover?.dispose();
      return;
    }

    try {
      final image = await BookMockupComposer.compose(
        stageSize: Size(widget.width, widget.height),
        devicePixelRatio: _devicePixelRatio,
        cover: cover,
        spineColor: widget.spineColor,
        spineWidth: widget.spineWidth,
        title: widget.title,
        author: widget.author,
        showCoverType: widget.showCoverType,
      );
      if (!mounted || token != _renderToken) {
        image.dispose();
        return;
      }
      BookMockupCache.put(key, image);
      setState(() {
        _image = image;
        _failed = false;
      });
    } catch (_) {
      // Keep the fallback; a failed composite must never break the page.
      if (mounted && token == _renderToken) {
        setState(() => _failed = true);
      }
    } finally {
      if (_inFlightKey == key) _inFlightKey = null;
      cover?.dispose();
    }
  }

  /// Artwork bytes, in priority order: the editor's pending crop, the saved
  /// local cover, then the remote cover. Null means "paint the generated
  /// paper cover".
  Future<Uint8List?> _coverBytes() async {
    final pending = widget.pendingBytes;
    if (pending != null) return pending;

    final path = widget.coverPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) return file.readAsBytes();
    }

    final url = widget.coverUrl?.trim();
    if (url == null || url.isEmpty) return null;
    return _RemoteCoverBytes.load(url);
  }

  Future<ui.Image?> _decodeCover() async {
    try {
      final bytes = await _coverBytes();
      if (bytes == null) return null;
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 900);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageSize = Size(widget.width, widget.height);
    final placeholder = _failed
        ? widget.fallback
        : _PendingBook(
            stageSize: stageSize,
            spineColor: widget.spineColor,
            spineWidth: widget.spineWidth,
          );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The neutral block stays under the composite until it has faded in,
          // so there is no gap between placeholder and artwork.
          if (_image == null || !_revealed)
            placeholder ?? const SizedBox.shrink(),
          if (_image != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              onEnd: () {
                if (mounted && !_revealed) {
                  setState(() => _revealed = true);
                }
              },
              builder: (context, opacity, child) =>
                  Opacity(opacity: opacity, child: child),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RawImage(
                    image: _image,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                  CustomPaint(
                    painter: BookMockupSpineTypePainter(
                      stageSize: stageSize,
                      title: widget.title,
                      author: widget.author,
                      spineColor: widget.spineColor,
                      spineWidth: widget.spineWidth,
                      showText: widget.showSpineText,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Neutral book-shaped block shown while the cover composites.
///
/// It is drawn on the shell's own projected silhouette and washed with the
/// spine colour, so the hero holds its final position and outline instead of
/// flashing a fully drawn fallback book.
class _PendingBook extends StatelessWidget {
  const _PendingBook({
    required this.stageSize,
    required this.spineColor,
    required this.spineWidth,
  });

  final Size stageSize;
  final Color spineColor;
  final CoverSpineWidth spineWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PendingBookPainter(
        stageSize: stageSize,
        spineColor: spineColor,
        spineWidth: spineWidth,
        surface: DudoColors.surface,
        outline: DudoColors.outline,
      ),
    );
  }
}

/// Small LRU of downloaded cover bytes, so reopening a book does not hit the
/// network again; the composited image is cached separately.
class _RemoteCoverBytes {
  const _RemoteCoverBytes._();

  static const int _maxEntries = 8;
  static final Map<String, Uint8List> _bytes = {};
  static final List<String> _order = [];

  static Future<Uint8List?> load(String url) async {
    final cached = _bytes[url];
    if (cached != null) return cached;
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

class _PendingBookPainter extends CustomPainter {
  const _PendingBookPainter({
    required this.stageSize,
    required this.spineColor,
    required this.spineWidth,
    required this.surface,
    required this.outline,
  });

  final Size stageSize;
  final Color spineColor;
  final CoverSpineWidth spineWidth;
  final Color surface;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final spine = BookMockupGeometry.spineQuadFor(stageSize, spineWidth);
    final cover = BookMockupGeometry.coverQuadFor(stageSize, spineWidth);
    // Exactly the shell's silhouette, so the block does not peek out around the
    // composite while it fades in.
    final silhouette = Path()
      ..addPolygon([
        spine[0],
        cover[0],
        cover[1],
        cover[2],
        cover[3],
        spine[3],
      ], true);
    canvas.drawPath(silhouette, Paint()..color = surface);

    // A wash of the chosen spine colour hints at the binding without
    // pretending to be the artwork.
    canvas.drawPath(
      Path()..addPolygon(spine, true),
      Paint()..color = spineColor.withValues(alpha: 0.09),
    );

    canvas.drawPath(
      silhouette,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outline.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_PendingBookPainter oldDelegate) {
    return oldDelegate.stageSize != stageSize ||
        oldDelegate.spineColor != spineColor ||
        oldDelegate.spineWidth != spineWidth ||
        oldDelegate.surface != surface ||
        oldDelegate.outline != outline;
  }
}
