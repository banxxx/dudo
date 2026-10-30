/// Persisted configuration for cloud sync.
///
/// The cloud transport is not wired up yet, so these values record the user's
/// intent and are saved locally. The page reads them to show the honest
/// "未连接云端" state and the selected scope; a future transport will use the
/// same fields to decide what to push and pull.
class DataSyncSettings {
  const DataSyncSettings({
    this.enabled = true,
    this.progress = true,
    this.bookmarks = true,
    this.highlights = true,
    this.settings = true,
  });

  static const String preferenceKey = 'data_sync.settings';

  /// Whether cloud sync is attempted at all.
  final bool enabled;

  /// Reading progress (last chapter and position per book).
  final bool progress;

  /// Bookmarks and notes.
  final bool bookmarks;

  /// Highlighted passages.
  final bool highlights;

  /// Theme, typography and read-aloud preferences.
  final bool settings;

  factory DataSyncSettings.defaults() => const DataSyncSettings();

  /// Value shown on the settings entry row.
  String get entryLabel => enabled ? '已开启' : '已关闭';

  DataSyncSettings copyWith({
    bool? enabled,
    bool? progress,
    bool? bookmarks,
    bool? highlights,
    bool? settings,
  }) {
    return DataSyncSettings(
      enabled: enabled ?? this.enabled,
      progress: progress ?? this.progress,
      bookmarks: bookmarks ?? this.bookmarks,
      highlights: highlights ?? this.highlights,
      settings: settings ?? this.settings,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'enabled': enabled,
      'progress': progress,
      'bookmarks': bookmarks,
      'highlights': highlights,
      'settings': settings,
    };
  }

  /// Tolerant decode: every invalid field falls back to its default so a
  /// hand-edited preference file never breaks the settings page.
  factory DataSyncSettings.fromJson(Object? json) {
    if (json is! Map) return DataSyncSettings.defaults();
    final defaults = DataSyncSettings.defaults();

    return DataSyncSettings(
      enabled: _readBool(json['enabled'], defaults.enabled),
      progress: _readBool(json['progress'], defaults.progress),
      bookmarks: _readBool(json['bookmarks'], defaults.bookmarks),
      highlights: _readBool(json['highlights'], defaults.highlights),
      settings: _readBool(json['settings'], defaults.settings),
    );
  }

  static bool _readBool(Object? value, bool fallback) {
    return value is bool ? value : fallback;
  }

  @override
  bool operator ==(Object other) {
    return other is DataSyncSettings &&
        other.enabled == enabled &&
        other.progress == progress &&
        other.bookmarks == bookmarks &&
        other.highlights == highlights &&
        other.settings == settings;
  }

  @override
  int get hashCode =>
      Object.hash(enabled, progress, bookmarks, highlights, settings);
}
