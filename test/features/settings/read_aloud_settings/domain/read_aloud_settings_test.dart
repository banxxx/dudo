import 'dart:convert';

import 'package:dudo/features/settings/read_aloud_settings/domain/read_aloud_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults match the system voice at normal speed', () {
    final settings = ReadAloudSettings.defaults();

    expect(settings.voiceName, isNull);
    expect(settings.language, 'zh-CN');
    expect(settings.speechRate, 1.0);
    expect(settings.ttsRate, 0.5);
    expect(settings.pitch, 1.0);
    expect(settings.volume, 0.8);
    expect(settings.timerEnabled, isFalse);
    expect(settings.timerMinutes, 15);
    expect(settings.backgroundEnabled, isTrue);
    expect(settings.paragraphFollowEnabled, isTrue);
  });

  test('JSON round trip keeps every field', () {
    final settings = ReadAloudSettings.defaults().copyWith(
      voiceName: 'zh-cn-x-ccc-local',
      voiceLocale: 'zh-CN',
      speechRate: 1.3,
      pitch: 0.9,
      volume: 0.6,
      timerEnabled: true,
      timerMinutes: 30,
      backgroundEnabled: false,
      paragraphFollowEnabled: false,
    );

    final decoded = ReadAloudSettings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())),
    );

    expect(decoded, settings);
  });

  test('ttsRate maps the UI multiplier onto the engine range', () {
    expect(ReadAloudSettings.defaults().copyWith(speechRate: 2.0).ttsRate, 1.0);
    expect(
        ReadAloudSettings.defaults().copyWith(speechRate: 0.5).ttsRate, 0.25);
  });

  test('out of range values are clamped instead of rejected', () {
    final settings = ReadAloudSettings.fromJson({
      'speechRate': 9,
      'pitch': 0.1,
      'volume': -2,
      'timerMinutes': 900,
    });

    expect(settings.speechRate, 2.0);
    expect(settings.pitch, 0.5);
    expect(settings.volume, 0.0);
    expect(settings.timerMinutes, 120);
  });

  test('missing or malformed values fall back to the defaults', () {
    expect(ReadAloudSettings.fromJson('nope'), ReadAloudSettings.defaults());
    expect(ReadAloudSettings.fromJson(const {}), ReadAloudSettings.defaults());
    expect(
      ReadAloudSettings.fromJson(const {'voiceName': '  '}).voiceName,
      isNull,
    );
  });

  test('copyWith can clear the selected voice', () {
    final withVoice = ReadAloudSettings.defaults().copyWith(
      voiceName: 'zh-cn-x-ccc-local',
      voiceLocale: 'zh-CN',
    );

    final cleared = withVoice.copyWith(clearVoiceName: true);
    expect(cleared.voiceName, isNull);
    expect(cleared.voiceLocale, isNull);
  });

  test('online engine settings survive a JSON round trip', () {
    final settings = ReadAloudSettings.defaults().copyWith(
      engine: ReadAloudEngine.online,
      onlineUrl: 'https://tts.example.com/speak',
      onlineToken: 'secret',
      onlineVoice: 'zh-CN-XiaoxiaoNeural',
      onlineFormat: OnlineTtsFormat.json,
    );

    final decoded = ReadAloudSettings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())),
    );

    expect(decoded, settings);
    expect(decoded.hasOnlineEndpoint, isTrue);
  });

  test('unknown engine and format fall back to the defaults', () {
    final settings = ReadAloudSettings.fromJson({
      'engine': 'robot',
      'onlineFormat': 'xml',
    });

    expect(settings.engine, ReadAloudEngine.system);
    expect(settings.onlineFormat, OnlineTtsFormat.text);
  });

  test('empty online fields decode as null', () {
    final settings = ReadAloudSettings.fromJson({
      'onlineUrl': '   ',
      'onlineToken': '',
      'onlineVoice': null,
    });

    expect(settings.onlineUrl, isNull);
    expect(settings.onlineToken, isNull);
    expect(settings.onlineVoice, isNull);
    expect(settings.hasOnlineEndpoint, isFalse);
  });
}
