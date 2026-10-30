/// How often the app checks the shelf's online books for new chapters.
enum ShelfUpdateFrequency {
  daily,
  everyThreeDays,
  weekly;

  /// Label shown in the settings row and on the frequency cards.
  String get label => switch (this) {
        ShelfUpdateFrequency.daily => '每天',
        ShelfUpdateFrequency.everyThreeDays => '每 3 天',
        ShelfUpdateFrequency.weekly => '每周',
      };

  /// Second line of the frequency card.
  String get hint => switch (this) {
        ShelfUpdateFrequency.daily => '每日检查',
        ShelfUpdateFrequency.everyThreeDays => '间隔三天',
        ShelfUpdateFrequency.weekly => '每周一次',
      };

  /// Minimum gap between two automatic checks.
  Duration get interval => switch (this) {
        ShelfUpdateFrequency.daily => const Duration(days: 1),
        ShelfUpdateFrequency.everyThreeDays => const Duration(days: 3),
        ShelfUpdateFrequency.weekly => const Duration(days: 7),
      };
}

/// Persisted configuration for keeping the shelf's online catalogs fresh.
///
/// The scheduled fetch itself reuses the remote book import pipeline; this
/// object only records the user's intent so every surface (settings row, update
/// page, future background worker) reads the same values.
class ShelfUpdateSettings {
  const ShelfUpdateSettings({
    this.enabled = true,
    this.frequency = ShelfUpdateFrequency.daily,
    this.wifiOnly = true,
    this.chapterAlerts = true,
  });

  static const String preferenceKey = 'shelf_update.settings';

  /// Whether the shelf is checked automatically at all.
  final bool enabled;

  /// How often the check runs while [enabled] is true.
  final ShelfUpdateFrequency frequency;

  /// Skip automatic checks on cellular data.
  final bool wifiOnly;

  /// Tell the user when a check turns up chapters not seen before.
  final bool chapterAlerts;

  factory ShelfUpdateSettings.defaults() => const ShelfUpdateSettings();

  /// Value shown on the settings entry row.
  String get entryLabel => enabled ? frequency.label : '已关闭';

  /// One-line summary of the active schedule, e.g. `每天 · 仅 Wi-Fi`.
  String get scheduleLabel {
    if (!enabled) return '自动更新已关闭';
    return [
      frequency.label,
      wifiOnly ? '仅 Wi-Fi' : '任意网络',
    ].join(' · ');
  }

  ShelfUpdateSettings copyWith({
    bool? enabled,
    ShelfUpdateFrequency? frequency,
    bool? wifiOnly,
    bool? chapterAlerts,
  }) {
    return ShelfUpdateSettings(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      chapterAlerts: chapterAlerts ?? this.chapterAlerts,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'enabled': enabled,
      'frequency': frequency.name,
      'wifiOnly': wifiOnly,
      'chapterAlerts': chapterAlerts,
    };
  }

  /// Tolerant decode: an unknown frequency or a hand-edited value falls back to
  /// its default instead of breaking the settings page.
  factory ShelfUpdateSettings.fromJson(Object? json) {
    if (json is! Map) return ShelfUpdateSettings.defaults();
    final defaults = ShelfUpdateSettings.defaults();

    return ShelfUpdateSettings(
      enabled: json['enabled'] is bool
          ? json['enabled'] as bool
          : defaults.enabled,
      frequency: _readFrequency(json['frequency']),
      wifiOnly: json['wifiOnly'] is bool
          ? json['wifiOnly'] as bool
          : defaults.wifiOnly,
      chapterAlerts: json['chapterAlerts'] is bool
          ? json['chapterAlerts'] as bool
          : defaults.chapterAlerts,
    );
  }

  static ShelfUpdateFrequency _readFrequency(Object? value) {
    if (value is String) {
      for (final frequency in ShelfUpdateFrequency.values) {
        if (frequency.name == value) return frequency;
      }
    }
    return ShelfUpdateFrequency.daily;
  }

  @override
  bool operator ==(Object other) {
    return other is ShelfUpdateSettings &&
        other.enabled == enabled &&
        other.frequency == frequency &&
        other.wifiOnly == wifiOnly &&
        other.chapterAlerts == chapterAlerts;
  }

  @override
  int get hashCode => Object.hash(enabled, frequency, wifiOnly, chapterAlerts);
}
