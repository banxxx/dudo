part of '../../../reader_controls.dart';

// 正文阅读页控件主题入口：所有阅读控件和二级弹窗的颜色都从这里取。
// 纸页色板保持原值；护眼色板独立适配，后续暖棕、夜读也在这里继续扩展。
class _ReaderControlTheme {
  const _ReaderControlTheme._({
    required this.overlay,
    required this.surface,
    required this.text,
    required this.action,
    required this.themePicker,
  });

  factory _ReaderControlTheme.fromPalette(ReaderPalette palette) {
    if (palette.name == ReaderTheme.eyeCare.name) {
      return _eyeCare;
    }
    return _paper;
  }

  // 纸页主题：保留当前 UI 的原始颜色，不做任何改动。
  static const _paper = _ReaderControlTheme._(
    overlay: _ReaderOverlayThemeTokens(
      barrier: Color(0x3325251F),
      glassHighlight: Color(0x12FFFFFF),
      transparent: Colors.transparent,
    ),
    surface: _ReaderSurfaceThemeTokens(
      panel: Color(0xFFFFF8EA),
      panelHigh: Color(0xFFFFFBF2),
      panelLow: Color(0xFFF3ECDD),
      page: Color(0xFFF8F4EA),
      outline: Color(0xFFE7DCC8),
      outlineStrong: Color(0xFFD8CDBB),
      shadow: Color(0x3325251F),
      chromeShadow: Color(0x1F25251F),
      sheetShadow: Color(0x2625251F),
    ),
    text: _ReaderTextThemeTokens(
      primary: Color(0xFF25251F),
      secondary: Color(0xFF8A735A),
      tertiary: Color(0xFF6F6B61),
      accentText: Color(0xFF1B2918),
      inverse: Color(0xFFFFF8EA),
      secondaryWeak: Color(0x668A735A),
    ),
    action: _ReaderActionThemeTokens(
      accent: Color(0xFF5E6F5B),
      accentSoft: Color(0xFFDDE8D4),
      darkFill: Color(0xFF25251F),
      inactiveFill: Color(0xFFF3ECDD),
      inactiveLine: Color(0xFFD8CDBB),
      paperTexture: Color(0xFFEFE3CF),
      whiteHighlight: Colors.white,
    ),
    themePicker: _ReaderThemePickerThemeTokens(
      paper: Color(0xFFF8F4EA),
      panel: Color(0xFFFFF8EA),
      surfaceLow: Color(0xFFF3ECDD),
      surfaceLine: Color(0xFFD8CDBB),
      ink: Color(0xFF25251F),
      muted: Color(0xFF8A735A),
      secondaryText: Color(0xFF6F6B61),
      green: Color(0xFF5E6F5B),
      greenSoft: Color(0xFFDDE8D4),
      greenLine: Color(0xFFBFD0B5),
      warmBrown: Color(0xFFE8D7BD),
      warmBrownLine: Color(0xFFD0B58D),
    ),
  );

  // 护眼主题：低饱和浅绿 + 米白面板，保证所有控件和弹窗都有明确背景色。
  static const _eyeCare = _ReaderControlTheme._(
    overlay: _ReaderOverlayThemeTokens(
      barrier: Color(0x33203324),
      glassHighlight: Color(0x10FFFFFF),
      transparent: Colors.transparent,
    ),
    surface: _ReaderSurfaceThemeTokens(
      panel: Color(0xFFF6FAEA),
      panelHigh: Color(0xFFFBFDF2),
      panelLow: Color(0xFFE3EED7),
      page: Color(0xFFEAF3DF),
      outline: Color(0xFFC5D7B8),
      outlineStrong: Color(0xFFADC69E),
      shadow: Color(0x2A203A25),
      chromeShadow: Color(0x1A203A25),
      sheetShadow: Color(0x24203A25),
    ),
    text: _ReaderTextThemeTokens(
      primary: Color(0xFF203A25),
      secondary: Color(0xFF53674A),
      tertiary: Color(0xFF65765E),
      accentText: Color(0xFF173314),
      inverse: Color(0xFFF6FAEA),
      secondaryWeak: Color(0x6653674A),
    ),
    action: _ReaderActionThemeTokens(
      accent: Color(0xFF5C7C4F),
      accentSoft: Color(0xFFB8D5AA),
      darkFill: Color(0xFF203A25),
      inactiveFill: Color(0xFFE3EED7),
      inactiveLine: Color(0xFFADC69E),
      paperTexture: Color(0xFFEDF4E3),
      whiteHighlight: Colors.white,
    ),
    themePicker: _ReaderThemePickerThemeTokens(
      paper: Color(0xFFEAF3DF),
      panel: Color(0xFFF6FAEA),
      surfaceLow: Color(0xFFE3EED7),
      surfaceLine: Color(0xFFADC69E),
      ink: Color(0xFF203A25),
      muted: Color(0xFF53674A),
      secondaryText: Color(0xFF65765E),
      green: Color(0xFF5C7C4F),
      greenSoft: Color(0xFFD7E8CC),
      greenLine: Color(0xFFC5D7B8),
      warmBrown: Color(0xFFE7D6B8),
      warmBrownLine: Color(0xFFC9B288),
    ),
  );

