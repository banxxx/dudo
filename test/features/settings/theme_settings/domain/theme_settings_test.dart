import 'dart:convert';

import 'package:dudo/features/settings/theme_settings/domain/theme_settings.dart';
import 'package:dudo/shared/theme/dudo_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults are the paper mode with the pine accent', () {
    final settings = ThemeSettings.defaults();
    expect(settings.mode, DudoThemeMode.paper);
    expect(settings.accent, DudoAccent.pine);
  });

  test('JSON round trip keeps every field', () {
    const settings = ThemeSettings(
      mode: DudoThemeMode.system,
      accent: DudoAccent.lichee,
    );
    final decoded =
        ThemeSettings.fromJson(jsonDecode(jsonEncode(settings.toJson())));
    expect(decoded.mode, DudoThemeMode.system);
    expect(decoded.accent, DudoAccent.lichee);
  });

  test('unknown or missing values fall back to the defaults', () {
    final decoded = ThemeSettings.fromJson({'mode': 'neon', 'accent': 42});
    expect(decoded.mode, DudoThemeMode.paper);
    expect(decoded.accent, DudoAccent.pine);
    expect(ThemeSettings.fromJson(null).accent, DudoAccent.pine);
  });

  test('light pine palette keeps the design-spec primary family', () {
    final palette = DudoPalette.light(DudoAccent.pine);
    expect(palette.primary, const Color(0xFF5E6F5B));
    expect(palette.primaryContainer, const Color(0xFFDDE8D4));
    expect(palette.primaryContainerStrong, const Color(0xFFBFD0B5));
    expect(palette.onPrimaryContainer, const Color(0xFF1B2918));
    expect(palette.textPrimary, const Color(0xFF25251F));
    expect(palette.paperBackground, const Color(0xFFF8F4EA));
  });

  test('dark palette differs from light while keeping the accent', () {
    final light = DudoPalette.light(DudoAccent.pine);
    final dark = DudoPalette.dark(DudoAccent.pine);
    expect(dark.paperBackground, isNot(light.paperBackground));
    expect(dark.textPrimary, isNot(light.textPrimary));
    expect(dark.textPrimary, isNot(dark.paperBackground));
  });
}
