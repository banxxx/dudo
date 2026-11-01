/// Explains why [url] cannot be used as a Dudo Sync server, or `null` when it
/// looks usable. HTTP is only allowed for loopback addresses so a local
/// development server keeps working while real tokens always travel over TLS.
String? dataSyncUrlError(String? url) {
  final value = url?.trim() ?? '';
  if (value.isEmpty) return '请填写服务器地址';
  final uri = Uri.tryParse(value);
  if (uri == null) return '服务器地址格式不正确';
  if (!uri.hasScheme) return '地址需以 https:// 开头';
  if (uri.scheme != 'https' && uri.scheme != 'http') {
    return '仅支持 https:// 或 http:// 地址';
  }
  if (uri.host.isEmpty) return '地址缺少服务器域名或 IP';
  if (uri.scheme == 'http' && !_isLoopback(uri.host)) {
    return '同步服务需要使用 HTTPS 地址';
  }
  return null;
}

bool _isLoopback(String host) {
  return host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '10.0.2.2' ||
      host == '::1';
}

/// Persisted configuration for syncing with a self-hosted Dudo Sync API.
///
/// The server URL and access token are stored on this device only; they are
/// never uploaded in a sync snapshot. [lastSyncedAt] is also local metadata.
class DataSyncSettings {
  const DataSyncSettings({
    this.enabled = true,
    this.progress = true,
    this.annotations = true,
    this.settings = true,
    this.serverUrl,
    this.accessToken,
    this.lastSyncedAt,
  });

  static const String preferenceKey = 'data_sync.settings';

  /// Whether automatic sync is attempted while the app is running.
  final bool enabled;

  /// Shelf books and their reading progress.
  final bool progress;

  /// Bookmarks, highlights and notes.
  final bool annotations;

  /// Theme, typography and page-turn preferences.
  final bool settings;

  /// Root URL of the self-hosted sync server, e.g. `https://sync.example.com`.
  final String? serverUrl;

  /// Optional bearer token sent with every request.
  final String? accessToken;

  /// When the last successful sync finished, stored on this device.
  final DateTime? lastSyncedAt;

  factory DataSyncSettings.defaults() => const DataSyncSettings();

  bool get isConfigured => serverUrl != null && serverUrl!.trim().isNotEmpty;

  bool get hasScope => progress || annotations || settings;

  /// Value shown on the settings entry row.
  String get entryLabel {
    if (!isConfigured) return '未连接';
    return enabled ? '自动同步' : '手动同步';
  }

  DataSyncSettings copyWith({
    bool? enabled,
    bool? progress,
    bool? annotations,
    bool? settings,
    String? serverUrl,
    bool clearServerUrl = false,
    String? accessToken,
    bool clearAccessToken = false,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
  }) {
    return DataSyncSettings(
      enabled: enabled ?? this.enabled,
      progress: progress ?? this.progress,
      annotations: annotations ?? this.annotations,
      settings: settings ?? this.settings,
      serverUrl: clearServerUrl ? null : (serverUrl ?? this.serverUrl),
      accessToken: clearAccessToken ? null : (accessToken ?? this.accessToken),
      lastSyncedAt:
          clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'enabled': enabled,
      'progress': progress,
      'annotations': annotations,
      'settings': settings,
      'serverUrl': serverUrl,
      'accessToken': accessToken,
      'lastSyncedAt': lastSyncedAt?.toUtc().toIso8601String(),
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
      annotations: _readAnnotations(json),
      settings: _readBool(json['settings'], defaults.settings),
      serverUrl: _readString(json['serverUrl']),
      accessToken: _readString(json['accessToken']),
      lastSyncedAt: _readDate(json['lastSyncedAt']),
    );
  }

  /// Older builds stored bookmarks and highlights as two switches. Their union
  /// becomes the single annotation scope, so existing users keep both kinds.
  static bool _readAnnotations(Map<dynamic, dynamic> json) {
    final annotations = json['annotations'];
    if (annotations is bool) return annotations;
    final bookmarks = json['bookmarks'];
    final highlights = json['highlights'];
    if (bookmarks is bool || highlights is bool) {
      return (bookmarks is bool ? bookmarks : true) ||
          (highlights is bool ? highlights : true);
    }
    return true;
  }

  static bool _readBool(Object? value, bool fallback) {
    return value is bool ? value : fallback;
  }

  static String? _readString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _readDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  @override
  bool operator ==(Object other) {
    return other is DataSyncSettings &&
        other.enabled == enabled &&
        other.progress == progress &&
        other.annotations == annotations &&
        other.settings == settings &&
        other.serverUrl == serverUrl &&
        other.accessToken == accessToken &&
        other.lastSyncedAt == lastSyncedAt;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        progress,
        annotations,
        settings,
        serverUrl,
        accessToken,
        lastSyncedAt,
      );
}
