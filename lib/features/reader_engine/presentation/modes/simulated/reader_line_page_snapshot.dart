import 'package:flutter/painting.dart';

import '../../../../../shared/theme/app_theme.dart';
import '../../../domain/reader_settings.dart';
import '../../../layout/reader_line_layout_models.dart';
import '../reader_page_slice_line_layout.dart';
import '../reader_paged_window.dart';
import '../../widgets/reader_canvas_page.dart';
import 'page_curl_snapshot.dart';

class ReaderLinePageSnapshotController {
  const ReaderLinePageSnapshotController({
    this.rasterizer = const ReaderPageRasterizer(),
  });

  final ReaderPageRasterizer rasterizer;

  Future<PageCurlSnapshotPair?> capturePair({
    required ReaderPageLayout currentPage,
    required ReaderPageLayout targetPage,
    required ReaderPalette palette,
    required double devicePixelRatio,
  }) async {
    final current = await rasterizer.renderImage(
      pageLayout: currentPage,
      palette: palette,
      pixelRatio: devicePixelRatio,
    );
    try {
      final target = await rasterizer.renderImage(
        pageLayout: targetPage,
        palette: palette,
        pixelRatio: devicePixelRatio,
      );
      return PageCurlSnapshotPair(current: current, target: target);
    } catch (_) {
      current.dispose();
      return null;
    }
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
        devicePixelRatio: devicePixelRatio,
      );
    } catch (_) {
      return null;
    }
  }
}
