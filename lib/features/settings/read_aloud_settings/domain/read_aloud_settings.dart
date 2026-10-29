/// Persisted configuration for reading aloud with the system TTS engine.
class ReadAloudSettings {
  const ReadAloudSettings({
    this.voiceName,
    this.voiceLocale,
    this.language = 'zh-CN',
    this.speechRate = 1.0,
    this.pitch = 1.0,
    this.volume = 0.8,
    this.timerEnabled = false,
    this.timerMinutes = 15,
    this.backgroundEnabled = true,
    this.paragraphFollowEnabled = true,
  });

  static const String preferenceKey = 'read_aloud.settings';

  /// Device voice name, `null` keeps the engine's default voice.
  final String? voiceName;

  /// Locale of the selected voice, used together with [voiceName].
  final String? voiceLocale;

  final String language;

  /// Playback multiplier shown in the UI, `1.0` is normal speed.
  final double speechRate;

  final double pitch;

  final double volume;

  final bool timerEnabled;

  final int timerMinutes;

  final bool backgroundEnabled;

  final bool paragraphFollowEnabled;

  factory ReadAloudSettings.defaults() => const ReadAloudSettings();

  /// flutter_tts takes `0.0 - 1.0` where `0.5` is normal speed on both
  /// Android and iOS, so the UI multiplier is mapped onto that range.
  double get ttsRate => (0.5 * speechRate).clamp(0.1, 1.0);

  String get voiceLabel => voiceName == null ? '系统语音' : (voiceLocale ?? '系统语音');

  ReadAloudSettings copyWith({
    String? voiceName,
    bool clearVoiceName = false,
    String? voiceLocale,
    String? language,
    double? speechRate,
    double? pitch,
    double? volume,
    bool? timerEnabled,
    int? timerMinutes,
    bool? backgroundEnabled,
    bool? paragraphFollowEnabled,
  }) {
    return ReadAloudSettings(
      voiceName: clearVoiceName ? null : (voiceName ?? this.voiceName),
      voiceLocale: clearVoiceName ? null : (voiceLocale ?? this.voiceLocale),
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      paragraphFollowEnabled:
          paragraphFollowEnabled ?? this.paragraphFollowEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'voiceName': voiceName,
      'voiceLocale': voiceLocale,
      'language': language,
      'speechRate': speechRate,
      'pitch': pitch,
      'volume': volume,
      'timerEnabled': timerEnabled,
      'timerMinutes': timerMinutes,
      'backgroundEnabled': backgroundEnabled,
      'paragraphFollowEnabled': paragraphFollowEnabled,
    };
  }

  /// Tolerant decode: every invalid or missing field falls back to its default
  /// so a hand-edited preference file never breaks the reader.
  factory ReadAloudSettings.fromJson(Object? json) {
    if (json is! Map) return ReadAloudSettings.defaults();
    final defaults = ReadAloudSettings.defaults();

    final voiceName = json['voiceName'];
    final voiceLocale = json['voiceLocale'];
    final hasVoice = voiceName is String && voiceName.trim().isNotEmpty;

    return ReadAloudSettings(
      voiceName: hasVoice ? voiceName.trim() : null,
      voiceLocale: hasVoice && voiceLocale is String && voiceLocale.isNotEmpty
          ? voiceLocale
          : null,
      language: json['language'] is String && (json['language'] as String).isNotEmpty
          ? json['language'] as String
          : defaults.language,
      speechRate:
          _readDouble(json['speechRate'], defaults.speechRate, 0.5, 2.0),
      pitch: _readDouble(json['pitch'], defaults.pitch, 0.5, 2.0),
      volume: _readDouble(json['volume'], defaults.volume, 0.0, 1.0),
      timerEnabled: _readBool(json['timerEnabled'], defaults.timerEnabled),
      timerMinutes: _readInt(json['timerMinutes'], defaults.timerMinutes, 5, 120),
      backgroundEnabled:
          _readBool(json['backgroundEnabled'], defaults.backgroundEnabled),
      paragraphFollowEnabled: _readBool(
        json['paragraphFollowEnabled'],
        defaults.paragraphFollowEnabled,
      ),
    );
  }

  static double _readDouble(Object? value, double fallback, double min,
      double max) {
    if (value is! num) return fallback;
    final parsed = value.toDouble();
    if (parsed.isNaN) return fallback;
    return parsed.clamp(min, max);
  }

  static int _readInt(Object? value, int fallback, int min, int max) {
    if (value is! num) return fallback;
    return value.toInt().clamp(min, max);
  }

  static bool _readBool(Object? value, bool fallback) {
    return value is bool ? value : fallback;
  }

  @override
  bool operator ==(Object other) {
    return other is ReadAloudSettings &&
        other.voiceName == voiceName &&
        other.voiceLocale == voiceLocale &&
        other.language == language &&
        other.speechRate == speechRate &&
        other.pitch == pitch &&
        other.volume == volume &&
        other.timerEnabled == timerEnabled &&
        other.timerMinutes == timerMinutes &&
        other.backgroundEnabled == backgroundEnabled &&
        other.paragraphFollowEnabled == paragraphFollowEnabled;
  }

  @override
  int get hashCode => Object.hash(
        voiceName,
        voiceLocale,
        language,
        speechRate,
        pitch,
        volume,
        timerEnabled,
        timerMinutes,
        backgroundEnabled,
        paragraphFollowEnabled,
      );
}
