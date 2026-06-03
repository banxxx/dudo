import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'app_fonts.dart';

/// Material 3 theme builder for dudo.
///
/// We follow the Material You guidance: rich elevation tints, dynamic colors
/// when available, otherwise our brand seed `#446355`.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF446355);

  static ColorScheme lightScheme(ColorScheme? dynamicScheme) {
    if (dynamicScheme != null) {
      return dynamicScheme.harmonized();
    }
    return ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
  }

  static ColorScheme darkScheme(ColorScheme? dynamicScheme) {
    if (dynamicScheme != null) {
      return dynamicScheme.harmonized();
    }
    return ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
  }

  static ThemeData build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: scheme.surface,
    );

    final textTheme = base.textTheme
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .apply(fontFamily: DudoFonts.sansSc);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 3,
        surfaceTintColor: scheme.surfaceTint,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        color: scheme.surfaceContainerLow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Reader background presets — independent of the global Material You theme.
class ReaderTheme {
  ReaderTheme._();

  static const ReaderPalette parchment = ReaderPalette(
    name: '羊皮纸',
    background: Color(0xFFF8F4EA),
    foreground: Color(0xFF25251F),
    backgroundEnd: Color(0xFFF3ECDD),
    panel: Color(0xEAFFF8EA),
    panelStrong: Color(0xF2FFF8EA),
    outline: Color(0xAAD8CDBB),
    mutedForeground: Color(0xFF8A735A),
    accent: Color(0xFF5E6F5B),
  );

  static const ReaderPalette night = ReaderPalette(
    name: '夜间',
    background: Color(0xFF121212),
    foreground: Color(0xFFCFCFCF),
    backgroundEnd: Color(0xFF1F1F1F),
    panel: Color(0xEA252525),
    panelStrong: Color(0xF2303030),
    outline: Color(0x663E4248),
    mutedForeground: Color(0xFF9F9F9F),
    accent: Color(0xFF8EAD84),
  );

  static const ReaderPalette eyeCare = ReaderPalette(
    name: '护眼绿',
    background: Color(0xFFE8F1DD),
    foreground: Color(0xFF1B3A1F),
    backgroundEnd: Color(0xFFD8E8CF),
    panel: Color(0xEAF7F7E9),
    panelStrong: Color(0xF2F7F7E9),
    outline: Color(0x889CB48D),
    mutedForeground: Color(0xFF53674A),
    accent: Color(0xFF5E6F5B),
  );

  static const ReaderPalette plain = ReaderPalette(
    name: '简白',
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF202124),
    backgroundEnd: Color(0xFFF4F1EA),
    panel: Color(0xEAFFFFFF),
    panelStrong: Color(0xF2FFFFFF),
    outline: Color(0x88D7D2C7),
    mutedForeground: Color(0xFF6F6B61),
    accent: Color(0xFF5E6F5B),
  );

  static const List<ReaderPalette> presets = <ReaderPalette>[
    parchment,
    eyeCare,
    plain,
    night,
  ];
}

@immutable
class ReaderPalette {
  final String name;
  final Color background;
  final Color foreground;
  final Color? backgroundEnd;
  final Color? panel;
  final Color? panelStrong;
  final Color? outline;
  final Color? mutedForeground;
  final Color? accent;

  const ReaderPalette({
    required this.name,
    required this.background,
    required this.foreground,
    this.backgroundEnd,
    this.panel,
    this.panelStrong,
    this.outline,
    this.mutedForeground,
    this.accent,
  });
}