  final _ReaderOverlayThemeTokens overlay;
  final _ReaderSurfaceThemeTokens surface;
  final _ReaderTextThemeTokens text;
  final _ReaderActionThemeTokens action;
  final _ReaderThemePickerThemeTokens themePicker;
}

// 遮罩和透明态归类，避免散落在各个弹层里。
class _ReaderOverlayThemeTokens {
  const _ReaderOverlayThemeTokens({
    required this.barrier,
    required this.glassHighlight,
    required this.transparent,
  });

  final Color barrier;
  final Color glassHighlight;
  final Color transparent;
}

// 面板、边框、阴影等容器级颜色。
class _ReaderSurfaceThemeTokens {
  const _ReaderSurfaceThemeTokens({
    required this.panel,
    required this.panelHigh,
    required this.panelLow,
    required this.page,
    required this.outline,
    required this.outlineStrong,
    required this.shadow,
    required this.chromeShadow,
    required this.sheetShadow,
  });

  final Color panel;
  final Color panelHigh;
  final Color panelLow;
  final Color page;
  final Color outline;
  final Color outlineStrong;
  final Color shadow;
  final Color chromeShadow;
  final Color sheetShadow;
}

// 阅读控件文字颜色，不和正文文字 palette.foreground 混在一起。
class _ReaderTextThemeTokens {
  const _ReaderTextThemeTokens({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.accentText,
    required this.inverse,
    required this.secondaryWeak,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color accentText;
  final Color inverse;
  final Color secondaryWeak;
}

// 按钮、选中态、滑块、开关等交互颜色。
class _ReaderActionThemeTokens {
  const _ReaderActionThemeTokens({
    required this.accent,
    required this.accentSoft,
    required this.darkFill,
    required this.inactiveFill,
    required this.inactiveLine,
    required this.paperTexture,
    required this.whiteHighlight,
  });

  final Color accent;
  final Color accentSoft;
  final Color darkFill;
  final Color inactiveFill;
  final Color inactiveLine;
  final Color paperTexture;
  final Color whiteHighlight;
}

// 主题面板专用颜色角色，控制主题卡片、亮度、开关行等面板内部样式。
class _ReaderThemePickerThemeTokens {
  const _ReaderThemePickerThemeTokens({
    required this.paper,
    required this.panel,
    required this.surfaceLow,
    required this.surfaceLine,
    required this.ink,
    required this.muted,
    required this.secondaryText,
    required this.green,
    required this.greenSoft,
    required this.greenLine,
    required this.warmBrown,
    required this.warmBrownLine,
  });

  final Color paper;
  final Color panel;
  final Color surfaceLow;
  final Color surfaceLine;
  final Color ink;
  final Color muted;
  final Color secondaryText;
  final Color green;
  final Color greenSoft;
  final Color greenLine;
  final Color warmBrown;
  final Color warmBrownLine;
}

class _ReaderControlThemeScope extends InheritedWidget {
  const _ReaderControlThemeScope({
    required this.theme,
    required super.child,
  });

  final _ReaderControlTheme theme;

  static _ReaderControlTheme of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ReaderControlThemeScope>();
    assert(scope != null, 'Reader control theme scope is missing.');
    return scope!.theme;
  }

  @override
  bool updateShouldNotify(_ReaderControlThemeScope oldWidget) {
    return theme != oldWidget.theme;
  }
}

extension _ReaderControlThemeContext on BuildContext {
  _ReaderControlTheme get readerControls => _ReaderControlThemeScope.of(this);
}
