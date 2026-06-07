import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../domain/reader_location.dart';
import '../../domain/reader_settings.dart';
import '../../domain/reader_viewport_state.dart';
import 'reader_page_slice_canvas_surface.dart';
import 'reader_paged_window.dart';

class PagedReaderView extends StatefulWidget {
  const PagedReaderView({
    super.key,
    required this.viewport,
    required this.settings,
    required this.palette,
    required this.controlsVisible,
    this.externalPageTurnRequestId = 0,
    this.externalPageTurnDirection = 0,
    required this.onContentTap,
    required this.onPreviousBoundary,
    required this.onNextBoundary,
    required this.onLocationChanged,
  });

  final ReaderViewportState viewport;
  final ReaderSettings settings;
  final ReaderPalette palette;
  final bool controlsVisible;
  final int externalPageTurnRequestId;
  final int externalPageTurnDirection;
  final VoidCallback onContentTap;
  final VoidCallback onPreviousBoundary;
  final VoidCallback onNextBoundary;
  final ValueChanged<ReaderLocation> onLocationChanged;

  @override
  State<PagedReaderView> createState() => _PagedReaderViewState();
}

class _PagedReaderViewState extends State<PagedReaderView> {
  int? _pageIndex;
  int _handledExternalPageTurnRequestId = 0;

  @override
  void didUpdateWidget(covariant PagedReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewport.center.chapter.index !=
            widget.viewport.center.chapter.index ||
        oldWidget.viewport.currentLocation != widget.viewport.currentLocation) {
      _pageIndex = null;
    }
    _handleExternalPageTurnIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleExternalPageTurnIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final window = ReaderPagedWindow.fromViewport(
      widget.viewport,
      pageIndex: _pageIndex,
    );
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
        child: ReaderPageSliceCanvasSurface(
          resolvedPage: window.current,
          settings: widget.settings,
          palette: widget.palette,
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
    final window = ReaderPagedWindow.fromViewport(
      widget.viewport,
      pageIndex: _pageIndex,
    );
    final target = window.pageForDirection(direction);
    if (target != null) {
      if (target.chapterIndex == widget.viewport.center.chapter.index) {
        setState(() => _pageIndex = target.pageIndex);
      }
      widget.onLocationChanged(target.page.start);
      return;
    }
    if (direction < 0) {
      widget.onPreviousBoundary();
    } else {
      widget.onNextBoundary();
    }
  }

  void _handleExternalPageTurnIfNeeded() {
    final requestId = widget.externalPageTurnRequestId;
    final direction = widget.externalPageTurnDirection;
    if (requestId == 0 ||
        requestId == _handledExternalPageTurnRequestId ||
        direction == 0 ||
        widget.controlsVisible) {
      return;
    }
    _handledExternalPageTurnRequestId = requestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _turnPage(direction);
    });
  }
}
