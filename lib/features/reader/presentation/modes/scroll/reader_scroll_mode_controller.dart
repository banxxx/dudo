import 'package:flutter/material.dart';

import '../../../domain/reader_chapter_view.dart';
import '../../layout/reader_scroll_position_mapper.dart';

class ReaderScrollModeController {
  ReaderScrollModeController({
    required this.onChapterTurnRequested,
    required this.onReadPositionChanged,
  });

  final void Function(int chapterIndex, int initialReadPosition)
      onChapterTurnRequested;
  final void Function(int chapterIndex, int readPosition) onReadPositionChanged;
  final ScrollController scrollController = ScrollController();

  bool _isTurningChapter = false;
  bool _isProgrammaticScroll = false;
  int? _programmaticReadPosition;
  int? _restoredChapterIndex;
  int? _lastReportedPosition;

  void dispose() => scrollController.dispose();

  void resetRestore() {
    _restoredChapterIndex = null;
    _lastReportedPosition = null;
    _isTurningChapter = false;
  }

  int? restoreReadPositionIfNeeded({
    required ReaderChapterView view,
    required int readPosition,
    required List<ReaderParagraphLayoutRange> ranges,
  }) {
    if (_restoredChapterIndex == view.currentChapterIndex) return null;
    final normalized = readPosition.clamp(0, view.text.length).toInt();
    _restoredChapterIndex = view.currentChapterIndex;
    _lastReportedPosition = normalized;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      final maxScrollExtent = scrollController.position.maxScrollExtent;
      final offset = ReaderScrollPositionMapper.scrollOffsetForReadPosition(
        ranges: ranges,
        readPosition: normalized,
      );
      scrollController.jumpTo(offset.clamp(0.0, maxScrollExtent));
    });
    return normalized;
  }

  bool handleScrollNotification({
    required ScrollNotification notification,
    required ReaderChapterView view,
    required int readPosition,
  }) {
    final normalized = readPosition.clamp(0, view.text.length).toInt();
    if (_isProgrammaticScroll) {
      _programmaticReadPosition = normalized;
    } else if (_shouldReportPosition(normalized)) {
      _lastReportedPosition = normalized;
      onReadPositionChanged(view.currentChapterIndex, normalized);
    }
    _handleChapterBoundary(notification: notification, view: view);
    return false;
  }

  void turnPage({
    required ReaderChapterView view,
    required int direction,
  }) {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final pageDelta = position.viewportDimension * 0.92 * direction;
    final target = (position.pixels + pageDelta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (target == position.pixels) {
      if (direction < 0 && view.previousChapterIndex != null) {
        onChapterTurnRequested(view.previousChapterIndex!, 1 << 30);
      } else if (direction > 0 && view.nextChapterIndex != null) {
        onChapterTurnRequested(view.nextChapterIndex!, 0);
      }
      return;
    }
    _isProgrammaticScroll = true;
    _programmaticReadPosition = null;
    final targetChapterIndex = view.currentChapterIndex;
    scrollController
        .animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    )
        .whenComplete(() {
      _isProgrammaticScroll = false;
      final finalReadPosition = _programmaticReadPosition;
      _programmaticReadPosition = null;
      if (finalReadPosition == null) return;
      _lastReportedPosition = finalReadPosition;
      onReadPositionChanged(targetChapterIndex, finalReadPosition);
    });
  }

  bool _shouldReportPosition(int readPosition) {
    final last = _lastReportedPosition;
    if (last == null) return true;
    return (readPosition - last).abs() >= 12;
  }

  void _handleChapterBoundary({
    required ScrollNotification notification,
    required ReaderChapterView view,
  }) {
    if (_isTurningChapter) return;
    if (notification is! OverscrollNotification &&
        notification is! ScrollUpdateNotification) {
      return;
    }
    final hasDragDetails = notification is OverscrollNotification
        ? notification.dragDetails != null
        : notification is ScrollUpdateNotification &&
            notification.dragDetails != null;
    if (!hasDragDetails) return;

    final metrics = notification.metrics;
    final atTop = metrics.pixels <= metrics.minScrollExtent;
    final atBottom = metrics.pixels >= metrics.maxScrollExtent;
    if (atTop && view.previousChapterIndex != null) {
      _isTurningChapter = true;
      onChapterTurnRequested(view.previousChapterIndex!, 1 << 30);
      return;
    }
    if (atBottom && view.nextChapterIndex != null) {
      _isTurningChapter = true;
      onChapterTurnRequested(view.nextChapterIndex!, 0);
    }
  }
}
