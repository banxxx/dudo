part of '../../reader_controls.dart';

class _ReaderOverlayMetrics {
  const _ReaderOverlayMetrics({
    required this.layout,
  });

  factory _ReaderOverlayMetrics.fromLayout(ReaderChromeLayout layout) {
    return _ReaderOverlayMetrics(layout: layout);
  }

  final ReaderChromeLayout layout;

  double get scale => layout.metrics.scale;
  double get left => layout.metrics.left;
  double get top => layout.metrics.top;
  double get width => layout.metrics.width;
  double get height => layout.metrics.height;
  double get topControlsTop => layout.topControlsTop;
  double get bottomControlsTop => layout.bottomControlsTop;
  double get bottomControlsHeight => layout.bottomControlsHeight;

  double x(double value) => layout.metrics.x(value);
  double y(double value) => layout.metrics.y(value);
  double s(double value) => layout.metrics.s(value);
  double floatingPanelTop({
    required double preferredTop,
    required double height,
  }) =>
      layout.floatingPanelTop(preferredTop: preferredTop, height: height);
  double catalogSheetHeight(double preferredHeight) =>
      layout.catalogSheetHeight(preferredHeight);
  double get rightInset => left + s(16);
  double get panelWidth => width - s(32);
}
