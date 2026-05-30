import 'dart:io' show Directory;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Lightweight Dio wrapper with cookie persistence, retry, charset & logging
/// support — used by the source-engine and direct downloads alike.
class HttpClient {
  HttpClient._(this.dio, this.cookieJar);

  final Dio dio;
  final PersistCookieJar cookieJar;

  static HttpClient? _instance;
  static HttpClient get instance {
    final HttpClient? inst = _instance;
    if (inst == null) {
      throw StateError('HttpClient.init() must be called first.');
    }
    return inst;
  }

  static Future<HttpClient> init() async {
    if (_instance != null) return _instance!;

    final docDir = await getApplicationDocumentsDirectory();
    final cookieDir = Directory(p.join(docDir.path, 'cookies'));
    if (!cookieDir.existsSync()) cookieDir.createSync(recursive: true);

    final jar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(cookieDir.path),
    );

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
        followRedirects: true,
        validateStatus: (int? s) => s != null && s < 500,
        headers: <String, dynamic>{
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 dudo/0.1',
        },
        responseType: ResponseType.bytes, // we decode charset manually
      ),
    );

    dio.interceptors
      ..add(CookieManager(jar))
      ..add(RetryInterceptor())
      ..add(AppLogInterceptor());

    final HttpClient client = HttpClient._(dio, jar);
    _instance = client;
    return client;
  }
}

/// Naive exponential-backoff retry interceptor.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({this.maxAttempts = 3});
  final int maxAttempts;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final int attempt =
        (err.requestOptions.extra['retry_attempt'] as int?) ?? 0;
    final bool shouldRetry = _isRetryable(err) && attempt < maxAttempts - 1;
    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    final int nextAttempt = attempt + 1;
    await Future<void>.delayed(Duration(milliseconds: 300 * (1 << attempt)));
    try {
      final RequestOptions clone = err.requestOptions.copyWith(
        extra: <String, dynamic>{
          ...err.requestOptions.extra,
          'retry_attempt': nextAttempt,
        },
      );
      final Response<dynamic> response =
          await HttpClient.instance.dio.fetch<dynamic>(clone);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _isRetryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      default:
        return false;
    }
  }
}

/// Project log interceptor — renamed to avoid clashing with `dio.LogInterceptor`.
class AppLogInterceptor extends Interceptor {
  AppLogInterceptor();
  final Logger _log = Logger(printer: PrettyPrinter(methodCount: 0));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.d('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log.d('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.w('✗ ${err.requestOptions.uri} : ${err.message}');
    handler.next(err);
  }
}
