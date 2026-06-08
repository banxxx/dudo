import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_theme.dart';
import '../../../domain/reader_location.dart';
import '../../../domain/reader_settings.dart';
import '../../../domain/reader_viewport_state.dart';
import '../reader_page_slice_canvas_surface.dart';
import '../reader_paged_window.dart';
import 'page_curl_controller.dart';
import 'page_curl_gesture.dart';
import 'page_curl_quality.dart';
import 'page_curl_render_widget.dart';
import 'page_curl_snapshot.dart';
import 'reader_line_page_snapshot.dart';
import 'reader_page_image_renderer.dart';

class SimulatedReaderView extends StatefulWidget {
  const SimulatedReaderView({
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
  State<SimulatedReaderView> createState() => _SimulatedReaderViewState();
}

class _SimulatedReaderViewState extends State<SimulatedReaderView>
    with SingleTickerProviderStateMixin {
  static const double _minDragCommitRatio = 0.22;
  static const double _dragExitTolerance = 8;
  static Duration get _commitTravelDuration =>
      const Duration(milliseconds: 380);
  static Duration get _cancelTravelDuration =>
      const Duration(milliseconds: 900);

  final GlobalKey _currentPageKey = GlobalKey();
  final GlobalKey _targetPageKey = GlobalKey();
  final PageCurlSnapshotController _fallbackSnapshotController =
      const PageCurlSnapshotController(quality: PageCurlQuality.high);
  final ReaderPageImageCache _pageImageCache =
      ReaderPageImageCache(maximumEntries: 3);
  late final ReaderPageSliceSnapshotController _pageSliceSnapshotController =
      ReaderPageSliceSnapshotController(
    lineSnapshotController: ReaderLinePageSnapshotController(
      renderer: ReaderPageImageRenderer(cache: _pageImageCache),
    ),
  );

  late final AnimationController _controller;
  late final PageCurlController _curlController;
  Animation<Offset>? _touchAnimation;

  int? _pageIndex;
  double _viewportWidth = 1;
  double _viewportHeight = 1;
  Offset? _pendingDragStart;
  Offset? _dragStart;
  Offset? _lastDragPosition;
  PageCurlDirection? _dragDirection;
  double _dragOffset = 0;
  bool _isCancelingTurn = false;
  PageCurlGesture? _gesture;
  ReaderResolvedPage? _transitionTarget;
  ReaderResolvedPage? _committedTarget;
  ReaderResolvedPage? _snapshotHandoffTarget;
  int? _committingDirection;
  int? _cancelingDirection;
  PageCurlSnapshotPair? _snapshots;
  bool _captureInFlight = false;
  Future<void>? _snapshotCaptureFuture;
  int _snapshotCaptureGeneration = 0;
  String? _imageWarmupKey;
  bool _imageWarmupInFlight = false;
  int _turnRequestId = 0;
  int _handledExternalPageTurnRequestId = 0;
  int _animationGeneration = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _commitTravelDuration,
    );
    _curlController = PageCurlController();
  }

