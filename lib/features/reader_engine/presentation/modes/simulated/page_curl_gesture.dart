import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum PageCurlDirection {
  previous,
  next,
}

enum PageCurlAnchor {
  top,
  middle,
  bottom,
}

class PageCurlGesture {
  const PageCurlGesture({
    required this.pageSize,
    required this.start,
    required this.current,
    required this.direction,
    required this.anchor,
    required this.progress,
  });

  factory PageCurlGesture.fromPoints({
    required Size pageSize,
    required Offset start,
    required Offset current,
    PageCurlDirection? lockedDirection,
  }) {
    final deltaX = current.dx - start.dx;
    final direction = lockedDirection ??
        switch (deltaX) {
          < 0 => PageCurlDirection.next,
          > 0 => PageCurlDirection.previous,
          _ => start.dx <= pageSize.width / 2
              ? PageCurlDirection.previous
              : PageCurlDirection.next,
        };
    final anchor = _anchorForStart(start: start, pageHeight: pageSize.height);
    final horizontalTravel = switch (direction) {
      PageCurlDirection.previous => current.dx - start.dx,
      PageCurlDirection.next => start.dx - current.dx,
    };
    final progress = (horizontalTravel / math.max(1.0, pageSize.width))
        .clamp(0.0, 1.0)
        .toDouble();

    return PageCurlGesture(
      pageSize: pageSize,
      start: start,
      current: current,
      direction: direction,
      anchor: anchor,
      progress: progress,
    );
  }

  final Size pageSize;
  final Offset start;
  final Offset current;
  final PageCurlDirection direction;
  final PageCurlAnchor anchor;
  final double progress;

  bool get isTurning => progress > 0 || (current.dx - start.dx).abs() > 0.5;

  static PageCurlAnchor _anchorForStart({
    required Offset start,
    required double pageHeight,
  }) {
    final topBoundary = pageHeight / 3;
    final bottomBoundary = pageHeight * 2 / 3;
    if (start.dy <= topBoundary) return PageCurlAnchor.top;
    if (start.dy >= bottomBoundary) return PageCurlAnchor.bottom;
    return PageCurlAnchor.middle;
  }
}
