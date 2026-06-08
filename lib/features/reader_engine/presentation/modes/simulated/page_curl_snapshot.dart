import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'page_curl_quality.dart';

class PageCurlSnapshotPair {
  PageCurlSnapshotPair({
    required this.current,
    required this.target,
    void Function()? onDispose,
  }) : _onDispose = onDispose;

  final ui.Image current;
  final ui.Image target;
  final void Function()? _onDispose;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final onDispose = _onDispose;
    if (onDispose != null) {
      onDispose();
      return;
    }
    current.dispose();
    target.dispose();
  }
}

class PageCurlSnapshotController {
  const PageCurlSnapshotController({
    this.quality = PageCurlQuality.normal,
  });

  final PageCurlQuality quality;

  Future<PageCurlSnapshotPair?> capturePair({
    required GlobalKey currentKey,
    required GlobalKey targetKey,
    required double devicePixelRatio,
  }) async {
    final pixelRatio = quality.cappedPixelRatio(devicePixelRatio);
    final current = await _capture(currentKey, pixelRatio);
    if (current == null) return null;

    final target = await _capture(targetKey, pixelRatio);
    if (target == null) {
      current.dispose();
      return null;
    }

    return PageCurlSnapshotPair(current: current, target: target);
  }

  Future<ui.Image?> _capture(GlobalKey key, double pixelRatio) async {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    if (renderObject.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
    }
    try {
      return renderObject.toImage(pixelRatio: pixelRatio);
    } catch (_) {
      return null;
    }
  }
}
