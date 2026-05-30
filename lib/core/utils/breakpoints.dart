import 'package:flutter/widgets.dart';

/// Layout-mode helper: when wide enough we render two reader pages side
/// by side, like a real book.
enum LayoutMode { phone, tablet, twoPane }

class Breakpoints {
  Breakpoints._();
  static const double medium = 600;
  static const double large = 840;
  static const double xlarge = 1200;

  static LayoutMode of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= large) return LayoutMode.twoPane;
    if (w >= medium) return LayoutMode.tablet;
    return LayoutMode.phone;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }
}
