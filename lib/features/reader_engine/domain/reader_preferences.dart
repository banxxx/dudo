import 'reader_settings.dart';
import 'reader_theme.dart';
import 'reader_turn_mode.dart';

/// The reader's typography, theme and chrome settings. Stored in
/// `app_preferences` so they survive closing the reader and restarting the app.
class ReaderPreferences {
  const ReaderPreferences({
    required this.paletteId,
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.pageHorizontalMargin,
    required this.firstLineIndentEnabled,
    required this.textEnhancementEnabled,
    required this.turnMode,
    required this.brightness,
    required this.followSystemBrightness,
    required this.eyeComfortEnhanced,
    required this.timeBatteryHidden,
    required this.chapterProgressHidden,
    required this.systemStatusBarHidden,
    required this.pageEdgeHidden,
    required this.gestureNavigationBlocked,
    required this.volumePageTurnEnabled,
  });

  factory ReaderPreferences.defaults() {
    return const ReaderPreferences(
      paletteId: 'parchment',
      fontSize: 19,
      lineHeight: 1.72,
      paragraphSpacing: 15,
      pageHorizontalMargin: ReaderSettings.defaultPageHorizontalMargin,
      firstLineIndentEnabled: true,
      textEnhancementEnabled: false,
      turnMode: ReaderTurnMode.slide,
      brightness: 1,
      followSystemBrightness: false,
      eyeComfortEnhanced: false,
      timeBatteryHidden: false,
      chapterProgressHidden: false,
      systemStatusBarHidden: true,
      pageEdgeHidden: false,
      gestureNavigationBlocked: true,
      volumePageTurnEnabled: true,
    );
  }

  /// Restores preferences from JSON, clamping every value and falling back to
  /// the defaults for missing or malformed fields.
  factory ReaderPreferences.fromJson(Object? json) {
    final defaults = ReaderPreferences.defaults();
    if (json is! Map) return defaults;

    double number(Object? value, double fallback) =>
        value is num ? value.toDouble() : fallback;
    bool flag(Object? value, bool fallback) => value is bool ? value : fallback;

    final paletteId = json['paletteId'];
    final turnMode = json['turnMode'];

    return ReaderPreferences(
      paletteId: paletteId is String &&
              ReaderTheme.paletteById(paletteId).id == paletteId
          ? paletteId
          : defaults.paletteId,
      fontSize: ReaderSettings.clampFontSize(
        number(json['fontSize'], defaults.fontSize),
      ),
      lineHeight: number(json['lineHeight'], defaults.lineHeight)
          .clamp(1.2, 2.6)
          .toDouble(),
      paragraphSpacing: ReaderSettings.clampParagraphSpacing(
        number(json['paragraphSpacing'], defaults.paragraphSpacing),
      ),
      pageHorizontalMargin: ReaderSettings.clampPageHorizontalMargin(
        number(json['pageHorizontalMargin'], defaults.pageHorizontalMargin),
      ),
      firstLineIndentEnabled: flag(
        json['firstLineIndentEnabled'],
        defaults.firstLineIndentEnabled,
      ),
      textEnhancementEnabled: flag(
        json['textEnhancementEnabled'],
        defaults.textEnhancementEnabled,
      ),
      turnMode: ReaderTurnMode.values.firstWhere(
        (mode) => mode.name == turnMode,
        orElse: () => defaults.turnMode,
      ),
      brightness: number(json['brightness'], defaults.brightness)
          .clamp(0.1, 1.0)
          .toDouble(),
      followSystemBrightness: flag(
        json['followSystemBrightness'],
        defaults.followSystemBrightness,
      ),
      eyeComfortEnhanced: flag(
        json['eyeComfortEnhanced'],
        defaults.eyeComfortEnhanced,
      ),
      timeBatteryHidden: flag(
        json['timeBatteryHidden'],
        defaults.timeBatteryHidden,
      ),
      chapterProgressHidden: flag(
        json['chapterProgressHidden'],
        defaults.chapterProgressHidden,
      ),
      systemStatusBarHidden: flag(
        json['systemStatusBarHidden'],
        defaults.systemStatusBarHidden,
      ),
      pageEdgeHidden: flag(json['pageEdgeHidden'], defaults.pageEdgeHidden),
      gestureNavigationBlocked: flag(
        json['gestureNavigationBlocked'],
        defaults.gestureNavigationBlocked,
      ),
      volumePageTurnEnabled: flag(
        json['volumePageTurnEnabled'],
        defaults.volumePageTurnEnabled,
      ),
    );
  }

