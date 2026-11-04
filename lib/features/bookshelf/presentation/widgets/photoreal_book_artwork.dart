import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_tokens.dart';
import '../../data/book_mockup_cache.dart';
import '../../domain/book_cover_style.dart';
import 'book_artwork_renderer.dart';
import 'book_mockup_composer.dart';

/// A photoreal book rendered from a pre-rendered hardcover shell.
///
/// The cover, its printed type and the spine tint are composited once into a
/// device-resolution bitmap and cached, so this widget paints a single image
/// per frame. While the first composite is running, the book's own artwork is
/// warped onto the shell's cover face, so the hero holds its colours instead
/// of flashing a white block; [fallback] is only shown if compositing fails.
class PhotorealBookArtwork extends StatefulWidget {
  const PhotorealBookArtwork({
    super.key,
    required this.spec,
    this.fallback,
  });

  final BookArtworkSpec spec;
  final Widget? fallback;

  @override
  State<PhotorealBookArtwork> createState() => _PhotorealBookArtworkState();
}

class _PhotorealBookArtworkState extends State<PhotorealBookArtwork> {
  BookMockupEntry? _entry;

  /// Low-resolution artwork drawn on the cover face until the composite (and
  /// the spine colour sampled from it) is ready.
  ui.Image? _preview;

  /// Cache key of the composite currently being rasterised. Parent rebuilds
  /// must not start a second one: the newer run would cancel the older and pay
  /// for both.
  String? _renderingKey;
  String? _inFlightKey;
  int _renderToken = 0;

  /// Set when the cover cannot be composited, so the caller's fallback (a
  /// fully drawn book) takes over instead of leaving a blank placeholder.
  bool _failed = false;

  /// True once the composite has faded in, after which the placeholder is
  /// dropped from the tree.
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureRendered();
  }

  @override
  void didUpdateWidget(covariant PhotorealBookArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureRendered();
  }

  @override
  void dispose() {
    _preview?.dispose();
    super.dispose();
  }

  Future<void> _ensureRendered() async {
    final spec = widget.spec;
    final key = spec.cacheKey;
    // Same inputs and the work is done (or already failed for these inputs):
    // do not redo it just because the page rebuilt.
    if (key == _renderingKey && (_entry != null || _failed)) return;
    if (key == _inFlightKey) return;

    final cached = BookMockupCache.get(key);
    if (cached != null) {
      _renderingKey = key;
      if (mounted) {
        setState(() {
          _entry = cached;
          _failed = false;
          // The bitmap is already finished, so paint it on the first frame
          // rather than fading it over the placeholder.
          _revealed = true;
        });
      }
      return;
    }

    _renderingKey = key;
    _inFlightKey = key;
    final token = ++_renderToken;
    _dropPreview();

    // The preview only paints the cover face; it is much cheaper than the
    // shell composite and can land while that is still running.
    unawaited(_loadPreview(spec, token));

    final entry = await BookArtworkRenderer.render(spec);
    if (!mounted || token != _renderToken) {
      if (_inFlightKey == key) _inFlightKey = null;
      return;
    }
    if (_inFlightKey == key) _inFlightKey = null;
    if (entry == null) {
      setState(() => _failed = true);
    } else {
      setState(() {
        _entry = entry;
        _failed = false;
      });
    }
  }

  Future<void> _loadPreview(BookArtworkSpec spec, int token) async {
    try {
      final bytes = await BookArtworkRenderer.readCoverBytes(spec);
      if (bytes == null || !mounted || token != _renderToken) return;
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 450);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted || token != _renderToken || _entry != null) {
        frame.image.dispose();
        return;
      }
      setState(() => _preview = frame.image);
    } catch (_) {
      // No preview: the neutral surface stays until the composite arrives.
    }
  }

  void _dropPreview() {
    final preview = _preview;
    _preview = null;
    if (preview != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => preview.dispose());
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final stageSize = Size(spec.width, spec.height);
    final entry = _entry;

    final artwork = entry == null
        ? null
        : Stack(
            fit: StackFit.expand,
            children: [
              RawImage(
                image: entry.image,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
              CustomPaint(
                painter: BookMockupSpineTypePainter(
                  stageSize: stageSize,
                  title: spec.title,
                  author: spec.author,
                  spineColor: entry.spineColor,
                  spineWidth: spec.spineWidth,
                  showText: spec.showSpineText,
                ),
              ),
            ],
          );

    return SizedBox(
      width: spec.width,
      height: spec.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The placeholder stays under the composite until it has faded in,
          // so there is no gap between the two.
          if (artwork == null || !_revealed)
            _failed
                ? widget.fallback ?? const SizedBox.shrink()
                : _PendingBook(
                    stageSize: stageSize,
                    spineColor: entry?.spineColor ??
                        spec.spineColor ??
                        spec.previewStartColor ??
                        DudoColors.primary,
                    spineWidth: spec.spineWidth,
                    preview: _preview,
                    previewStartColor: spec.previewStartColor,
                    previewEndColor: spec.previewEndColor,
                  ),
          if (artwork != null)
            _revealed
                ? artwork
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: AppMotion.fast,
                    curve: AppMotion.standard,
                    onEnd: () {
                      if (!mounted || _revealed) return;
                      setState(() => _revealed = true);
                      _dropPreview();
                    },
                    builder: (context, opacity, child) =>
                        Opacity(opacity: opacity, child: child),
                    child: artwork,
                  ),
        ],
      ),
    );
  }
}

