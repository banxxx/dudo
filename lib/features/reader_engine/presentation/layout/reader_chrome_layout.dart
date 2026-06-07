import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/reader_insets.dart';
import 'reader_page_metrics.dart';

class ReaderChromeLayout {
  ReaderChromeLayout._({
    required this.size,
    required this.safePadding,
    required this.metrics,
  });

  factory ReaderChromeLayout.fromSize(Size size, EdgeInsets safePadding) {
    return ReaderChromeLayout._(
      size: size,
      safePadding: safePadding,
      metrics: ReaderPageMetrics.fromSize(size),
    );
  }

  final Size size;
  final EdgeInsets safePadding;
  final ReaderPageMetrics metrics;

  double get topControlsHeight => metrics.s(58);
  double get bottomControlsHeight => metrics.s(124);
  double get _panelGap => metrics.s(14);
  double get _floatingPanelGap => metrics.s(16);
  double get _controlEdgeGap => metrics.s(isCompactHeight ? 12 : 20);

  double get topControlsTop {
    return safePadding.top + _controlEdgeGap;
  }

  double get bottomControlsTop {
    final bottom = safePadding.bottom + _controlEdgeGap;
    final preferredTop = size.height - bottom - bottomControlsHeight;
    final minimumTop = topControlsTop + topControlsHeight + _panelGap;
    return math.max(minimumTop, preferredTop);
  }

  bool get isCompactHeight => size.height < metrics.s(760);

  ReaderInsets get contentInsets {
    final left = metrics.x(30);
    final contentWidth = math.min(
      metrics.s(330),
      math.max(1.0, size.width - left),
    );
    final right =
        (size.width - left - contentWidth).clamp(0.0, size.width).toDouble();
    final top = safePadding.top + metrics.s(18);
    final bottom = safePadding.bottom + metrics.s(60);

    return ReaderInsets(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  double floatingPanelTop({
    required double preferredTop,
    required double height,
  }) {
    final scaledHeight = metrics.s(height);
    final minimumTop = topControlsTop + topControlsHeight + _panelGap;
    final anchoredTop = bottomControlsTop - _floatingPanelGap - scaledHeight;

    if (anchoredTop < minimumTop) {
      final preferred = metrics.y(preferredTop);
      final safeTop = safePadding.top + metrics.s(8);
      return math.max(safeTop, math.min(preferred, anchoredTop));
    }

    return anchoredTop;
  }

  double catalogSheetHeight(double preferredHeight) {
    final maxHeight = size.height - safePadding.top - metrics.s(28);
    final preferred = metrics.s(preferredHeight);
    final minimum = math.min(metrics.s(360), maxHeight);
    return preferred.clamp(minimum, maxHeight).toDouble();
  }
}
