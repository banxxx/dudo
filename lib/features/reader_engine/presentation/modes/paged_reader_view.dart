import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../domain/reader_location.dart';
import '../../domain/reader_settings.dart';
import '../../domain/reader_viewport_state.dart';
import '../widgets/reader_text_layer.dart';

class PagedReaderView extends StatefulWidget {
  const PagedReaderView({
    super.key,
    required this.viewport,
    required this.settings,
    required this.palette,
    required this.controlsVisible,
    required this.onContentTap,
    required this.onPreviousBoundary,
    required this.onNextBoundary,
    required this.onLocationChanged,
  });

  final ReaderViewportState viewport;
  final ReaderSettings settings;
  final ReaderPalette palette;
  final bool controlsVisible;
  final VoidCallback onContentTap;
  final VoidCallback onPreviousBoundary;
  final VoidCallback onNextBoundary;
  final ValueChanged<ReaderLocation> onLocationChanged;

  @override
  State<PagedReaderView> createState() => _PagedReaderViewState();
}

class _PagedReaderViewState extends State<PagedReaderView> {
  var _pageIndex = 0;

  @override
  void didUpdateWidget(covariant PagedReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewport.center.chapter.index !=
        widget.viewport.center.chapter.index) {
      _pageIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.viewport.currentLayout.pages;
    final page = pages[_pageIndex.clamp(0, pages.length - 1)];
    return SizedBox.expand(
      child: GestureDetector(
        key: const ValueKey('reader-engine-paged-view'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _handleTap(details.localPosition),
        onHorizontalDragEnd: widget.controlsVisible
            ? null
            : (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() < 260) return;
                _turnPage(velocity < 0 ? 1 : -1);
              },
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            widget.settings.pagePadding.left,
            widget.settings.pagePadding.top,
            widget.settings.pagePadding.right,
            widget.settings.pagePadding.bottom,
          ),
          child: ReaderTextLayer(
            blocks: page.blocks,
            settings: widget.settings,
            palette: widget.palette,
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset position) {
    final width = context.size?.width ?? 0;
    if (widget.controlsVisible || width == 0) {
      widget.onContentTap();
      return;
    }

    if (position.dx < width * 0.33) {
      _turnPage(-1);
      return;
    }
    if (position.dx > width * 0.67) {
      _turnPage(1);
      return;
    }
    widget.onContentTap();
  }

  void _turnPage(int direction) {
    final pages = widget.viewport.currentLayout.pages;
    final nextPageIndex = _pageIndex + direction;
    if (nextPageIndex >= 0 && nextPageIndex < pages.length) {
      setState(() => _pageIndex = nextPageIndex);
      widget.onLocationChanged(pages[_pageIndex].start);
      return;
    }
    if (direction < 0) {
      widget.onPreviousBoundary();
    } else {
      widget.onNextBoundary();
    }
  }
}
