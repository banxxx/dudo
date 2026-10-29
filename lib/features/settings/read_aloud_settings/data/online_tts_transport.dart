import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/http_client.dart';
import '../domain/read_aloud_settings.dart';

/// A fully resolved HTTP request for an online TTS endpoint.
class OnlineTtsRequest {
  const OnlineTtsRequest({
    required this.url,
    required this.body,
    required this.contentType,
    this.headers = const {},
  });

  final String url;
  final String body;
  final String contentType;
  final Map<String, String> headers;
}

/// Builds the request sent to a user supplied TTS endpoint.
///
/// The contract is intentionally small so a user can point dudo at Azure, an
/// Edge `大声朗读` forwarder (e.g. ms-ra-forwarder) or any self hosted service:
///
/// * `text`  — `POST` with `Content-Type: text/plain; charset=utf-8`
/// * `json`  — `POST` with `Content-Type: application/json` and the body
///   `{"text": "...", "voice": "...", "rate": 1.2}`
///
/// The endpoint must answer with audio bytes (mp3/wav), not JSON.
OnlineTtsRequest buildOnlineTtsRequest(
  ReadAloudSettings settings,
  String text,
) {
  final url = settings.onlineUrl?.trim() ?? '';
  final token = settings.onlineToken?.trim();
  final headers = <String, String>{
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  if (settings.onlineFormat == OnlineTtsFormat.json) {
    return OnlineTtsRequest(
      url: url,
      body: jsonEncode({
        'text': text,
        if (settings.onlineVoice != null) 'voice': settings.onlineVoice,
        'rate': settings.speechRate,
      }),
      contentType: 'application/json; charset=utf-8',
      headers: headers,
    );
  }

  return OnlineTtsRequest(
    url: url,
    body: text,
    contentType: 'text/plain; charset=utf-8',
    headers: headers,
  );
}

abstract interface class OnlineTtsTransport {
  /// Returns the audio bytes for [text] or throws when the endpoint fails.
  Future<List<int>> synthesize(ReadAloudSettings settings, String text);
}

class DioOnlineTtsTransport implements OnlineTtsTransport {
  const DioOnlineTtsTransport({Dio? dio}) : _dio = dio;

  final Dio? _dio;

  Dio get _client => _dio ?? HttpClient.instance.dio;

  /// One paragraph should not stall the queue for the client wide 30s.
  static const _timeout = Duration(seconds: 12);

  @override
  Future<List<int>> synthesize(ReadAloudSettings settings, String text) async {
    if (!settings.hasOnlineEndpoint) {
      throw StateError('未配置在线朗读接口地址');
    }
    final request = buildOnlineTtsRequest(settings, text);
    try {
      return await _post(request).timeout(_timeout);
    } on DioException catch (error) {
      // A pooled keep-alive socket is sometimes closed by the server between
      // two paragraphs; retrying once recovers those without dropping text.
      if (!_isTransient(error)) rethrow;
      return _post(request).timeout(_timeout);
    }
  }

  Future<List<int>> _post(OnlineTtsRequest request) async {
    final response = await _client.post<List<int>>(
      request.url,
      data: request.body,
      options: Options(
        responseType: ResponseType.bytes,
        contentType: request.contentType,
        headers: request.headers,
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('在线朗读接口返回了空音频');
    }
    return data;
  }

  /// Timeouts are not retried: a second 12s wait is worse than reporting the
  /// failure and letting the reader skip to the next paragraph.
  bool _isTransient(DioException error) => switch (error.type) {
        DioExceptionType.connectionError || DioExceptionType.unknown => true,
        _ => false,
      };
}