/// Book-shaped block shown while the cover composites.
///
/// It is drawn on the shell's own projected silhouette, so the hero holds its
/// final position and outline. Once the artwork bytes are decoded, the cover
/// is warped onto the cover face and the spine washed with the chosen colour;
/// the first frame is no longer a blank white block.
class _PendingBook extends StatelessWidget {
  const _PendingBook({
    required this.stageSize,
    required this.spineColor,
    required this.spineWidth,
    this.preview,
    this.previewStartColor,
    this.previewEndColor,
  });

  final Size stageSize;
  final Color spineColor;
  final CoverSpineWidth spineWidth;
  final ui.Image? preview;
  final Color? previewStartColor;
  final Color? previewEndColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PendingBookPainter(
        stageSize: stageSize,
        spineColor: spineColor,
        spineWidth: spineWidth,
        preview: preview,
        previewStartColor: previewStartColor,
        previewEndColor: previewEndColor,
        surface: DudoColors.surface,
        outline: DudoColors.outline,
      ),
    );
  }
}

class _PendingBookPainter extends CustomPainter {
  const _PendingBookPainter({
    required this.stageSize,
    required this.spineColor,
    required this.spineWidth,
    required this.surface,
    required this.outline,
    this.preview,
    this.previewStartColor,
    this.previewEndColor,
  });

  final Size stageSize;
  final Color spineColor;
  final CoverSpineWidth spineWidth;
  final ui.Image? preview;
  final Color? previewStartColor;
  final Color? previewEndColor;
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

    final coverPath = Path()..addPolygon(cover, true);
    final preview = this.preview;
    if (preview != null) {
      const layout = BookMockupGeometry.coverLayout;
      canvas.save();
      canvas.clipPath(coverPath);
      canvas.transform(BookMockupComposer.homography(layout, cover).storage);
      canvas.drawImageRect(
        preview,
        BookMockupComposer.coverSourceRect(preview, layout),
        Offset.zero & layout,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    } else if (previewStartColor != null && previewEndColor != null) {
      // The same generated gradient the shelf card wore, so the hand-off into
      // the detail page starts from a book-coloured face, never a blank one.
      final bounds = coverPath.getBounds();
      canvas.save();
      canvas.clipPath(coverPath);
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = LinearGradient(
            // Matches the direction the shelf card paints.
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [previewStartColor!, previewEndColor!],
          ).createShader(bounds),
      );
      canvas.restore();
    }

    // A wash of the chosen spine colour hints at the binding without
    // pretending to be the artwork. It has to be strong enough to keep the
    // spine from reading as a white board while the cover loads.
    canvas.drawPath(
      Path()..addPolygon(spine, true),
      Paint()..color = spineColor.withValues(alpha: 0.28),
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
        oldDelegate.preview != preview ||
        oldDelegate.previewStartColor != previewStartColor ||
        oldDelegate.previewEndColor != previewEndColor ||
        oldDelegate.surface != surface ||
        oldDelegate.outline != outline;
  }
}