  static const String preferenceKey = 'reader.preferences';

  final String paletteId;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final double pageHorizontalMargin;
  final bool firstLineIndentEnabled;
  final bool textEnhancementEnabled;
  final ReaderTurnMode turnMode;
  final double brightness;
  final bool followSystemBrightness;
  final bool eyeComfortEnhanced;
  final bool timeBatteryHidden;
  final bool chapterProgressHidden;
  final bool systemStatusBarHidden;
  final bool pageEdgeHidden;
  final bool gestureNavigationBlocked;
  final bool volumePageTurnEnabled;

  ReaderPalette get palette => ReaderTheme.paletteById(paletteId);

  ReaderPreferences copyWith({
    String? paletteId,
    double? fontSize,
    double? lineHeight,
    double? paragraphSpacing,
    double? pageHorizontalMargin,
    bool? firstLineIndentEnabled,
    bool? textEnhancementEnabled,
    ReaderTurnMode? turnMode,
    double? brightness,
    bool? followSystemBrightness,
    bool? eyeComfortEnhanced,
    bool? timeBatteryHidden,
    bool? chapterProgressHidden,
    bool? systemStatusBarHidden,
    bool? pageEdgeHidden,
    bool? gestureNavigationBlocked,
    bool? volumePageTurnEnabled,
  }) {
    return ReaderPreferences(
      paletteId: paletteId ?? this.paletteId,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      pageHorizontalMargin: pageHorizontalMargin ?? this.pageHorizontalMargin,
      firstLineIndentEnabled:
          firstLineIndentEnabled ?? this.firstLineIndentEnabled,
      textEnhancementEnabled:
          textEnhancementEnabled ?? this.textEnhancementEnabled,
      turnMode: turnMode ?? this.turnMode,
      brightness: brightness ?? this.brightness,
      followSystemBrightness:
          followSystemBrightness ?? this.followSystemBrightness,
      eyeComfortEnhanced: eyeComfortEnhanced ?? this.eyeComfortEnhanced,
      timeBatteryHidden: timeBatteryHidden ?? this.timeBatteryHidden,
      chapterProgressHidden:
          chapterProgressHidden ?? this.chapterProgressHidden,
      systemStatusBarHidden:
          systemStatusBarHidden ?? this.systemStatusBarHidden,
      pageEdgeHidden: pageEdgeHidden ?? this.pageEdgeHidden,
      gestureNavigationBlocked:
          gestureNavigationBlocked ?? this.gestureNavigationBlocked,
      volumePageTurnEnabled:
          volumePageTurnEnabled ?? this.volumePageTurnEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'paletteId': paletteId,
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'paragraphSpacing': paragraphSpacing,
      'pageHorizontalMargin': pageHorizontalMargin,
      'firstLineIndentEnabled': firstLineIndentEnabled,
      'textEnhancementEnabled': textEnhancementEnabled,
      'turnMode': turnMode.name,
      'brightness': brightness,
      'followSystemBrightness': followSystemBrightness,
      'eyeComfortEnhanced': eyeComfortEnhanced,
      'timeBatteryHidden': timeBatteryHidden,
      'chapterProgressHidden': chapterProgressHidden,
      'systemStatusBarHidden': systemStatusBarHidden,
      'pageEdgeHidden': pageEdgeHidden,
      'gestureNavigationBlocked': gestureNavigationBlocked,
      'volumePageTurnEnabled': volumePageTurnEnabled,
    };
  }
}
