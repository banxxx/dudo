/// Preferences that control how cached chapter downloads are scheduled.
///
/// The download queue reads [concurrency] when it decides how many books may
/// run at once. The value is persisted so it survives restarts.
class OfflineCacheSettings {
  const OfflineCacheSettings({this.concurrency = 3});

  static const String preferenceKey = 'offline_cache.settings';

  /// The options shown by the segmented control.
  static const List<int> concurrencyOptions = [1, 2, 3, 5];

  /// How many books may download chapter content at the same time.
  final int concurrency;

  factory OfflineCacheSettings.defaults() => const OfflineCacheSettings();

  OfflineCacheSettings copyWith({int? concurrency}) {
    return OfflineCacheSettings(concurrency: concurrency ?? this.concurrency);
  }

  Map<String, Object?> toJson() {
    return {'concurrency': concurrency};
  }

  /// Tolerant decode: a removed or hand-edited option falls back to the
  /// default instead of breaking the page.
  factory OfflineCacheSettings.fromJson(Object? json) {
    if (json is! Map) return OfflineCacheSettings.defaults();
    final value = json['concurrency'];
    if (value is int && concurrencyOptions.contains(value)) {
      return OfflineCacheSettings(concurrency: value);
    }
    return OfflineCacheSettings.defaults();
  }

  @override
  bool operator ==(Object other) {
    return other is OfflineCacheSettings && other.concurrency == concurrency;
  }

  @override
  int get hashCode => concurrency.hashCode;
}
