import 'package:flutter/material.dart';

class DudoColors {
  DudoColors._();

  static const Color paperBackground = Color(0xFFF8F4EA);
  static const Color surface = Color(0xFFFFFBF2);
  static const Color surfaceLow = Color(0xFFF3ECDD);
  static const Color surfaceHigh = Color(0xFFFFF8EA);
  static const Color primary = Color(0xFF5E6F5B);
  static const Color primaryContainer = Color(0xFFDDE8D4);
  static const Color primaryContainerStrong = Color(0xFFBFD0B5);
  static const Color primaryContainerMuted = Color(0xFFC9D7C0);
  static const Color onPrimaryContainer = Color(0xFF1B2918);
  static const Color primaryDark = Color(0xFF4B5A45);
  static const Color secondary = Color(0xFF8A735A);
  static const Color secondaryDark = Color(0xFF5B4B39);
  static const Color secondaryContainer = Color(0xFFEFE0CC);
  static const Color accent = Color(0xFFB98242);
  static const Color accentSoft = Color(0xFFD3B98E);
  static const Color accentMuted = Color(0xFFC7B48B);
  static const Color textPrimary = Color(0xFF25251F);
  static const Color textSecondary = Color(0xFF6F6B61);
  static const Color outline = Color(0xFFD8CDBB);
  static const Color outlineVariant = Color(0xFFE7DCC8);
  static const Color navigationStroke = Color(0xCCFFFFFF);
  static const Color navigationShadow = Color(0x2225251F);

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
