import 'reader_location.dart';

class ReaderAnchor {
  const ReaderAnchor({
    required this.location,
    required this.alignment,
  });

  final ReaderLocation location;

  /// 0 means the top edge of the viewport, 1 means the bottom edge.
  final double alignment;
}
