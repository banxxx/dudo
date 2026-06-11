import 'package:flutter/painting.dart';

import '../../../domain/reader_background.dart';
import '../../../domain/reader_theme.dart';
import '../../../domain/reader_settings.dart';
import '../../../layout/reader_line_layout_models.dart';
import '../reader_page_slice_line_layout.dart';
import '../reader_paged_window.dart';
import 'page_curl_snapshot.dart';
import 'reader_page_image_renderer.dart';

class ReaderLinePageSnapshotController {
  const ReaderLinePageSnapshotController({
    this.renderer = const ReaderPageImageRenderer(),
  });

  final ReaderPageImageRenderer renderer;

  Future<PageCurlSnapshotPair?> capturePair({
    required ReaderPageLayout currentPage,
    required ReaderPageLayout targetPage,
    required ReaderPalette palette,
    ReaderBackgroundPreference background = const ReaderBackgroundPreference(
      type: ReaderBackgroundType.solid,
      id: ReaderBackgroundPreference.solidId,
      opacity: 0,
      alignment: Alignment.center,
      tintEnabled: false,
    ),
    required double devicePixelRatio,
  }) async {
    try {
      return await renderer.renderPair(
        currentPage: currentPage,
        targetPage: targetPage,
        palette: palette,
        background: background,
        pixelRatio: devicePixelRatio,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> warmPage({
    required ReaderPageLayout pageLayout,
    required ReaderPalette palette,
    ReaderBackgroundPreference background = const ReaderBackgroundPreference(
      type: ReaderBackgroundType.solid,
      id: ReaderBackgroundPreference.solidId,
      opacity: 0,
      alignment: Alignment.center,
      tintEnabled: false,
    ),
    required double devicePixelRatio,
  }) async {
    final handle = await renderer.renderPage(
      pageLayout: pageLayout,
      palette: palette,
      background: background,
      pixelRatio: devicePixelRatio,
    );
    handle.release();
  }
}

class ReaderPageSliceSnapshotController {
  const ReaderPageSliceSnapshotController({
    this.layoutResolver = const ReaderPageSliceLineLayoutResolver(),
    this.lineSnapshotController = const ReaderLinePageSnapshotController(),
  });

  final ReaderPageSliceLineLayoutResolver layoutResolver;
  final ReaderLinePageSnapshotController lineSnapshotController;

  Future<PageCurlSnapshotPair?> capturePair({
    required ReaderResolvedPage currentPage,
    required ReaderResolvedPage targetPage,
    required ReaderSettings settings,
    required ReaderPalette palette,
    ReaderBackgroundPreference background = const ReaderBackgroundPreference(
      type: ReaderBackgroundType.solid,
      id: ReaderBackgroundPreference.solidId,
      opacity: 0,
      alignment: Alignment.center,
      tintEnabled: false,
    ),
    required Size viewportSize,
    required double devicePixelRatio,
  }) async {
    try {
      final currentLayout = await layoutResolver.resolvePage(
        resolvedPage: currentPage,
        settings: settings,
        viewportSize: viewportSize,
      );
      final targetLayout = await layoutResolver.resolvePage(
        resolvedPage: targetPage,
        settings: settings,
        viewportSize: viewportSize,
      );
      return lineSnapshotController.capturePair(
        currentPage: currentLayout,
        targetPage: targetLayout,
        palette: palette,
        background: background,
        devicePixelRatio: devicePixelRatio,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> warmPages({
    required Iterable<ReaderResolvedPage> pages,
    required ReaderSettings settings,
    required ReaderPalette palette,
    ReaderBackgroundPreference background = const ReaderBackgroundPreference(
      type: ReaderBackgroundType.solid,
      id: ReaderBackgroundPreference.solidId,
      opacity: 0,
      alignment: Alignment.center,
      tintEnabled: false,
    ),
    required Size viewportSize,
    required double devicePixelRatio,
  }) async {
    for (final page in pages) {
      try {
        final layout = await layoutResolver.resolvePage(
          resolvedPage: page,
          settings: settings,
          viewportSize: viewportSize,
        );
        await lineSnapshotController.warmPage(
          pageLayout: layout,
          palette: palette,
          background: background,
          devicePixelRatio: devicePixelRatio,
        );
      } catch (_) {
        // Warming is opportunistic; active turns can still render on demand.
      }
    }
  }
}
