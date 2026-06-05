import 'package:flutter/material.dart';

import '../../domain/reader_overlay_mode.dart';
import '../modes/reader_turn_mode.dart';

class ReaderGestureLayer extends StatelessWidget {
  const ReaderGestureLayer({
    super.key,
    required this.overlayMode,
    required this.pageTurnMode,
    required this.onToggleOverlay,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final ReaderOverlayMode overlayMode;
  final ReaderTurnMode pageTurnMode;
  final VoidCallback onToggleOverlay;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('reader-gesture-layer'),
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _handleTap(context, details.localPosition),
      onHorizontalDragEnd: pageTurnMode == ReaderTurnMode.scroll
          ? null
          : (details) => _handleHorizontalDragEnd(details.primaryVelocity ?? 0),
    );
  }

  void _handleTap(BuildContext context, Offset position) {
    if (overlayMode != ReaderOverlayMode.hidden) {
      onToggleOverlay();
      return;
    }

    final width = context.size?.width ?? 0;
    if (width == 0) {
      onToggleOverlay();
      return;
    }

    if (pageTurnMode == ReaderTurnMode.scroll) {
      onToggleOverlay();
      return;
    }

    if (position.dx < width * 0.33) {
      onPreviousPage();
      return;
    }
    if (position.dx > width * 0.67) {
      onNextPage();
      return;
    }
    onToggleOverlay();
  }

  void _handleHorizontalDragEnd(double velocity) {
    if (overlayMode != ReaderOverlayMode.hidden || velocity.abs() < 260) return;
    if (velocity < 0) {
      onNextPage();
    } else {
      onPreviousPage();
    }
  }
}
