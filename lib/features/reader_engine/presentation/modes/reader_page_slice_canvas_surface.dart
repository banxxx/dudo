import 'package:flutter/widgets.dart';

import '../../domain/reader_theme.dart';
import '../../domain/reader_settings.dart';
import '../../layout/reader_line_layout_models.dart';
import '../widgets/reader_canvas_highlight.dart';
import 'reader_line_page_surface.dart';
import 'reader_page_slice_line_layout.dart';
import 'reader_page_surface.dart';
import 'reader_paged_window.dart';

class ReaderPageSliceCanvasSurface extends StatefulWidget {
  const ReaderPageSliceCanvasSurface({
    super.key,
    required this.resolvedPage,
    required this.settings,
    required this.palette,
    this.highlights = const [],
    this.layoutResolver = const ReaderPageSliceLineLayoutResolver(),
  });

  final ReaderResolvedPage resolvedPage;
  final ReaderSettings settings;
  final ReaderPalette palette;
  final List<ReaderPageHighlight> highlights;
  final ReaderPageSliceLineLayoutResolver layoutResolver;

  @override
  State<ReaderPageSliceCanvasSurface> createState() =>
      _ReaderPageSliceCanvasSurfaceState();
}

class _ReaderPageSliceCanvasSurfaceState
    extends State<ReaderPageSliceCanvasSurface> {
  String? _layoutKey;
  int _generation = 0;
  ReaderPageLayout? _pageLayout;

  @override
  void didUpdateWidget(covariant ReaderPageSliceCanvasSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resolvedPage.page != widget.resolvedPage.page ||
        oldWidget.settings != widget.settings) {
      _layoutKey = null;
      _pageLayout = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );
        if (size.width <= 0 || size.height <= 0) {
          return _fallbackSurface();
        }

        _ensurePageLayout(size);
        final pageLayout = _pageLayout;
        if (pageLayout == null) return _fallbackSurface();
        return ReaderLinePageSurface(
          pageLayout: pageLayout,
          palette: widget.palette,
          highlights: widget.highlights,
        );
      },
    );
  }

  Widget _fallbackSurface() {
    return ReaderPageSurface(
      resolvedPage: widget.resolvedPage,
      settings: widget.settings,
      palette: widget.palette,
    );
  }

  void _ensurePageLayout(Size size) {
    final key = widget.layoutResolver.cacheKeyForPage(
      resolvedPage: widget.resolvedPage,
      settings: widget.settings,
      viewportSize: size,
    );
    if (_layoutKey == key) return;

    _layoutKey = key;
    final cachedPage = widget.layoutResolver.cachedPage(
      resolvedPage: widget.resolvedPage,
      settings: widget.settings,
      viewportSize: size,
    );
    if (cachedPage != null) {
      _pageLayout = cachedPage;
      return;
    }

    _pageLayout = null;
    final generation = ++_generation;
    widget.layoutResolver
        .resolvePage(
      resolvedPage: widget.resolvedPage,
      settings: widget.settings,
      viewportSize: size,
    )
        .then((pageLayout) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _pageLayout = pageLayout;
      });
    });
  }
}
