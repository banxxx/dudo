import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../application/reader_engine_state.dart';
import '../data/reader_document_source.dart';
import '../domain/reader_location.dart';
import '../domain/reader_turn_mode.dart';
import '../layout/reader_layout_engine.dart';
import 'modes/cover_reader_view.dart';
import 'modes/paged_reader_view.dart';
import 'modes/scroll_reader_view.dart';
import 'modes/simulated/simulated_reader_view.dart';
import 'modes/slide_reader_view.dart';

class ReaderViewport extends StatelessWidget {
  const ReaderViewport({
    super.key,
    required this.state,
    required this.palette,
    this.brightness = 1,
    required this.controlsVisible,
    required this.source,
    required this.layoutEngine,
    required this.viewportSize,
    required this.chapterCount,
    required this.onContentTap,
    required this.onPreviousBoundary,
    required this.onNextBoundary,
    required this.onLocationChanged,
    this.externalPageTurnRequestId = 0,
    this.externalPageTurnDirection = 0,
  });

  final ReaderSessionState state;
  final ReaderPalette palette;
  final double brightness;
  final bool controlsVisible;
  final ReaderDocumentSource source;
  final ReaderLayoutEngine layoutEngine;
  final Size viewportSize;
  final int chapterCount;
  final VoidCallback onContentTap;
  final VoidCallback onPreviousBoundary;
  final VoidCallback onNextBoundary;
  final ValueChanged<ReaderLocation> onLocationChanged;
  final int externalPageTurnRequestId;
  final int externalPageTurnDirection;

  @override
  Widget build(BuildContext context) {
    final viewport = state.viewport;
    if (viewport == null) {
      return const Center(child: Text('暂无正文'));
    }
    return switch (state.settings.turnMode) {
      ReaderTurnMode.scroll => ScrollReaderView(
          bookId: viewport.center.chapter.bookId,
          chapterCount: chapterCount,
          source: source,
          layoutEngine: layoutEngine,
          viewportSize: viewportSize,
          viewport: viewport,
          settings: state.settings,
          palette: palette,
          externalPageTurnRequestId: externalPageTurnRequestId,
          externalPageTurnDirection: externalPageTurnDirection,
          onContentTap: onContentTap,
          onLocationChanged: onLocationChanged,
        ),
      ReaderTurnMode.slide => SlideReaderView(
          viewport: viewport,
          settings: state.settings,
          palette: palette,
          controlsVisible: controlsVisible,
          externalPageTurnRequestId: externalPageTurnRequestId,
          externalPageTurnDirection: externalPageTurnDirection,
          onContentTap: onContentTap,
          onPreviousBoundary: onPreviousBoundary,
          onNextBoundary: onNextBoundary,
          onLocationChanged: onLocationChanged,
        ),
      ReaderTurnMode.simulated => SimulatedReaderView(
          viewport: viewport,
          settings: state.settings,
          palette: palette,
          brightness: brightness,
          controlsVisible: controlsVisible,
          externalPageTurnRequestId: externalPageTurnRequestId,
          externalPageTurnDirection: externalPageTurnDirection,
          onContentTap: onContentTap,
          onPreviousBoundary: onPreviousBoundary,
          onNextBoundary: onNextBoundary,
          onLocationChanged: onLocationChanged,
        ),
      ReaderTurnMode.cover => CoverReaderView(
          viewport: viewport,
          settings: state.settings,
          palette: palette,
          brightness: brightness,
          controlsVisible: controlsVisible,
          externalPageTurnRequestId: externalPageTurnRequestId,
          externalPageTurnDirection: externalPageTurnDirection,
          onContentTap: onContentTap,
          onPreviousBoundary: onPreviousBoundary,
          onNextBoundary: onNextBoundary,
          onLocationChanged: onLocationChanged,
        ),
      ReaderTurnMode.paged => PagedReaderView(
          viewport: viewport,
          settings: state.settings,
          palette: palette,
          controlsVisible: controlsVisible,
          externalPageTurnRequestId: externalPageTurnRequestId,
          externalPageTurnDirection: externalPageTurnDirection,
          onContentTap: onContentTap,
          onPreviousBoundary: onPreviousBoundary,
          onNextBoundary: onNextBoundary,
          onLocationChanged: onLocationChanged,
        ),
    };
  }
}
