import '../utils/logger.dart';
import 'exception_mapper.dart';

class ErrorHandler {
  ErrorHandler._();

  static void handle(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    final exception = ExceptionMapper.map(error, stackTrace);
    final message = [
      if (context != null) '[$context]',
      exception.message,
      'type=${exception.type.name}',
      if (exception.code != null) 'code=${exception.code}',
    ].join(' ');

    if (fatal) {
      log.e(message,
          error: exception.cause ?? exception, stackTrace: stackTrace);
    } else {
      log.w(message,
          error: exception.cause ?? exception, stackTrace: stackTrace);
    }
  }
}
