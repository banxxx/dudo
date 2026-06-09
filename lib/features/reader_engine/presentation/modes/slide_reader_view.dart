import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/reader_theme.dart';
import '../../domain/reader_location.dart';
import '../../domain/reader_settings.dart';
import '../../domain/reader_viewport_state.dart';
import 'reader_page_slice_canvas_surface.dart';
import 'reader_paged_window.dart';

class SlideReaderView extends StatefulWidget {
  const SlideReaderView({
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
  State<SlideReaderView> createState() => _SlideReaderViewState();
}

class _SlideReaderViewState extends State<SlideReaderView>
    with SingleTickerProviderStateMixin {
  static const double _minDragCommitRatio = 0.22;
  static const double _minFlingVelocity = 450;

  late final AnimationController _controller;
  Animation<double>? _offsetAnimation;

  int? _pageIndex;
  double _dragOffset = 0;
  double _viewportWidth = 1;
  ReaderResolvedPage? _transitionTarget;
  ReaderResolvedPage? _committedTarget;
  int? _committingDirection;
  int _handledExternalPageTurnRequestId = 0;
  int _animationGeneration = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didUpdateWidget(covariant SlideReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final committedTarget = _committedTarget;
    if (committedTarget != null) {
      if (committedTarget.chapterIndex ==
          widget.viewport.center.chapter.index) {
        _committedTarget = null;
        _pageIndex = null;
        _resetTransitionState(stopAnimation: true);
      }
      return;
    }
    if (oldWidget.viewport.center.chapter.index !=
            widget.viewport.center.chapter.index ||
        oldWidget.viewport.currentLocation != widget.viewport.currentLocation) {
      _pageIndex = null;
      _resetTransitionState(stopAnimation: true);
    }
    _handleExternalPageTurnIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleExternalPageTurnIfNeeded();
  }

  @override
  void dispose() {
    _offsetAnimation?.removeListener(_handleAnimatedOffset);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = ReaderPagedWindow.fromViewport(
          widget.viewport,
          pageIndex: _pageIndex,
        );
        final width = math.max(1.0, constraints.maxWidth);
        _viewportWidth = width;
        final committedTarget = _committedTarget;
        if (committedTarget != null) {
          return _SlideGestureShell(
            onTapUp: _handleTap,
            onHorizontalDragUpdate:
                widget.controlsVisible ? null : _handleHorizontalDragUpdate,
            onHorizontalDragEnd:
                widget.controlsVisible ? null : _handleHorizontalDragEnd,
            onHorizontalDragCancel:
                widget.controlsVisible ? null : _animateBackToRest,
            child: ReaderPageSliceCanvasSurface(
              key: ValueKey(
                'reader-engine-slide-committed-'
                '${committedTarget.chapterIndex}-${committedTarget.pageIndex}',
              ),
              resolvedPage: committedTarget,
              settings: widget.settings,
              palette: widget.palette,
            ),
          );
        }
        final direction = _directionForOffset(_dragOffset);
        final target = _transitionTarget ?? window.pageForDirection(direction);
        final visibleOffset = target == null
            ? _dragOffset * 0.28
            : _dragOffset.clamp(-width, width);

        return _SlideGestureShell(
          onTapUp: _handleTap,
          onHorizontalDragUpdate:
              widget.controlsVisible ? null : _handleHorizontalDragUpdate,
          onHorizontalDragEnd:
              widget.controlsVisible ? null : _handleHorizontalDragEnd,
          onHorizontalDragCancel:
              widget.controlsVisible ? null : _animateBackToRest,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (target != null && direction != 0)
                _TranslatedPage(
                  offset: Offset(
                    direction > 0
                        ? width + visibleOffset
                        : -width + visibleOffset,
                    0,
                  ),
                  child: ReaderPageSliceCanvasSurface(
                    key: ValueKey(
                      'reader-engine-slide-target-'
                      '${target.chapterIndex}-${target.pageIndex}',
                    ),
                    resolvedPage: target,
                    settings: widget.settings,
                    palette: widget.palette,
                  ),
                ),
              _TranslatedPage(
                offset: Offset(visibleOffset, 0),
                child: ReaderPageSliceCanvasSurface(
                  key: ValueKey(
                    'reader-engine-slide-current-'
                    '${window.current.chapterIndex}-'
                    '${window.current.pageIndex}',
                  ),
                  resolvedPage: window.current,
                  settings: widget.settings,
                  palette: widget.palette,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleTap(Offset position) {
    final width = _viewportWidth;
    if (widget.controlsVisible || width == 0) {
      widget.onContentTap();
      return;
    }

    if (position.dx < width * 0.33) {
      if (!_finishActivePageTurnIfNeeded()) return;
      _turnPage(-1);
      return;
    }
    if (position.dx > width * 0.67) {
      if (!_finishActivePageTurnIfNeeded()) return;
      _turnPage(1);
      return;
    }
    widget.onContentTap();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) return;
    final width = _viewportWidth;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(-width, width);
      _transitionTarget = null;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset == 0) return;
    final width = _viewportWidth;
    final velocity = details.primaryVelocity ?? 0;
    final direction = _directionForOffset(_dragOffset);
    final shouldCommit = _dragOffset.abs() >= width * _minDragCommitRatio ||
        velocity.abs() >= _minFlingVelocity;

    if (!shouldCommit || direction == 0) {
      _animateBackToRest();
      return;
    }
    _turnPage(direction, fromOffset: _dragOffset);
  }

  void _turnPage(int direction, {double? fromOffset}) {
    final window = ReaderPagedWindow.fromViewport(
      widget.viewport,
      pageIndex: _pageIndex,
    );
    final target = window.pageForDirection(direction);
    if (target == null) {
      _resetTransitionState();
      if (direction < 0) {
        widget.onPreviousBoundary();
      } else {
        widget.onNextBoundary();
      }
      return;
    }

    final width = _viewportWidth;
    _transitionTarget = target;
    _committingDirection = direction;
    _animateOffset(
      from: fromOffset ?? 0,
      to: direction > 0 ? -width : width,
    );
  }

  void _animateBackToRest() {
    if (_dragOffset == 0) return;
    _committingDirection = null;
    _animateOffset(from: _dragOffset, to: 0);
  }

  void _animateOffset({
    required double from,
    required double to,
  }) {
    _offsetAnimation?.removeListener(_handleAnimatedOffset);
    _controller.stop();
    final generation = ++_animationGeneration;
    _controller.reset();
    _dragOffset = from;
    _offsetAnimation = Tween<double>(begin: from, end: to)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_controller)
      ..addListener(_handleAnimatedOffset);
    _controller.forward().whenComplete(() => _completeAnimation(generation));
  }

  void _handleAnimatedOffset() {
    if (!mounted || _offsetAnimation == null) return;
    setState(() => _dragOffset = _offsetAnimation!.value);
  }

  void _completeAnimation(int generation) {
    if (!mounted || generation != _animationGeneration) return;
    final target = _transitionTarget;
    final direction = _committingDirection;
    if (target != null && direction != null) {
      if (target.chapterIndex == widget.viewport.center.chapter.index) {
        _pageIndex = target.pageIndex;
      } else {
        _committedTarget = target;
      }
      widget.onLocationChanged(target.page.start);
    }
    setState(() => _resetTransitionState());
  }

  bool _finishActivePageTurnIfNeeded() {
    if (!_controller.isAnimating && _committingDirection == null) {
      return _committedTarget == null;
    }

    _animationGeneration++;
    _controller.stop();
    final target = _transitionTarget;
    final direction = _committingDirection;
    if (target != null && direction != null) {
      if (target.chapterIndex == widget.viewport.center.chapter.index) {
        _pageIndex = target.pageIndex;
      } else {
        _committedTarget = target;
      }
      widget.onLocationChanged(target.page.start);
    }
    setState(() => _resetTransitionState());
    return _committedTarget == null;
  }

  void _resetTransitionState({bool stopAnimation = false}) {
    if (stopAnimation) {
      _animationGeneration++;
      _controller.stop();
    }
    _offsetAnimation?.removeListener(_handleAnimatedOffset);
    _offsetAnimation = null;
    _dragOffset = 0;
    _transitionTarget = null;
    _committingDirection = null;
  }

  int _directionForOffset(double offset) {
    if (offset < 0) return 1;
    if (offset > 0) return -1;
    return 0;
  }

  void _handleExternalPageTurnIfNeeded() {
    final requestId = widget.externalPageTurnRequestId;
    final direction = widget.externalPageTurnDirection;
    if (requestId == 0 ||
        requestId == _handledExternalPageTurnRequestId ||
        direction == 0 ||
        widget.controlsVisible ||
        _committedTarget != null) {
      return;
    }
    _handledExternalPageTurnRequestId = requestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_finishActivePageTurnIfNeeded()) return;
      _turnPage(direction);
    });
  }
}

class _SlideGestureShell extends StatelessWidget {
  const _SlideGestureShell({
    required this.onTapUp,
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
    required this.onHorizontalDragCancel,
    required this.child,
  });

  final ValueChanged<Offset> onTapUp;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;
  final GestureDragCancelCallback? onHorizontalDragCancel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GestureDetector(
        key: const ValueKey('reader-engine-slide-view'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => onTapUp(details.localPosition),
        onHorizontalDragUpdate: onHorizontalDragUpdate,
        onHorizontalDragEnd: onHorizontalDragEnd,
        onHorizontalDragCancel: onHorizontalDragCancel,
        child: ClipRect(child: child),
      ),
    );
  }
}

class _TranslatedPage extends StatelessWidget {
  const _TranslatedPage({
    required this.offset,
    required this.child,
  });

  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: SizedBox.expand(child: child),
    );
  }
}
