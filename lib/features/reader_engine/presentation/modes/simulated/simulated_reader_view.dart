import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_theme.dart';
import '../../../domain/reader_location.dart';
import '../../../domain/reader_settings.dart';
import '../../../domain/reader_viewport_state.dart';
import '../reader_page_surface.dart';
import '../reader_paged_window.dart';
import 'page_curl_controller.dart';
import 'page_curl_gesture.dart';
import 'page_curl_quality.dart';
import 'page_curl_render_widget.dart';
import 'page_curl_snapshot.dart';

class SimulatedReaderView extends StatefulWidget {
  const SimulatedReaderView({
    super.key,
    required this.viewport,
    required this.settings,
    required this.palette,
    this.brightness = 1,
    required this.controlsVisible,
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
  final VoidCallback onContentTap;
  final VoidCallback onPreviousBoundary;
  final VoidCallback onNextBoundary;
  final ValueChanged<ReaderLocation> onLocationChanged;

  @override
  State<SimulatedReaderView> createState() => _SimulatedReaderViewState();
}

class _SimulatedReaderViewState extends State<SimulatedReaderView>
    with SingleTickerProviderStateMixin {
  static const double _minDragCommitRatio = 0.2;
  static const double _minFlingVelocity = 420;
  static const double _dragExitTolerance = 8;

  final GlobalKey _currentPageKey = GlobalKey();
  final GlobalKey _targetPageKey = GlobalKey();
  final PageCurlSnapshotController _snapshotController =
      const PageCurlSnapshotController();

  late final AnimationController _controller;
  late final PageCurlController _curlController;
  Animation<double>? _offsetAnimation;

  int? _pageIndex;
  double _viewportWidth = 1;
  double _viewportHeight = 1;
  Offset? _dragStart;
  PageCurlDirection? _dragDirection;
  double _dragOffset = 0;
  PageCurlGesture? _gesture;
  ReaderResolvedPage? _transitionTarget;
  int? _committingDirection;
  PageCurlSnapshotPair? _snapshots;
  bool _captureInFlight = false;
  Future<void>? _snapshotCaptureFuture;
  int _turnRequestId = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _curlController = PageCurlController();
  }

  @override
  void didUpdateWidget(covariant SimulatedReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewport.center.chapter.index !=
            widget.viewport.center.chapter.index ||
        oldWidget.viewport.currentLocation != widget.viewport.currentLocation) {
      _pageIndex = null;
      _resetTurnState(stopAnimation: true, disposeSnapshots: true);
    }
  }

