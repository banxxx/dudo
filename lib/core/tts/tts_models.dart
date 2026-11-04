/// A voice reported by the platform TTS engine.
class TtsVoice {
  const TtsVoice({
    required this.name,
    required this.locale,
    this.identifier,
  });

  final String name;
  final String locale;
  final String? identifier;

  bool get isChinese =>
      locale.toLowerCase().startsWith('zh') ||
      locale.toLowerCase().startsWith('cmn');

  /// Network voices are synthesized by the platform engine and need a
  /// connection; local voices are installed on the device.
  bool get isNetwork => name.toLowerCase().contains('network');

  /// Readable language name used by the settings page, e.g. `普通话`.
  String get languageLabel {
    final value = locale.toLowerCase();
    if (value.startsWith('zh-tw') ||
        value.startsWith('zh-hant') ||
        value.startsWith('cmn-tw')) {
      return '台湾国语';
    }
    if (value.startsWith('zh-hk') ||
        value.startsWith('zh-yue') ||
        value.startsWith('yue') ||
        value.contains('cantonese')) {
      return '粤语';
    }
    if (value.startsWith('zh') || value.startsWith('cmn')) return '普通话';
    return locale;
  }

  /// Short label used by the settings page, e.g. `普通话 · 本地`.
  String get displayName => '$languageLabel · ${isNetwork ? '网络' : '本地'}';

  /// Secondary line shown under a voice, e.g. `系统语音 · zh-CN · 离线`.
  String get voiceMeta => '系统语音 · $locale · ${isNetwork ? '需联网' : '离线'}';

  static TtsVoice? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final locale = raw['locale'];
    if (name is! String || name.isEmpty || locale is! String) return null;
    final identifier = raw['identifier'];
    return TtsVoice(
      name: name,
      locale: locale,
      identifier:
          identifier is String && identifier.isNotEmpty ? identifier : null,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TtsVoice && other.name == name && other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(name, locale);
}

/// Engine-agnostic playback configuration resolved from the user settings.
class TtsConfig {
  const TtsConfig({
    this.language = 'zh-CN',
    this.rate = 0.5,
    this.pitch = 1.0,
    this.volume = 0.8,
    this.voiceName,
    this.voiceLocale,
  });

  final String language;
  final double rate;
  final double pitch;
  final double volume;
  final String? voiceName;
  final String? voiceLocale;
}
