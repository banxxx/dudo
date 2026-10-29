import '../../../../shared/theme/dudo_palette.dart';

/// How the app chooses between the light and dark palette.
enum DudoThemeMode { paper, dark, system }

/// Persisted theme appearance settings: the light/dark mode plus the accent
/// that drives the primary colour family.
class ThemeSettings {
  const ThemeSettings({
    this.mode = DudoThemeMode.paper,
    this.accent = DudoAccent.pine,
  });

  static const String preferenceKey = 'theme.settings';

  /// The most recently seen settings, remembered so the next launch can start
  /// with the right palette before the database stream delivers its first
  /// value (otherwise every launch briefly flashes the default light theme).
  static ThemeSettings? _lastKnown;

  static ThemeSettings get lastKnown => _lastKnown ?? ThemeSettings.defaults();

  static void remember(ThemeSettings settings) => _lastKnown = settings;

  final DudoThemeMode mode;
  final DudoAccent accent;

  factory ThemeSettings.defaults() => const ThemeSettings();

  ThemeSettings copyWith({DudoThemeMode? mode, DudoAccent? accent}) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      accent: accent ?? this.accent,
    );
  }

  Map<String, Object?> toJson() {
    return {'mode': mode.name, 'accent': accent.name};
  }

  /// Tolerant decode: every missing or malformed field falls back to its
  /// default so a hand-edited preference file never breaks the theme.
  factory ThemeSettings.fromJson(Object? json) {
    if (json is! Map) return ThemeSettings.defaults();
    return ThemeSettings(
      mode: _enumByName(DudoThemeMode.values, json['mode']) ??
          DudoThemeMode.paper,
      accent: _enumByName(DudoAccent.values, json['accent']) ?? DudoAccent.pine,
    );
  }

  static T? _enumByName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
