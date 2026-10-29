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

  bool get isChinese => locale.toLowerCase().startsWith('zh');

  /// Short label used by the settings page, e.g. `中文 · ccc`.
  String get displayName {
    final parts = name.split('-').where((part) => part.isNotEmpty).toList();
    final label = isChinese ? '中文' : locale;
    return parts.isEmpty ? label : '$label · ${parts.last}';
  }

  static TtsVoice? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final locale = raw['locale'];
    if (name is! String || name.isEmpty || locale is! String) return null;
    final identifier = raw['identifier'];
    return TtsVoice(
      name: name,
      locale: locale,
      identifier: identifier is String && identifier.isNotEmpty
          ? identifier
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TtsVoice &&
        other.name == name &&
        other.locale == locale;
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
