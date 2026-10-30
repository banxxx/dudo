import 'package:flutter/material.dart';

/// The four accent choices offered on the theme page. Each is a seed for the
/// app's primary colour family: picking one restyles buttons, progress bars,
/// bookmarks and every other primary-tinted surface, while the warm paper
/// identity tokens (surface, text, outline) stay put.
enum DudoAccent {
  pine('松叶绿', Color(0xFF5E6F5B)),
  lichee('荔枝棕', Color(0xFFB98242)),
  ink('墨黑', Color(0xFF25251F)),
  almond('米杏', Color(0xFFC7B48B));

  const DudoAccent(this.label, this.swatch);

  final String label;

  /// Shown on the accent chip and used as the seed for the primary family, so
  /// the chip and the real primary stay visually related.
  final Color swatch;
}

/// A full set of app colour tokens for one brightness/accent combination.
/// [DudoColors] resolves to the active instance, which [DudoApp] swaps when the
/// user changes the theme mode or accent.
class DudoPalette {
  const DudoPalette({
    required this.isDark,
    required this.paperBackground,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceHigh,
    required this.ink,
    required this.onInk,
    required this.onInkMuted,
    required this.primary,
    required this.primaryContainer,
    required this.primaryContainerStrong,
    required this.primaryContainerMuted,
    required this.onPrimaryContainer,
    required this.primaryDark,
    required this.secondary,
    required this.secondaryDark,
    required this.secondaryContainer,
    required this.accent,
    required this.accentSoft,
    required this.accentMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.outlineVariant,
    required this.navigationStroke,
    required this.navigationShadow,
  });

  final bool isDark;
  final Color paperBackground;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceHigh;

  /// Background for masthead/hero cards that are intentionally "ink" in the
  /// light palette. In dark mode they become a raised charcoal paper surface
  /// instead of flipping to a bright cream card.
  final Color ink;

  /// Primary and muted foregrounds on [ink].
  final Color onInk;
  final Color onInkMuted;
  final Color primary;
  final Color primaryContainer;
  final Color primaryContainerStrong;
  final Color primaryContainerMuted;
  final Color onPrimaryContainer;
  final Color primaryDark;
  final Color secondary;
  final Color secondaryDark;
  final Color secondaryContainer;
  final Color accent;
  final Color accentSoft;
  final Color accentMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color outlineVariant;
  final Color navigationStroke;
  final Color navigationShadow;

  /// Value equality over every token, so consumers (e.g. remount keys) only
  /// react when the palette actually changes, not on every rebuild.
  @override
  bool operator ==(Object other) {
    return other is DudoPalette &&
        other.isDark == isDark &&
        other.paperBackground == paperBackground &&
        other.surface == surface &&
        other.surfaceLow == surfaceLow &&
        other.surfaceHigh == surfaceHigh &&
        other.ink == ink &&
        other.onInk == onInk &&
        other.onInkMuted == onInkMuted &&
        other.primary == primary &&
        other.primaryContainer == primaryContainer &&
        other.primaryContainerStrong == primaryContainerStrong &&
        other.primaryContainerMuted == primaryContainerMuted &&
        other.onPrimaryContainer == onPrimaryContainer &&
        other.primaryDark == primaryDark &&
        other.secondary == secondary &&
        other.secondaryDark == secondaryDark &&
        other.secondaryContainer == secondaryContainer &&
        other.accent == accent &&
        other.accentSoft == accentSoft &&
        other.accentMuted == accentMuted &&
        other.textPrimary == textPrimary &&
        other.textSecondary == textSecondary &&
        other.outline == outline &&
        other.outlineVariant == outlineVariant &&
        other.navigationStroke == navigationStroke &&
        other.navigationShadow == navigationShadow;
  }

  @override
  int get hashCode => Object.hashAll([
        isDark,
        paperBackground,
        surface,
        surfaceLow,
        surfaceHigh,
        ink,
        onInk,
        onInkMuted,
        primary,
        primaryContainer,
        primaryContainerStrong,
        primaryContainerMuted,
        onPrimaryContainer,
        primaryDark,
        secondary,
        secondaryDark,
        secondaryContainer,
        accent,
        accentSoft,
        accentMuted,
        textPrimary,
        textSecondary,
        outline,
        outlineVariant,
        navigationStroke,
        navigationShadow,
      ]);

