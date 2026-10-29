import 'package:flutter/material.dart';

import 'dudo_palette.dart';

/// The app-wide colour tokens. These were once compile-time constants, but the
/// theme settings let the user pick a mode (light/dark) and an accent at
/// runtime, so every token now resolves through the active [DudoPalette].
///
/// [DudoApp] installs the palette for the current setting before building the
/// widget tree, and swapping it there repaints every page because the root
/// `MaterialApp` rebuilds. Pages therefore keep reading `DudoColors.x` without
/// needing a `Theme.of(context)` lookup at each call site.
class DudoColors {
  DudoColors._();

  static DudoPalette _active = DudoPalette.light(DudoAccent.pine);

  static DudoPalette get palette => _active;

  static void use(DudoPalette palette) => _active = palette;

  static Color get paperBackground => _active.paperBackground;
  static Color get surface => _active.surface;
  static Color get surfaceLow => _active.surfaceLow;
  static Color get surfaceHigh => _active.surfaceHigh;
  static Color get primary => _active.primary;
  static Color get primaryContainer => _active.primaryContainer;
  static Color get primaryContainerStrong => _active.primaryContainerStrong;
  static Color get primaryContainerMuted => _active.primaryContainerMuted;
  static Color get onPrimaryContainer => _active.onPrimaryContainer;
  static Color get primaryDark => _active.primaryDark;
  static Color get secondary => _active.secondary;
  static Color get secondaryDark => _active.secondaryDark;
  static Color get secondaryContainer => _active.secondaryContainer;
  static Color get accent => _active.accent;
  static Color get accentSoft => _active.accentSoft;
  static Color get accentMuted => _active.accentMuted;
  static Color get textPrimary => _active.textPrimary;
  static Color get textSecondary => _active.textSecondary;
  static Color get outline => _active.outline;
  static Color get outlineVariant => _active.outlineVariant;
  static Color get navigationStroke => _active.navigationStroke;
  static Color get navigationShadow => _active.navigationShadow;

  /// The bottom tab bar still references these by name and branches on the
  /// platform brightness itself, so they stay as fixed constants.
  static const Color darkBackground = Color(0xFF1C1F22);
  static const Color darkSurface = Color(0xF2262930);
  static const Color darkNavigationActive = Color(0xFF2A2E28);
  static const Color darkNavigationActiveForeground = Color(0xFF8EAD84);
  static const Color darkNavigationInactive = Color(0xFFB8AA91);
  static const Color darkNavigationStroke = Color(0xCC3E4248);
  static const Color darkNavigationShadow = Color(0x66000000);
}

/// Spacing tokens — 8dp grid per M3 spec.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Shape tokens — small / medium / large radii.
class AppRadius {
  AppRadius._();
  static const BorderRadius small = BorderRadius.all(Radius.circular(8));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius large = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xLarge = BorderRadius.all(Radius.circular(24));
  static const BorderRadius full = BorderRadius.all(Radius.circular(999));
}

/// Responsive layout tokens for shared page containers and shells.
class DudoLayout {
  DudoLayout._();

  static const double compactPhoneWidth = 360;
  static const double phoneContentMaxWidth = 480;
  static const double tabletContentMaxWidth = 720;
  static const double desktopContentMaxWidth = 1080;

  static const EdgeInsets compactPhonePagePadding = EdgeInsets.fromLTRB(
    16,
    8,
    16,
    16,
  );
  static const EdgeInsets phonePagePadding = EdgeInsets.fromLTRB(20, 8, 20, 16);
  static const EdgeInsets tabletPagePadding = EdgeInsets.fromLTRB(
    32,
    16,
    32,
    24,
  );
  static const EdgeInsets desktopPagePadding = EdgeInsets.fromLTRB(
    40,
    20,
    40,
    32,
  );

  static const double bottomTabBarHeight = 68;
  static const double bottomTabHorizontalInset = 18;
  static const double bottomTabTopInset = 10;
}

/// Custom motion tokens following M3 emphasized easing.
class AppMotion {
  AppMotion._();
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);

  static const Curve emphasized = Cubic(0.2, 0.0, 0, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
}
