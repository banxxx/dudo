import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/exceptions/app_exception.dart';
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
    final urlError = onlineUrlError(settings.onlineUrl);
    if (urlError != null) {
      throw AppException(type: AppExceptionType.invalid, message: urlError);
    }
    final request = buildOnlineTtsRequest(settings, text);
    try {
      return await _post(request).timeout(_timeout);
    } on TimeoutException catch (error) {
      throw AppException.timeout('请求超时，服务器没有响应', cause: error);
    } on DioException catch (error) {
      // A pooled keep-alive socket is sometimes closed by the server between
      // two paragraphs; retrying once recovers those without dropping text.
      if (!_isTransient(error)) throw _describe(error);
      try {
        return await _post(request).timeout(_timeout);
      } on TimeoutException catch (retryError) {
        throw AppException.timeout('请求超时，服务器没有响应', cause: retryError);
      } on DioException catch (retryError) {
        throw _describe(retryError);
      }
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
      throw const AppException(
        type: AppExceptionType.invalid,
        message: '接口没有返回音频，请确认接口直接返回 mp3/wav',
      );
    }
    return data;
  }

  /// Turns a transport failure into the sentence the settings page shows.
  AppException _describe(DioException error) {
    final status = error.response?.statusCode;
    if (status != null) {
      return switch (status) {
        401 || 403 => AppException(
            type: AppExceptionType.unauthorized,
            message: '访问令牌无效或没有权限（HTTP $status）',
            code: '$status',
            cause: error,
          ),
        404 => AppException(
            type: AppExceptionType.notFound,
            message: '接口地址不存在（HTTP 404）',
            code: '404',
            cause: error,
          ),
        429 => AppException(
            type: AppExceptionType.network,
            message: '请求过于频繁，请稍后再试（HTTP 429）',
            code: '429',
            cause: error,
          ),
        >= 500 => AppException(
            type: AppExceptionType.server,
            message: '服务端出错（HTTP $status）',
            code: '$status',
            cause: error,
          ),
        _ => AppException(
            type: AppExceptionType.network,
            message: '接口返回错误（HTTP $status）',
            code: '$status',
            cause: error,
          ),
      };
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        AppException.timeout('连接超时，请检查网络或服务器状态', cause: error),
      DioExceptionType.connectionError => AppException.network(
          '无法连接服务器，请检查地址与网络',
          cause: error,
        ),
      DioExceptionType.badCertificate => AppException.network(
          '证书校验失败，请检查接口地址',
          cause: error,
        ),
      _ => AppException.network(
          '请求失败：${error.message ?? error.type.name}',
          cause: error,
        ),
    };
  }

  /// Timeouts are not retried: a second 12s wait is worse than reporting the
  /// failure and letting the reader skip to the next paragraph.
  bool _isTransient(DioException error) => switch (error.type) {
        DioExceptionType.connectionError || DioExceptionType.unknown => true,
        _ => false,
      };
}