  @override
  void didUpdateWidget(covariant SimulatedReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final committedTarget = _committedTarget;
    if (committedTarget != null) {
      if (committedTarget.chapterIndex ==
          widget.viewport.center.chapter.index) {
        _committedTarget = null;
        _pageIndex = null;
        _resetTurnState(stopAnimation: true, disposeSnapshots: true);
      }
      return;
    }
    if (_snapshotHandoffTarget != null) {
      return;
    }
    if (oldWidget.viewport.center.chapter.index !=
            widget.viewport.center.chapter.index ||
        oldWidget.viewport.currentLocation != widget.viewport.currentLocation) {
      _pageIndex = null;
      _resetTurnState(stopAnimation: true, disposeSnapshots: true);
    }
    if (oldWidget.settings != widget.settings ||
        oldWidget.palette != widget.palette) {
      _imageWarmupKey = null;
      _pageImageCache.clear();
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
    _touchAnimation?.removeListener(_handleAnimatedTouch);
    _snapshots?.dispose();
    _pageImageCache.dispose();
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
        _schedulePageImageWarmup(
          window: window,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        );
        final target = _transitionTarget ?? window.current;
        final pageColor = widget.palette.background;
        final committedTarget = _committedTarget;
        if (committedTarget != null) {
          return SizedBox.expand(
            child: GestureDetector(
              key: const ValueKey('reader-engine-simulated-view'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _handleTap(details.localPosition),
              child: ClipRect(
                child: ColoredBox(
                  color: pageColor,
                  child: ReaderPageSliceCanvasSurface(
                    key: ValueKey(
                      'reader-engine-simulated-committed-'
                      '${committedTarget.chapterIndex}-'
                      '${committedTarget.pageIndex}',
                    ),
                    resolvedPage: committedTarget,
                    settings: widget.settings,
                    palette: widget.palette,
                  ),
                ),
              ),
            ),
          );
        }
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
            onHorizontalDragDown:
                widget.controlsVisible ? null : _handleHorizontalDragDown,
            onHorizontalDragStart:
                widget.controlsVisible ? null : _handleHorizontalDragStart,
            onHorizontalDragUpdate:
                widget.controlsVisible ? null : _handleHorizontalDragUpdate,
            onHorizontalDragEnd:
                widget.controlsVisible ? null : _handleHorizontalDragEnd,
            onHorizontalDragCancel:
                widget.controlsVisible ? null : _handleHorizontalDragCancel,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    key: _targetPageKey,
                    child: ColoredBox(
                      color: pageColor,
                      child: ReaderPageSliceCanvasSurface(
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
                        child: ReaderPageSliceCanvasSurface(
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
                      quality: PageCurlQuality.high,
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

  void _handleTap(Offset position) {
    final width = _viewportWidth;
    if (widget.controlsVisible || width == 0) {
      widget.onContentTap();
      return;
    }

    if (position.dx < width * 0.33) {
      if (!_finishActivePageTurnIfNeeded()) return;
      _startProgrammaticTurn(-1, Offset(0, position.dy));
      return;
    }
    if (position.dx > width * 0.67) {
      if (!_finishActivePageTurnIfNeeded()) return;
      _startProgrammaticTurn(1, Offset(width, position.dy));
      return;
    }
    widget.onContentTap();
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    final start = _pendingDragStart ?? details.localPosition;
    _beginTurn(start: start, current: details.localPosition);
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) return;
    final start = _dragStart ?? _pendingDragStart ?? details.localPosition;
    _beginTurn(start: start, current: details.localPosition);
  }

  void _handleHorizontalDragDown(DragDownDetails details) {
    _pendingDragStart = details.localPosition;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final gesture = _gesture;
    if (gesture == null) {
      _pendingDragStart = null;
      return;
    }
    if (!gesture.isTurning) {
      _animateBackToRest();
      return;
    }
    if (_isOutsideInteractivePage(gesture.current)) {
      _animateBackToRest();
      return;
    }
    final direction = _directionForGesture(gesture.direction);
    if (_isCancelingTurn || gesture.progress < _minDragCommitRatio) {
      _animateBackToRest();
      return;
    }
    _turnPage(direction);
  }

  void _handleHorizontalDragCancel() {
    if (_committingDirection != null) return;
    _animateBackToRest();
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
    final gesture = _gestureFromPoints(
      start: start,
      current: current,
      lockedDirection: _dragDirection,
    );
    final horizontalDelta = (current.dx - start.dx).abs();
    final lockedDirection =
        _dragDirection ?? (horizontalDelta >= 1 ? gesture.direction : null);
    final direction = _directionForGesture(gesture.direction);
    final lastPosition = _lastDragPosition ?? start;
    final isCancelingTurn = lockedDirection == null
        ? false
        : switch (gesture.direction) {
            PageCurlDirection.next => current.dx > lastPosition.dx,
            PageCurlDirection.previous => current.dx < lastPosition.dx,
          };
    final window = ReaderPagedWindow.fromViewport(
      widget.viewport,
      pageIndex: _pageIndex,
    );
    final target = window.pageForDirection(direction);
    final dragOffset = current.dx - start.dx;

    setState(() {
      _dragStart = start;
      _lastDragPosition = current;
      _dragDirection = lockedDirection;
      _dragOffset = dragOffset;
      _isCancelingTurn = isCancelingTurn;
      _gesture = gesture;
      if (!_isSameResolvedPage(_transitionTarget, target)) {
        _disposeSnapshots();
      }
      _transitionTarget = target;
      _committingDirection = null;
      _cancelingDirection = null;
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
    _turnPage(direction);
  }

  void _turnPage(int direction) {
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
    _cancelingDirection = null;
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
    );
  }

  Future<void> _animatePreparedTurn({
    required int requestId,
    required int direction,
    required ReaderResolvedPage target,
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
    final gesture = _gesture;
    if (gesture == null) {
      _animateBackToRest();
      return;
    }
    final travel = _simulationAnimationTravel(
      gesture: gesture,
      direction: direction,
      cancel: false,
      baseDuration: _commitTravelDuration,
    );
    _animateTouch(
      from: gesture.current,
      to: travel.to,
      curve: Curves.easeOutCubic,
      duration: travel.duration,
    );
  }

  void _animateBackToRest() {
    final gesture = _gesture;
    final direction = _dragDirection;
    if (gesture == null || direction == null || !gesture.isTurning) {
      setState(() => _resetTurnState(disposeSnapshots: true));
      return;
    }
    _committingDirection = null;
    _cancelingDirection = _directionForGesture(direction);
    final travel = _simulationAnimationTravel(
      gesture: gesture,
      direction: _cancelingDirection!,
      cancel: true,
      baseDuration: _cancelTravelDuration,
    );
    _animateTouch(
      from: gesture.current,
      to: travel.to,
      curve: Curves.easeOutCubic,
      duration: travel.duration,
    );
  }

  void _animateTouch({
    required Offset from,
    required Offset to,
    required Duration duration,
    Curve curve = Curves.easeOutCubic,
  }) {
    _touchAnimation?.removeListener(_handleAnimatedTouch);
    _controller.stop();
    final generation = ++_animationGeneration;
    _controller.duration = duration;
    _controller.reset();
    _applyAnimatedTouch(from);
    _touchAnimation = Tween<Offset>(begin: from, end: to)
        .chain(CurveTween(curve: curve))
        .animate(_controller)
      ..addListener(_handleAnimatedTouch);
    _controller.forward().whenComplete(() => _completeAnimation(generation));
  }

  void _handleAnimatedTouch() {
    if (!mounted || _touchAnimation == null) return;
    _applyAnimatedTouch(_touchAnimation!.value);
  }

  void _applyAnimatedTouch(Offset current) {
    final gestureStart = _gestureStartForAnimatedTravel();
    final direction = _dragDirection;
    if (gestureStart == null || direction == null) return;

    final gesture = _gestureFromPoints(
      start: gestureStart,
      current: current,
      lockedDirection: direction,
    );
    _dragOffset = current.dx - (_dragStart?.dx ?? gestureStart.dx);
    _gesture = gesture;
    final target = _transitionTarget;
    if (target == null) {
      setState(() {});
      return;
    }
    _updateCurlController(
      gesture: gesture,
      target: target,
      direction: _committingDirection ??
          _cancelingDirection ??
          _directionForGesture(gesture.direction),
    );
  }

  _PageCurlTravel _simulationAnimationTravel({
    required PageCurlGesture gesture,
    required int direction,
    required bool cancel,
    required Duration baseDuration,
  }) {
    final height = math.max(1.0, _viewportHeight);
    final width = math.max(1.0, _viewportWidth);
    final cornerY = _simulationCornerY(gesture: gesture, direction: direction);
    final isNext = direction > 0;
    var dx = 0.0;
    if (cancel) {
      dx = isNext ? width - gesture.current.dx : -(width + gesture.current.dx);
    } else {
      dx = isNext ? -(width + gesture.current.dx) : width - gesture.current.dx;
    }
    final dy = cancel
        ? (cornerY > height / 2
            ? height - gesture.current.dy
            : -gesture.current.dy)
        : (cornerY > height / 2
            ? height - gesture.current.dy
            : math.min(1.0, height) - gesture.current.dy);
    final to = Offset(gesture.current.dx + dx, gesture.current.dy + dy);
    return _PageCurlTravel(
      to: to,
      duration: _scaledTravelDuration(
        baseDuration: baseDuration,
        primaryDistance: dx != 0 ? dx.abs() : dy.abs(),
        viewportDistance: dx != 0 ? width : height,
      ),
    );
  }

  Duration _scaledTravelDuration({
    required Duration baseDuration,
    required double primaryDistance,
    required double viewportDistance,
  }) {
    final ratio = primaryDistance / math.max(1.0, viewportDistance);
    final milliseconds = (baseDuration.inMilliseconds * ratio).round();
    return Duration(milliseconds: math.max(1, milliseconds));
  }

  double _simulationCornerY({
    required PageCurlGesture gesture,
    required int direction,
  }) {
    if (direction < 0) return _viewportHeight;
    if (gesture.anchor == PageCurlAnchor.middle) {
      return gesture.start.dy < _viewportHeight / 2 ? 0 : _viewportHeight;
    }
    return gesture.anchor == PageCurlAnchor.top ? 0 : _viewportHeight;
  }

  Offset? _gestureStartForAnimatedTravel() {
    final start = _dragStart;
    final direction = _dragDirection;
    if (_committingDirection == null &&
        _cancelingDirection == null &&
        start != null &&
        direction != null) {
      return switch (direction) {
        PageCurlDirection.next => Offset(_viewportWidth, start.dy),
        PageCurlDirection.previous => Offset(0, start.dy),
      };
    }
    final gesture = _gesture;
    if (gesture != null) return gesture.start;
    if (start == null) return null;
    return switch (direction) {
      PageCurlDirection.next => Offset(_viewportWidth, start.dy),
      PageCurlDirection.previous => Offset(0, start.dy),
      null => start,
    };
  }

  PageCurlGesture _gestureFromPoints({
    required Offset start,
    required Offset current,
    PageCurlDirection? lockedDirection,
  }) {
    final pageSize = Size(_viewportWidth, _viewportHeight);
    final gesture = PageCurlGesture.fromPoints(
      pageSize: pageSize,
      start: start,
      current: current,
      lockedDirection: lockedDirection,
    );
    final visualStart = _visualStartForGesture(gesture);
    if (visualStart == start) return gesture;
    return PageCurlGesture.fromPoints(
      pageSize: pageSize,
      start: visualStart,
      current: current,
      lockedDirection: gesture.direction,
    );
  }

  Offset _visualStartForGesture(PageCurlGesture gesture) {
    if (gesture.anchor != PageCurlAnchor.middle) {
      return gesture.start;
    }
    final isRightMiddleTrigger = gesture.start.dx >= _viewportWidth * 0.67;
    if (!isRightMiddleTrigger) {
      return gesture.start;
    }
    return switch (gesture.direction) {
      PageCurlDirection.next => Offset(_viewportWidth, gesture.start.dy),
      PageCurlDirection.previous => gesture.start,
    };
  }

  void _completeAnimation(int generation) {
    if (!mounted || generation != _animationGeneration) return;
    final target = _transitionTarget;
    final direction = _committingDirection;
    if (target != null && direction != null) {
      if (target.chapterIndex == widget.viewport.center.chapter.index) {
        setState(() {
          _pageIndex = target.pageIndex;
          _snapshotHandoffTarget = target;
        });
        widget.onLocationChanged(target.page.start);
        _scheduleSnapshotHandoffClear(target);
        return;
      } else {
        _committedTarget = target;
      }
      widget.onLocationChanged(target.page.start);
    }
    setState(() => _resetTurnState(disposeSnapshots: true));
  }

  bool _finishActivePageTurnIfNeeded() {
    final target = _transitionTarget;
    final direction = _committingDirection;
    final hasActiveTurn = _controller.isAnimating ||
        target != null ||
        direction != null ||
        _snapshotHandoffTarget != null;
    if (!hasActiveTurn) return _committedTarget == null;

    _animationGeneration++;
    _controller.stop();
    if (target != null && direction != null) {
      if (target.chapterIndex == widget.viewport.center.chapter.index) {
        _pageIndex = target.pageIndex;
      } else {
        _committedTarget = target;
      }
      widget.onLocationChanged(target.page.start);
    }
    setState(() => _resetTurnState(disposeSnapshots: true));
    return _committedTarget == null;
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
    final captureGeneration = ++_snapshotCaptureGeneration;
    final captureTarget = _transitionTarget;
    final captureCurrent = ReaderPagedWindow.fromViewport(
      widget.viewport,
      pageIndex: _pageIndex,
    ).current;
    _captureInFlight = true;
    () async {
      PageCurlSnapshotPair? pair;
      try {
        if (!mounted || captureTarget == null) return;
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        pair = await _pageSliceSnapshotController.capturePair(
          currentPage: captureCurrent,
          targetPage: captureTarget,
          settings: widget.settings,
          palette: widget.palette,
          viewportSize: Size(_viewportWidth, _viewportHeight),
          devicePixelRatio: devicePixelRatio,
        );
        if (pair == null) {
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) return;
          pair = await _fallbackSnapshotController.capturePair(
            currentKey: _currentPageKey,
            targetKey: _targetPageKey,
            devicePixelRatio: devicePixelRatio,
          );
        }
        if (!mounted) {
          pair?.dispose();
          return;
        }
        if (captureGeneration != _snapshotCaptureGeneration) {
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
        if (mounted && captureGeneration == _snapshotCaptureGeneration) {
          _captureInFlight = false;
          _snapshotCaptureFuture = null;
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }();
    return completer.future;
  }

  void _schedulePageImageWarmup({
    required ReaderPagedWindow window,
    required double devicePixelRatio,
  }) {
    if (_imageWarmupInFlight ||
        _controller.isAnimating ||
        _gesture != null ||
        _committedTarget != null ||
        _snapshotHandoffTarget != null) {
      return;
    }
    final pages = [
      window.current,
      if (window.previous != null) window.previous!,
      if (window.next != null) window.next!,
    ];
    final key = [
      _viewportWidth,
      _viewportHeight,
      devicePixelRatio,
      widget.settings.paletteId,
      widget.settings.fontFamily,
      widget.settings.fontSize,
      widget.settings.lineHeight,
      widget.settings.paragraphSpacing,
      widget.settings.firstLineIndentEnabled,
      widget.settings.pagePadding.left,
      widget.settings.pagePadding.top,
      widget.settings.pagePadding.right,
      widget.settings.pagePadding.bottom,
      widget.palette.background.toARGB32(),
      widget.palette.foreground.toARGB32(),
      for (final page in pages) ...[
        page.chapterIndex,
        page.pageIndex,
        page.page.start.offset,
        page.page.end.offset,
      ],
    ].join('|');
    if (_imageWarmupKey == key) return;
    _imageWarmupKey = key;
    _imageWarmupInFlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted || _imageWarmupKey != key) return;
        await _pageSliceSnapshotController.warmPages(
          pages: pages,
          settings: widget.settings,
          palette: widget.palette,
          viewportSize: Size(_viewportWidth, _viewportHeight),
          devicePixelRatio: devicePixelRatio,
        );
      } finally {
        if (mounted) {
          _imageWarmupInFlight = false;
        }
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _resetTurnState({
    bool stopAnimation = false,
    bool disposeSnapshots = false,
  }) {
    if (stopAnimation) {
      _animationGeneration++;
      _controller.stop();
    }
    _touchAnimation?.removeListener(_handleAnimatedTouch);
    _touchAnimation = null;
    _dragStart = null;
    _pendingDragStart = null;
    _lastDragPosition = null;
    _dragDirection = null;
    _dragOffset = 0;
    _isCancelingTurn = false;
    _gesture = null;
    _transitionTarget = null;
    _snapshotHandoffTarget = null;
    _committingDirection = null;
    _cancelingDirection = null;
    _captureInFlight = false;
    _snapshotCaptureFuture = null;
    _snapshotCaptureGeneration++;
    _turnRequestId++;
    _curlController.clear();
    if (disposeSnapshots) {
      _disposeSnapshots();
    }
  }

  void _scheduleSnapshotHandoffClear(ReaderResolvedPage target) {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (!mounted || !_isSameResolvedPage(_snapshotHandoffTarget, target)) {
        return;
      }
      binding.addPostFrameCallback((_) {
        if (!mounted || !_isSameResolvedPage(_snapshotHandoffTarget, target)) {
          return;
        }
        setState(() => _resetTurnState(disposeSnapshots: true));
      });
      binding.ensureVisualUpdate();
    });
    binding.ensureVisualUpdate();
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
      phase: _committingDirection == null && _cancelingDirection == null
          ? PageCurlMotionPhase.interactive
          : PageCurlMotionPhase.completion,
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
      if (!mounted) return;
      if (!_finishActivePageTurnIfNeeded()) return;
      final start = Offset(
        direction > 0 ? _viewportWidth : 0,
        _viewportHeight / 2,
      );
      _startProgrammaticTurn(direction, start);
    });
  }
}

class _PageCurlTravel {
  const _PageCurlTravel({
    required this.to,
    required this.duration,
  });

  final Offset to;
  final Duration duration;
}
