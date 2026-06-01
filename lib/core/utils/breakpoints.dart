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
    return modeForWidth(MediaQuery.sizeOf(context).width);
  }

  static LayoutMode modeForWidth(double width) {
    if (isLargeWidth(width)) return LayoutMode.twoPane;
    if (isTabletWidth(width)) return LayoutMode.tablet;
    return LayoutMode.phone;
  }

  static bool isPhoneWidth(double width) => width < medium;

  static bool isTabletWidth(double width) => width >= medium;

  static bool isLargeWidth(double width) => width >= large;

  static bool isDesktopWidth(double width) => width >= xlarge;

  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }
}
