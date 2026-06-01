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
    background: Color(0xFFF4ECD8),
    foreground: Color(0xFF3E2C1C),
  );

  static const ReaderPalette night = ReaderPalette(
    name: '夜间',
    background: Color(0xFF121212),
    foreground: Color(0xFFCFCFCF),
  );

  static const ReaderPalette eyeCare = ReaderPalette(
    name: '护眼绿',
    background: Color(0xFFCCE8CF),
    foreground: Color(0xFF1B3A1F),
  );

  static const ReaderPalette plain = ReaderPalette(
    name: '简白',
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF202124),
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
  const ReaderPalette({
    required this.name,
    required this.background,
    required this.foreground,
  });
}
