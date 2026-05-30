import 'package:dio/dio.dart';

import 'app_exception.dart';

class ExceptionMapper {
  ExceptionMapper._();

  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;
    if (error is DioException) return fromDio(error, stackTrace);
    if (error is FormatException) {
      return AppException(
        type: AppExceptionType.parse,
        message: '数据解析失败',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return AppException.unknown(error, stackTrace);
  }

  static AppException fromDio(DioException error, [StackTrace? stackTrace]) {
    final statusCode = error.response?.statusCode;
    final effectiveStackTrace = stackTrace ?? error.stackTrace;

    if (statusCode != null) {
      return _fromStatusCode(error, statusCode, effectiveStackTrace);
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout => AppException.timeout(
          '连接超时，请稍后重试',
          cause: error,
          stackTrace: effectiveStackTrace,
        ),
      DioExceptionType.sendTimeout => AppException.timeout(
          '请求超时，请稍后重试',
          cause: error,
          stackTrace: effectiveStackTrace,
        ),
      DioExceptionType.receiveTimeout => AppException.timeout(
          '响应超时，请稍后重试',
          cause: error,
          stackTrace: effectiveStackTrace,
        ),
      DioExceptionType.connectionError => AppException.network(
          '网络连接失败，请检查网络',
          cause: error,
          stackTrace: effectiveStackTrace,
        ),
      DioExceptionType.badCertificate => AppException.network(
          '网络证书验证失败',
          cause: error,
          stackTrace: effectiveStackTrace,
        ),
      DioExceptionType.cancel => AppException(
          type: AppExceptionType.cancelled,
          message: '请求已取消',
          cause: error,
          stackTrace: effectiveStackTrace,
        ),
      DioExceptionType.badResponse || DioExceptionType.unknown => AppException(
          type: AppExceptionType.unknown,
          message: '发生未知网络错误',
          cause: error,
          stackTrace: effectiveStackTrace,
        ),
    };
  }

  static AppException _fromStatusCode(
    DioException error,
    int statusCode,
    StackTrace stackTrace,
  ) {
    final (type, message) = switch (statusCode) {
      401 => (AppExceptionType.unauthorized, '登录状态已失效'),
      403 => (AppExceptionType.forbidden, '没有访问权限'),
      404 => (AppExceptionType.notFound, '请求的资源不存在'),
      >= 500 => (AppExceptionType.server, '服务器暂时不可用'),
      _ => (AppExceptionType.network, '请求失败'),
    };

    return AppException(
      type: type,
      message: message,
      code: statusCode.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