  factory DudoPalette.light(DudoAccent accent) {
    final family = _primaryFamily(accent, Brightness.light);
    return DudoPalette._resolve(
      isDark: false,
      family: family,
      surface: const Color(0xFFFFFBF2),
      paperBackground: const Color(0xFFF8F4EA),
      surfaceLow: const Color(0xFFF3ECDD),
      surfaceHigh: const Color(0xFFFFF8EA),
      ink: const Color(0xFF25251F),
      onInk: const Color(0xFFFFF8EA),
      onInkMuted: const Color(0xFFD8CDBB),
      secondary: const Color(0xFF8A735A),
      secondaryDark: const Color(0xFF5B4B39),
      secondaryContainer: const Color(0xFFEFE0CC),
      accent: const Color(0xFFB98242),
      accentSoft: const Color(0xFFD3B98E),
      accentMuted: const Color(0xFFC7B48B),
      textPrimary: const Color(0xFF25251F),
      textSecondary: const Color(0xFF6F6B61),
      outline: const Color(0xFFD8CDBB),
      outlineVariant: const Color(0xFFE7DCC8),
      navigationStroke: const Color(0xCCFFFFFF),
      navigationShadow: const Color(0x2225251F),
    );
  }

  /// Quiet Paper Material Dark: charcoal-blue paper, warm ink text and a
  /// restrained sage/amber accent. Values follow `docs/dudo-dark-design-tokens.md`
  /// so components that use the raw tokens (rather than only [primary]) stay
  /// consistent with the night-reading design.
  factory DudoPalette.dark(DudoAccent accent) {
    final family = _primaryFamily(accent, Brightness.dark);
    return DudoPalette._resolve(
      isDark: true,
      family: family,
      surface: const Color(0xFF262930),
      paperBackground: const Color(0xFF1C1F22),
      surfaceLow: const Color(0xFF2E3136),
      surfaceHigh: const Color(0xFF3A3E45),
      ink: const Color(0xFF262930),
      onInk: const Color(0xFFF4EBD8),
      onInkMuted: const Color(0xFFB8AA91),
      secondary: const Color(0xFFB8AA91),
      secondaryDark: const Color(0xFFD3C6AC),
      secondaryContainer: const Color(0xFF3A3328),
      accent: const Color(0xFFD7A15D),
      accentSoft: const Color(0xFFC9A87C),
      accentMuted: const Color(0xFFA8875A),
      textPrimary: const Color(0xFFF4EBD8),
      textSecondary: const Color(0xFFB8AA91),
      outline: const Color(0xFF3E4248),
      outlineVariant: const Color(0xAA3E4248),
      navigationStroke: const Color(0xCC3E4248),
      navigationShadow: const Color(0x66000000),
    );
  }

