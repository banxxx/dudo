import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../shared/theme/app_tokens.dart';
import '../../data/cover_image_tools.dart';

/// Shared pinch / pan / rotate crop surface used by both cover editors.
///
/// The image is laid out "cover" style inside the viewport, then translated and
/// scaled. The [RepaintBoundary] wraps only the image layer, so capturing it
/// returns exactly what is visible in the crop frame.
class CoverCropView extends StatefulWidget {
  const CoverCropView({
    super.key,
    required this.bytes,
    required this.aspectRatio,
    required this.controller,
    this.overlayBuilder,
  });

  final Uint8List bytes;
  final double aspectRatio;
  final CoverCropController controller;
  final Widget Function(Size viewport)? overlayBuilder;

  @override
  State<CoverCropView> createState() => CoverCropViewState();
}

class CoverCropViewState extends State<CoverCropView> {
  final GlobalKey _boundaryKey = GlobalKey();
  ui.Image? _image;
  Size? _viewport;
  double _scale = 1;
  Offset _offset = Offset.zero;
  int _quarterTurns = 0;
  double _gestureStartScale = 1;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant CoverCropView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
    if (!identical(oldWidget.bytes, widget.bytes)) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final image = await decodeCoverImage(widget.bytes);
    if (!mounted) {
      image.dispose();
      return;
    }
    _image?.dispose();
    setState(() {
      _image = image;
      _viewport = null;
      _scale = 1;
      _offset = Offset.zero;
    });
    widget.controller.scale.value = 1;
  }

  /// The image is laid out cover-style at exactly the viewport size, so the
  /// crop surface only ever transforms a viewport-sized layer. This keeps
  /// [RenderRepaintBoundary.toImage] reliable even when the source is much
  /// taller than the crop frame.
  Size _baseSize(Size viewport, int turns) => viewport;

  Offset _centeredOffset(Size viewport, Size base) => Offset.zero;

  Offset _clampOffset(Offset offset, Size viewport, Size base, double scale) {
    final minX = viewport.width - base.width * scale;
    final minY = viewport.height - base.height * scale;
    return Offset(
      offset.dx.clamp(math.min(minX, 0), 0),
      offset.dy.clamp(math.min(minY, 0), 0),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _gestureStartScale = _scale;
    _gestureStartOffset = _offset;
    _gestureStartFocal = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final viewport = _viewport;
    if (viewport == null) return;
    final base = _baseSize(viewport, _quarterTurns);
    final newScale = (_gestureStartScale * details.scale).clamp(1.0, 5.0);
    final anchor = (_gestureStartFocal - _gestureStartOffset) /
        _gestureStartScale;
    final target = details.localFocalPoint - anchor * newScale;
    setState(() {
      _scale = newScale;
      _offset = _clampOffset(target, viewport, base, newScale);
    });
    widget.controller.scale.value = newScale;
  }

  void _setScale(double value) {
    final viewport = _viewport;
    if (viewport == null) return;
    final base = _baseSize(viewport, _quarterTurns);
    final newScale = value.clamp(1.0, 5.0);
    final center = viewport.center(Offset.zero);
    final anchor = (center - _offset) / _scale;
    final target = center - anchor * newScale;
    setState(() {
      _scale = newScale;
      _offset = _clampOffset(target, viewport, base, newScale);
    });
    widget.controller.scale.value = newScale;
  }

  void _rotate() {
    final viewport = _viewport;
    final nextTurns = (_quarterTurns + 1) % 4;
    setState(() {
      _quarterTurns = nextTurns;
      if (viewport != null && _image != null) {
        final base = _baseSize(viewport, nextTurns);
        _scale = 1;
        _offset = _centeredOffset(viewport, base);
      }
    });
    widget.controller.scale.value = 1;
    widget.controller.quarterTurns.value = nextTurns;
  }

  void _resetPosition() {
    final viewport = _viewport;
    if (viewport == null || _image == null) return;
    final base = _baseSize(viewport, _quarterTurns);
    setState(() {
      _scale = 1;
      _offset = _centeredOffset(viewport, base);
    });
    widget.controller.scale.value = 1;
  }

  Future<Uint8List> capture() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('The cover crop is not ready yet.');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      throw StateError('Could not encode the cropped cover.');
    }
    return data.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        if (_image == null) {
          return ColoredBox(
            color: const Color(0xFF25251F),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DudoColors.accentSoft,
                ),
              ),
            ),
          );
        }
        final base = _baseSize(viewport, _quarterTurns);
        if (_viewport != viewport) {
          _viewport = viewport;
          _scale = 1;
          _offset = _centeredOffset(viewport, base);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.controller.scale.value = 1;
          });
        } else {
          _offset = _clampOffset(_offset, viewport, base, _scale);
        }

        final matrix = Matrix4.identity()
          ..setEntry(0, 0, _scale)
          ..setEntry(1, 1, _scale)
          ..setTranslationRaw(_offset.dx, _offset.dy, 0);

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: RepaintBoundary(
                key: _boundaryKey,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFF25251F)),
                      Positioned.fill(
                        child: Transform(
                          transform: matrix,
                          alignment: Alignment.topLeft,
                          filterQuality: FilterQuality.medium,
                          child: RotatedBox(
                            quarterTurns: _quarterTurns,
                            child: Image.memory(
                              widget.bytes,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.overlayBuilder != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: widget.overlayBuilder!(viewport),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Lets the editor page drive the crop surface without reaching into its
/// state directly.
class CoverCropController {
  CoverCropViewState? _view;

  final ValueNotifier<double> scale = ValueNotifier(1);
  final ValueNotifier<int> quarterTurns = ValueNotifier(0);

  bool get isAttached => _view != null;

  void _attach(CoverCropViewState view) {
    _view = view;
  }

  void _detach(CoverCropViewState view) {
    if (identical(_view, view)) _view = null;
  }

  void setScale(double value) => _view?._setScale(value);
  void rotate() => _view?._rotate();
  void resetPosition() => _view?._resetPosition();

  Future<Uint8List> capture() async {
    final view = _view;
    if (view == null) {
      throw StateError('The cover crop is not ready yet.');
    }
    return view.capture();
  }

  void dispose() {
    scale.dispose();
    quarterTurns.dispose();
  }
}
