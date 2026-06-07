import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../domain/reader_location.dart';
import '../../domain/reader_settings.dart';
import '../../domain/reader_viewport_state.dart';
import 'reader_page_surface.dart';
import 'reader_paged_window.dart';

class CoverReaderView extends StatefulWidget {
  const CoverReaderView({
    super.key,
    required this.viewport,
    required this.settings,
    required this.palette,
    this.brightness = 1,
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
  final double brightness;
  final bool controlsVisible;
  final int externalPageTurnRequestId;
  final int externalPageTurnDirection;
  final VoidCallback onContentTap;
  final VoidCallback onPreviousBoundary;
  final VoidCallback onNextBoundary;
  final ValueChanged<ReaderLocation> onLocationChanged;

  @override
  State<CoverReaderView> createState() => _CoverReaderViewState();
}

class _CoverReaderViewState extends State<CoverReaderView>
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void didUpdateWidget(covariant CoverReaderView oldWidget) {
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
          return SizedBox.expand(
            child: GestureDetector(
              key: const ValueKey('reader-engine-cover-view'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _handleTap(details.localPosition),
              onHorizontalDragUpdate:
                  widget.controlsVisible ? null : _handleHorizontalDragUpdate,
              onHorizontalDragEnd:
                  widget.controlsVisible ? null : _handleHorizontalDragEnd,
              onHorizontalDragCancel:
                  widget.controlsVisible ? null : _animateBackToRest,
              child: ClipRect(
                child: ReaderPageSurface(
                  key: ValueKey(
                    'reader-engine-cover-committed-'
                    '${committedTarget.chapterIndex}-'
                    '${committedTarget.pageIndex}',
                  ),
                  resolvedPage: committedTarget,
                  settings: widget.settings,
                  palette: widget.palette,
                ),
              ),
            ),
          );
        }
        final direction = _directionForOffset(_dragOffset);
        final target = _transitionTarget ?? window.pageForDirection(direction);
        final activeOffset = target == null
            ? _dragOffset * 0.22
            : _dragOffset.clamp(-width, width);

        return SizedBox.expand(
          child: GestureDetector(
            key: const ValueKey('reader-engine-cover-view'),
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _handleTap(details.localPosition),
            onHorizontalDragUpdate:
                widget.controlsVisible ? null : _handleHorizontalDragUpdate,
            onHorizontalDragEnd:
                widget.controlsVisible ? null : _handleHorizontalDragEnd,
            onHorizontalDragCancel:
                widget.controlsVisible ? null : _animateBackToRest,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CurrentCoverStack(
                    window: window,
                    target: target,
                    direction: direction,
                    offset: activeOffset,
                    width: width,
                    settings: widget.settings,
                    palette: widget.palette,
                    brightness: widget.brightness,
                  ),
                ],
              ),
            ),
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
      _turnPage(-1);
      return;
    }
    if (position.dx > width * 0.67) {
      _turnPage(1);
      return;
    }
    widget.onContentTap();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) return;
    final width = _viewportWidth;
    final nextOffset = (_dragOffset + details.delta.dx).clamp(-width, width);
    setState(() {
      if (_directionForOffset(nextOffset) != _directionForOffset(_dragOffset)) {
        _transitionTarget = null;
      }
      _dragOffset = nextOffset;
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
    _controller.reset();
    _dragOffset = from;
    _offsetAnimation = Tween<double>(begin: from, end: to)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_controller)
      ..addListener(_handleAnimatedOffset);
    _controller.forward().whenComplete(_completeAnimation);
  }

  void _handleAnimatedOffset() {
    if (!mounted || _offsetAnimation == null) return;
    setState(() => _dragOffset = _offsetAnimation!.value);
  }

  void _completeAnimation() {
    if (!mounted) return;
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

  void _resetTransitionState({bool stopAnimation = false}) {
    if (stopAnimation) {
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
      if (mounted) _turnPage(direction);
    });
  }
}

class _CurrentCoverStack extends StatelessWidget {
  const _CurrentCoverStack({
    required this.window,
    required this.target,
    required this.direction,
    required this.offset,
    required this.width,
    required this.settings,
    required this.palette,
    required this.brightness,
  });

  final ReaderPagedWindow window;
  final ReaderResolvedPage? target;
  final int direction;
  final double offset;
  final double width;
  final ReaderSettings settings;
  final ReaderPalette palette;
  final double brightness;

  @override
  Widget build(BuildContext context) {
    if (target == null || direction == 0) {
      return ReaderPageSurface(
        key: ValueKey(
          'reader-engine-cover-current-'
          '${window.current.chapterIndex}-${window.current.pageIndex}',
        ),
        resolvedPage: window.current,
        settings: settings,
        palette: palette,
      );
    }

    if (direction > 0) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ReaderPageSurface(
            key: ValueKey(
              'reader-engine-cover-target-'
              '${target!.chapterIndex}-${target!.pageIndex}',
            ),
            resolvedPage: target!,
            settings: settings,
            palette: palette,
          ),
          _CoverPage(
            key: const ValueKey('reader-engine-cover-moving-current'),
            offset: Offset(offset, 0),
            palette: palette,
            brightness: brightness,
            child: ReaderPageSurface(
              key: ValueKey(
                'reader-engine-cover-current-'
                '${window.current.chapterIndex}-${window.current.pageIndex}',
              ),
              resolvedPage: window.current,
              settings: settings,
              palette: palette,
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ReaderPageSurface(
          key: ValueKey(
            'reader-engine-cover-current-'
            '${window.current.chapterIndex}-${window.current.pageIndex}',
          ),
          resolvedPage: window.current,
          settings: settings,
          palette: palette,
        ),
        _CoverPage(
          key: const ValueKey('reader-engine-cover-moving-target'),
          offset: Offset(-width + offset, 0),
          palette: palette,
          brightness: brightness,
          child: ReaderPageSurface(
            key: ValueKey(
              'reader-engine-cover-target-'
              '${target!.chapterIndex}-${target!.pageIndex}',
            ),
            resolvedPage: target!,
            settings: settings,
            palette: palette,
          ),
        ),
      ],
    );
  }
}

class _CoverPage extends StatelessWidget {
  const _CoverPage({
    super.key,
    required this.offset,
    required this.palette,
    required this.brightness,
    required this.child,
  });

  final Offset offset;
  final ReaderPalette palette;
  final double brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const shadow = BoxShadow(
      color: Color(0x3325251F),
      blurRadius: 18,
      offset: Offset(8, 0),
    );
    return Transform.translate(
      offset: offset,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [shadow],
        ),
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.background,
                      palette.backgroundEnd ?? palette.background,
                    ],
                  ),
                ),
              ),
              if (brightness < 0.98)
                ColoredBox(
                  color: Colors.black.withValues(
                    alpha: (1 - brightness).clamp(0.0, 0.65),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