  /// The primary family for one accent/brightness pair. The default pine accent
  /// keeps its hand-tuned light family so the app's light identity (and the
  /// design-spec token test) stays pixel-identical; every other combination is
  /// derived from the accent seed via `ColorScheme.fromSeed`, which also gives
  /// accessible on-tint pairs without hand-tuning four accent palettes.
  static _PrimaryFamily _primaryFamily(
      DudoAccent accent, Brightness brightness) {
    // The dark palette uses hand-tuned, low-saturation families instead of
    // `ColorScheme.fromSeed`: the generated dark containers were vivid greens
    // and olives that fought the warm charcoal reading surface.
    if (brightness == Brightness.dark) {
      return switch (accent) {
        DudoAccent.pine => const _PrimaryFamily(
            primary: Color(0xFF8EAD84),
            primaryContainer: Color(0xFF2A2E28),
            primaryContainerStrong: Color(0xFF3A4537),
            primaryContainerMuted: Color(0xFF23271F),
            onPrimaryContainer: Color(0xFFE9F0E3),
            primaryDark: Color(0xFFC2D6BA),
          ),
        DudoAccent.lichee => const _PrimaryFamily(
            primary: Color(0xFFD7A15D),
            primaryContainer: Color(0xFF3A2E1C),
            primaryContainerStrong: Color(0xFF4A3A22),
            primaryContainerMuted: Color(0xFF2E251A),
            onPrimaryContainer: Color(0xFFF3DDBB),
            primaryDark: Color(0xFFEBC58F),
          ),
        DudoAccent.ink => const _PrimaryFamily(
            primary: Color(0xFFC9C3B6),
            primaryContainer: Color(0xFF2E2C27),
            primaryContainerStrong: Color(0xFF3C3932),
            primaryContainerMuted: Color(0xFF26241F),
            onPrimaryContainer: Color(0xFFF4EBD8),
            primaryDark: Color(0xFFDED8CA),
          ),
        DudoAccent.almond => const _PrimaryFamily(
            primary: Color(0xFFD8C295),
            primaryContainer: Color(0xFF3A3324),
            primaryContainerStrong: Color(0xFF4A402C),
            primaryContainerMuted: Color(0xFF2C271C),
            onPrimaryContainer: Color(0xFFF4E6C8),
            primaryDark: Color(0xFFEAD7AE),
          ),
      };
    }
    if (accent == DudoAccent.pine && brightness == Brightness.light) {
      return const _PrimaryFamily(
        primary: Color(0xFF5E6F5B),
        primaryContainer: Color(0xFFDDE8D4),
        primaryContainerStrong: Color(0xFFBFD0B5),
        primaryContainerMuted: Color(0xFFC9D7C0),
        onPrimaryContainer: Color(0xFF1B2918),
        primaryDark: Color(0xFF4B5A45),
      );
    }
    final scheme = ColorScheme.fromSeed(
      seedColor: accent.swatch,
      brightness: brightness,
    );
    final primary = scheme.primary;
    final primaryContainer = scheme.primaryContainer;
    return _PrimaryFamily(
      primary: primary,
      primaryContainer: primaryContainer,
      primaryContainerStrong: Color.lerp(primaryContainer, primary, 0.4)!,
      primaryContainerMuted:
          Color.lerp(primaryContainer, scheme.surface, 0.35)!,
      onPrimaryContainer: scheme.onPrimaryContainer,
      primaryDark: Color.lerp(primary, const Color(0xFF000000), 0.18)!,
    );
  }

  /// Keeps the primary family fixed while the identity tokens are passed in.
  factory DudoPalette._resolve({
    required bool isDark,
    required _PrimaryFamily family,
    required Color paperBackground,
    required Color surface,
    required Color surfaceLow,
    required Color surfaceHigh,
    required Color ink,
    required Color onInk,
    required Color onInkMuted,
    required Color secondary,
    required Color secondaryDark,
    required Color secondaryContainer,
    required Color accent,
    required Color accentSoft,
    required Color accentMuted,
    required Color textPrimary,
    required Color textSecondary,
    required Color outline,
    required Color outlineVariant,
    required Color navigationStroke,
    required Color navigationShadow,
  }) {
    return DudoPalette(
      isDark: isDark,
      paperBackground: paperBackground,
      surface: surface,
      surfaceLow: surfaceLow,
      surfaceHigh: surfaceHigh,
      ink: ink,
      onInk: onInk,
      onInkMuted: onInkMuted,
      primary: family.primary,
      primaryContainer: family.primaryContainer,
      primaryContainerStrong: family.primaryContainerStrong,
      primaryContainerMuted: family.primaryContainerMuted,
      onPrimaryContainer: family.onPrimaryContainer,
      primaryDark: family.primaryDark,
      secondary: secondary,
      secondaryDark: secondaryDark,
      secondaryContainer: secondaryContainer,
      accent: accent,
      accentSoft: accentSoft,
      accentMuted: accentMuted,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      outline: outline,
      outlineVariant: outlineVariant,
      navigationStroke: navigationStroke,
      navigationShadow: navigationShadow,
    );
  }
}

/// The primary/accent colour family for one accent choice.
class _PrimaryFamily {
  const _PrimaryFamily({
    required this.primary,
    required this.primaryContainer,
    required this.primaryContainerStrong,
    required this.primaryContainerMuted,
    required this.onPrimaryContainer,
    required this.primaryDark,
  });

  final Color primary;
  final Color primaryContainer;
  final Color primaryContainerStrong;
  final Color primaryContainerMuted;
  final Color onPrimaryContainer;
  final Color primaryDark;
}
