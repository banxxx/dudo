import 'package:flutter/material.dart';

// 正文阅读主题：只服务正文阅读页，与应用全局 Material 主题无关。
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
    background: Color(0xFFEAF3DF),
    foreground: Color(0xFF203A25),
    backgroundEnd: Color(0xFFDCECCF),
    panel: Color(0xFFF6FAEA),
    panelStrong: Color(0xFFFBFDF2),
    outline: Color(0xFFB6CDA9),
    mutedForeground: Color(0xFF53674A),
    accent: Color(0xFF5C7C4F),
  );

  static const ReaderPalette warmBrown = ReaderPalette(
    name: '暖棕',
    background: Color(0xFFE8D7BD),
    foreground: Color(0xFF33281E),
    backgroundEnd: Color(0xFFD9C09A),
    panel: Color(0xEAF7E8D2),
    panelStrong: Color(0xF2F7E8D2),
    outline: Color(0x88D0B58D),
    mutedForeground: Color(0xFF7B6244),
    accent: Color(0xFF8A6A43),
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
    warmBrown,
    night,
  ];
}

@immutable
class ReaderPalette {
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

  final String name;
  final Color background;
  final Color foreground;
  final Color? backgroundEnd;
  final Color? panel;
  final Color? panelStrong;
  final Color? outline;
  final Color? mutedForeground;
  final Color? accent;
}
