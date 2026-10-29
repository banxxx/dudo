/// Which backend turns text into speech.
enum ReadAloudEngine { system, online }

/// Body format understood by a user supplied online TTS endpoint.
enum OnlineTtsFormat {
  /// `Content-Type: text/plain`, the whole body is the text to speak.
  text,

  /// JSON body with `text`, `voice` and `rate` keys.
  json,
}

/// Persisted configuration for reading aloud.
class ReadAloudSettings {
  const ReadAloudSettings({
    this.engine = ReadAloudEngine.system,
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
    this.onlineUrl,
    this.onlineToken,
    this.onlineVoice,
    this.onlineFormat = OnlineTtsFormat.text,
  });

  static const String preferenceKey = 'read_aloud.settings';

  final ReadAloudEngine engine;

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

  /// Endpoint returning audio bytes for the requested text.
  final String? onlineUrl;

  /// Optional token sent as `Authorization: Bearer <token>`.
  final String? onlineToken;

  /// Optional voice name forwarded to the online endpoint.
  final String? onlineVoice;

  final OnlineTtsFormat onlineFormat;

  factory ReadAloudSettings.defaults() => const ReadAloudSettings();

  /// flutter_tts takes `0.0 - 1.0` where `0.5` is normal speed on both
  /// Android and iOS, so the UI multiplier is mapped onto that range.
  double get ttsRate => (0.5 * speechRate).clamp(0.1, 1.0);

  String get voiceLabel => voiceName == null ? '系统语音' : (voiceLocale ?? '系统语音');

  bool get hasOnlineEndpoint =>
      onlineUrl != null && onlineUrl!.trim().isNotEmpty;

  ReadAloudSettings copyWith({
    ReadAloudEngine? engine,
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
    String? onlineUrl,
    bool clearOnlineUrl = false,
    String? onlineToken,
    bool clearOnlineToken = false,
    String? onlineVoice,
    bool clearOnlineVoice = false,
    OnlineTtsFormat? onlineFormat,
  }) {
    return ReadAloudSettings(
      engine: engine ?? this.engine,
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
      onlineUrl: clearOnlineUrl ? null : (onlineUrl ?? this.onlineUrl),
      onlineToken: clearOnlineToken ? null : (onlineToken ?? this.onlineToken),
      onlineVoice: clearOnlineVoice ? null : (onlineVoice ?? this.onlineVoice),
      onlineFormat: onlineFormat ?? this.onlineFormat,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'engine': engine.name,
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
      'onlineUrl': onlineUrl,
      'onlineToken': onlineToken,
      'onlineVoice': onlineVoice,
      'onlineFormat': onlineFormat.name,
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
      engine: _readEngine(json['engine']),
      voiceName: hasVoice ? voiceName.trim() : null,
      voiceLocale: hasVoice && voiceLocale is String && voiceLocale.isNotEmpty
          ? voiceLocale
          : null,
      language:
          json['language'] is String && (json['language'] as String).isNotEmpty
              ? json['language'] as String
              : defaults.language,
      speechRate:
          _readDouble(json['speechRate'], defaults.speechRate, 0.5, 2.0),
      pitch: _readDouble(json['pitch'], defaults.pitch, 0.5, 2.0),
      volume: _readDouble(json['volume'], defaults.volume, 0.0, 1.0),
      timerEnabled: _readBool(json['timerEnabled'], defaults.timerEnabled),
      timerMinutes:
          _readInt(json['timerMinutes'], defaults.timerMinutes, 5, 120),
      backgroundEnabled:
          _readBool(json['backgroundEnabled'], defaults.backgroundEnabled),
      paragraphFollowEnabled: _readBool(
        json['paragraphFollowEnabled'],
        defaults.paragraphFollowEnabled,
      ),
      onlineUrl: _readString(json['onlineUrl']),
      onlineToken: _readString(json['onlineToken']),
      onlineVoice: _readString(json['onlineVoice']),
      onlineFormat: _readFormat(json['onlineFormat']),
    );
  }

  static ReadAloudEngine _readEngine(Object? value) {
    if (value is String) {
      for (final engine in ReadAloudEngine.values) {
        if (engine.name == value) return engine;
      }
    }
    return ReadAloudEngine.system;
  }

  static OnlineTtsFormat _readFormat(Object? value) {
    if (value is String) {
      for (final format in OnlineTtsFormat.values) {
        if (format.name == value) return format;
      }
    }
    return OnlineTtsFormat.text;
  }

  static String? _readString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static double _readDouble(
      Object? value, double fallback, double min, double max) {
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
        other.engine == engine &&
        other.voiceName == voiceName &&
        other.voiceLocale == voiceLocale &&
        other.language == language &&
        other.speechRate == speechRate &&
        other.pitch == pitch &&
        other.volume == volume &&
        other.timerEnabled == timerEnabled &&
        other.timerMinutes == timerMinutes &&
        other.backgroundEnabled == backgroundEnabled &&
        other.paragraphFollowEnabled == paragraphFollowEnabled &&
        other.onlineUrl == onlineUrl &&
        other.onlineToken == onlineToken &&
        other.onlineVoice == onlineVoice &&
        other.onlineFormat == onlineFormat;
  }

  @override
  int get hashCode => Object.hashAll([
        engine,
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
        onlineUrl,
        onlineToken,
        onlineVoice,
        onlineFormat,
      ]);
}
