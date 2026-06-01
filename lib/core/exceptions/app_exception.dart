enum AppExceptionType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  server,
  parse,
  database,
  route,
  cancelled,
  unknown,
}

class AppException implements Exception {
  const AppException({
    required this.type,
    required this.message,
    this.code,
    this.cause,
    this.stackTrace,
  });

  const AppException.network(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
    String? code,
  }) : this(
          type: AppExceptionType.network,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
        );

  const AppException.timeout(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
    String? code,
  }) : this(
          type: AppExceptionType.timeout,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
        );

  const AppException.unknown(
    Object error, [
    StackTrace? stackTrace,
  ]) : this(
          type: AppExceptionType.unknown,
          message: '发生未知错误',
          cause: error,
          stackTrace: stackTrace,
        );

  final AppExceptionType type;
  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;

  bool get isRetryable => switch (type) {
        AppExceptionType.network ||
        AppExceptionType.timeout ||
        AppExceptionType.server =>
          true,
        _ => false,
      };

  @override
  String toString() => 'AppException($type, $code): $message';
}
