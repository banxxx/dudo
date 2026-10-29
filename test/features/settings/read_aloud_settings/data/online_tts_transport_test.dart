import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dudo/features/settings/read_aloud_settings/data/online_tts_transport.dart';
import 'package:dudo/features/settings/read_aloud_settings/domain/read_aloud_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final endpoint = ReadAloudSettings.defaults().copyWith(
    engine: ReadAloudEngine.online,
    onlineUrl: 'https://tts.example.com/speak',
  );

  test('text format posts the raw text with a plain text content type', () {
    final request = buildOnlineTtsRequest(endpoint, '你好，世界');

    expect(request.url, 'https://tts.example.com/speak');
    expect(request.body, '你好，世界');
    expect(request.contentType, 'text/plain; charset=utf-8');
    expect(request.headers, isEmpty);
  });

  test('json format sends text, voice and rate', () {
    final settings = endpoint.copyWith(
      onlineFormat: OnlineTtsFormat.json,
      onlineVoice: 'zh-CN-XiaoxiaoNeural',
      speechRate: 1.3,
    );

    final request = buildOnlineTtsRequest(settings, '你好');
    final body = jsonDecode(request.body) as Map<String, dynamic>;

    expect(request.contentType, 'application/json; charset=utf-8');
    expect(body['text'], '你好');
    expect(body['voice'], 'zh-CN-XiaoxiaoNeural');
    expect(body['rate'], 1.3);
  });

  test('a token becomes a bearer authorization header', () {
    final settings = endpoint.copyWith(onlineToken: 'abc123');

    final request = buildOnlineTtsRequest(settings, '你好');

    expect(request.headers['Authorization'], 'Bearer abc123');
  });

  test('a blank token sends no authorization header', () {
    final settings = endpoint.copyWith(onlineToken: '  ');

    final request = buildOnlineTtsRequest(settings, '你好');

    expect(request.headers, isEmpty);
  });

  test('a dropped connection is retried once and recovers', () async {
    final adapter = _FlakyAdapter(failures: 1);
    final transport =
        DioOnlineTtsTransport(dio: Dio()..httpClientAdapter = adapter);

    final bytes = await transport.synthesize(endpoint, '你好');

    expect(bytes, _FlakyAdapter.audio);
    expect(adapter.calls, 2);
  });

  test('a persistent failure surfaces after the retry', () async {
    final adapter = _FlakyAdapter(failures: 3);
    final transport =
        DioOnlineTtsTransport(dio: Dio()..httpClientAdapter = adapter);

    await expectLater(
      transport.synthesize(endpoint, '你好'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, 2);
  });
}

class _FlakyAdapter implements HttpClientAdapter {
  _FlakyAdapter({required this.failures});

  static const audio = [82, 73, 70, 70];

  final int failures;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (calls <= failures) {
      throw const HttpException('Connection closed while receiving data');
    }
    return ResponseBody.fromBytes(audio, 200);
  }

  @override
  void close({bool force = false}) {}
}