  @override
  void dispose() {
    _offsetAnimation?.removeListener(_handleAnimatedOffset);
    _snapshots?.dispose();
    _curlController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final width = math.max(1.0, size.width);
        final height = math.max(1.0, size.height);
        _viewportWidth = width;
        _viewportHeight = height;

        final window = ReaderPagedWindow.fromViewport(
          widget.viewport,
          pageIndex: _pageIndex,
        );
        final target = _transitionTarget ?? window.current;
        final pageColor = _pageColorForBrightness(
          widget.palette.background,
          widget.brightness,
        );
        final gesture = _gesture;
        final snapshots = _snapshots;
        final canPaintCurl = gesture != null &&
            snapshots != null &&
            !_snapshotsDisposed &&
            _curlController.isActive;
        final elasticOffset = gesture != null && _transitionTarget == null
            ? Offset(_dragOffset * 0.18, 0)
            : Offset.zero;

        return SizedBox.expand(
          child: GestureDetector(
            key: const ValueKey('reader-engine-simulated-view'),
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _handleTap(details.localPosition),
            onHorizontalDragStart:
                widget.controlsVisible ? null : _handleHorizontalDragStart,
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
                  RepaintBoundary(
                    key: _targetPageKey,
                    child: ColoredBox(
                      color: pageColor,
                      child: ReaderPageSurface(
                        key: ValueKey(
                          'reader-engine-simulated-under-'
                          '${target.chapterIndex}-${target.pageIndex}',
                        ),
                        resolvedPage: target,
                        settings: widget.settings,
                        palette: widget.palette,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: elasticOffset,
                    child: RepaintBoundary(
                      key: _currentPageKey,
                      child: ColoredBox(
                        color: pageColor,
                        child: ReaderPageSurface(
                          key: ValueKey(
                            'reader-engine-simulated-current-'
                            '${window.current.chapterIndex}-'
                            '${window.current.pageIndex}',
                          ),
                          resolvedPage: window.current,
                          settings: widget.settings,
                          palette: widget.palette,
                        ),
                      ),
                    ),
                  ),
                  if (canPaintCurl)
                    PageCurlRenderWidget(
                      key: const ValueKey('reader-engine-page-curl-painter'),
                      controller: _curlController,
                      snapshots: snapshots,
                      pageColor: pageColor,
                      quality: PageCurlQuality.normal,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool get _snapshotsDisposed => _snapshots?.isDisposed ?? true;

  Color _pageColorForBrightness(Color color, double brightness) {
    final overlayAlpha = (1 - brightness).clamp(0.0, 0.65).toDouble();
    if (overlayAlpha <= 0) return color;
    return Color.alphaBlend(
      Colors.black.withValues(alpha: overlayAlpha),
      color,
    );
  }

  void _handleTap(Offset position) {
    final width = _viewportWidth;
    if (widget.controlsVisible || width == 0) {
      widget.onContentTap();
      return;
    }

    if (position.dx < width * 0.33) {
      _startProgrammaticTurn(-1, Offset(0, position.dy));
      return;
    }
    if (position.dx > width * 0.67) {
      _startProgrammaticTurn(1, Offset(width, position.dy));
      return;
    }
    widget.onContentTap();
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _beginTurn(start: details.localPosition, current: details.localPosition);
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) return;
    final start = _dragStart ?? details.localPosition;
    _beginTurn(start: start, current: details.localPosition);
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final gesture = _gesture;
    if (gesture == null) return;
    if (!gesture.isTurning) {
      _animateBackToRest();
      return;
    }
    if (_isOutsideInteractivePage(gesture.current)) {
      _animateBackToRest();
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    final direction = _directionForGesture(gesture.direction);
    final shouldCommit = gesture.progress >= _minDragCommitRatio ||
        velocity.abs() >= _minFlingVelocity;

    if (!shouldCommit) {
      _animateBackToRest();
      return;
    }
    _turnPage(direction, fromOffset: _dragOffset);
  }

  bool _isOutsideInteractivePage(Offset position) {
    return position.dx < -_dragExitTolerance ||
        position.dx > _viewportWidth + _dragExitTolerance ||
        position.dy < -_dragExitTolerance ||
        position.dy > _viewportHeight + _dragExitTolerance;
  }

  void _beginTurn({
    required Offset start,
    required Offset current,
  }) {
    final pageSize = Size(_viewportWidth, context.size?.height ?? 1);
    final gesture = PageCurlGesture.fromPoints(
      pageSize: pageSize,
      start: start,
      current: current,
      lockedDirection: _dragDirection,
    );
    final horizontalDelta = (current.dx - start.dx).abs();
    final lockedDirection =
        _dragDirection ?? (horizontalDelta >= 1 ? gesture.direction : null);
    final direction = _directionForGesture(gesture.direction);
    final window = ReaderPagedWindow.fromViewport(
      widget.viewport,
      pageIndex: _pageIndex,
    );
    final target = window.pageForDirection(direction);
    final dragOffset = current.dx - start.dx;

    setState(() {
      _dragStart = start;
      _dragDirection = lockedDirection;
      _dragOffset = dragOffset;
      _gesture = gesture;
      if (!_isSameResolvedPage(_transitionTarget, target)) {
        _disposeSnapshots();
      }
      _transitionTarget = target;
      _committingDirection = null;
    });
    _updateCurlController(
        gesture: gesture, target: target, direction: direction);

    if (target != null) {
      _queueSnapshotCapture();
    }
  }

  void _startProgrammaticTurn(int direction, Offset start) {
    final pullDistance = _viewportWidth * 0.18;
    final current = Offset(
      start.dx + (direction > 0 ? -pullDistance : pullDistance),
      start.dy,
    );
    _beginTurn(start: start, current: current);
    final target = _transitionTarget;
    if (target == null) {
      _animateBackToRest();
      return;
    }
    _queueSnapshotCapture();
    _turnPage(direction, fromOffset: 0);
  }

  void _turnPage(int direction, {double? fromOffset}) {
    final window = ReaderPagedWindow.fromViewport(
      widget.viewport,
      pageIndex: _pageIndex,
    );
    final target = window.pageForDirection(direction);
    if (target == null) {
      _animateBackToRest();
      return;
    }

    _transitionTarget = target;
    _committingDirection = direction;
    final requestId = ++_turnRequestId;
    _updateCurlController(
      gesture: _gesture,
      target: target,
      direction: direction,
    );
    _animatePreparedTurn(
      requestId: requestId,
      direction: direction,
      target: target,
      fromOffset: fromOffset ?? _dragOffset,
    );
  }

  Future<void> _animatePreparedTurn({
    required int requestId,
    required int direction,
    required ReaderResolvedPage target,
    required double fromOffset,
  }) async {
    await _queueSnapshotCapture();
    if (!mounted ||
        requestId != _turnRequestId ||
        _committingDirection != direction ||
        !_isSameResolvedPage(_transitionTarget, target)) {
      return;
    }
    if (_snapshots == null || _snapshotsDisposed) {
      _animateBackToRest();
      return;
    }
    _animateOffset(
      from: fromOffset,
      to: direction > 0 ? -_viewportWidth : _viewportWidth,
    );
  }

  void _animateBackToRest() {
    if (_dragOffset == 0) {
      setState(() => _resetTurnState(disposeSnapshots: true));
      return;
    }
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
    final start = _dragStart;
    if (start == null) return;
    final value = _offsetAnimation!.value;
    final current = Offset(start.dx + value, start.dy);
    final gesture = PageCurlGesture.fromPoints(
      pageSize: Size(_viewportWidth, context.size?.height ?? 1),
      start: start,
      current: current,
      lockedDirection: _dragDirection,
    );
    _dragOffset = value;
    _gesture = gesture;
    final target = _transitionTarget;
    if (target == null) {
      setState(() {});
      return;
    }
    _updateCurlController(
      gesture: gesture,
      target: target,
      direction:
          _committingDirection ?? _directionForGesture(gesture.direction),
    );
  }

  void _completeAnimation() {
    if (!mounted) return;
    final target = _transitionTarget;
    final direction = _committingDirection;
    if (target != null && direction != null) {
      if (target.chapterIndex == widget.viewport.center.chapter.index) {
        _pageIndex = target.pageIndex;
      }
      widget.onLocationChanged(target.page.start);
    }
    setState(() => _resetTurnState(disposeSnapshots: true));
  }

  Future<void> _queueSnapshotCapture() {
    if (_snapshots != null && !_snapshotsDisposed) {
      return Future.value();
    }
    final activeCapture = _snapshotCaptureFuture;
    if (_captureInFlight && activeCapture != null) {
      return activeCapture;
    }
    final completer = Completer<void>();
    _snapshotCaptureFuture = completer.future;
    final captureTarget = _transitionTarget;
    _captureInFlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      PageCurlSnapshotPair? pair;
      try {
        if (!mounted) return;
        pair = await _snapshotController.capturePair(
          currentKey: _currentPageKey,
          targetKey: _targetPageKey,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        );
        if (!mounted) {
          pair?.dispose();
          return;
        }
        if (!_isSameResolvedPage(_transitionTarget, captureTarget)) {
          pair?.dispose();
          return;
        }
        setState(() {
          _disposeSnapshots();
          _snapshots = pair;
        });
      } finally {
        if (mounted) {
          _captureInFlight = false;
          _snapshotCaptureFuture = null;
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
    return completer.future;
  }

  void _resetTurnState({
    bool stopAnimation = false,
    bool disposeSnapshots = false,
  }) {
    if (stopAnimation) {
      _controller.stop();
    }
    _offsetAnimation?.removeListener(_handleAnimatedOffset);
    _offsetAnimation = null;
    _dragStart = null;
    _dragDirection = null;
    _dragOffset = 0;
    _gesture = null;
    _transitionTarget = null;
    _committingDirection = null;
    _captureInFlight = false;
    _snapshotCaptureFuture = null;
    _turnRequestId++;
    _curlController.clear();
    if (disposeSnapshots) {
      _disposeSnapshots();
    }
  }

  void _disposeSnapshots() {
    _snapshots?.dispose();
    _snapshots = null;
  }

  int _directionForGesture(PageCurlDirection direction) {
    return switch (direction) {
      PageCurlDirection.previous => -1,
      PageCurlDirection.next => 1,
    };
  }

  void _updateCurlController({
    required PageCurlGesture? gesture,
    required ReaderResolvedPage? target,
    required int direction,
  }) {
    if (gesture == null || target == null) {
      _curlController.clear();
      return;
    }
    _curlController.update(
      gesture: gesture,
      turnType: direction > 0
          ? PageCurlTurnType.nextPageOut
          : PageCurlTurnType.previousPageIn,
    );
  }

  bool _isSameResolvedPage(
    ReaderResolvedPage? first,
    ReaderResolvedPage? second,
  ) {
    if (first == null || second == null) return first == second;
    return first.chapterIndex == second.chapterIndex &&
        first.pageIndex == second.pageIndex;
  }
}
