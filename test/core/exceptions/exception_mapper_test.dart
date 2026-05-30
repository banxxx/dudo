import 'package:dio/dio.dart';
import 'package:dudo/core/exceptions/app_exception.dart';
import 'package:dudo/core/exceptions/exception_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExceptionMapper', () {
    test('maps connection timeout to timeout exception', () {
      final exception = ExceptionMapper.fromDio(
        DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: RequestOptions(path: '/timeout'),
        ),
      );

      expect(exception.type, AppExceptionType.timeout);
      expect(exception.isRetryable, isTrue);
    });

    test('maps connection error to network exception', () {
      final exception = ExceptionMapper.fromDio(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/network'),
          reason: 'offline',
        ),
      );

      expect(exception.type, AppExceptionType.network);
      expect(exception.isRetryable, isTrue);
    });

    test('maps 401 to unauthorized exception', () {
      final exception = ExceptionMapper.fromDio(
        _badResponse(401),
      );

      expect(exception.type, AppExceptionType.unauthorized);
      expect(exception.code, '401');
    });

    test('maps 404 to not found exception', () {
      final exception = ExceptionMapper.fromDio(
        _badResponse(404),
      );

      expect(exception.type, AppExceptionType.notFound);
      expect(exception.code, '404');
    });

    test('maps unknown exception to unknown exception', () {
      final exception = ExceptionMapper.map(Exception('boom'));

      expect(exception.type, AppExceptionType.unknown);
    });

    test('returns existing AppException unchanged', () {
      const original = AppException.network('网络错误');

      expect(ExceptionMapper.map(original), same(original));
    });
  });
}

DioException _badResponse(int statusCode) {
  final requestOptions = RequestOptions(path: '/status/$statusCode');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: requestOptions,
    response: Response<void>(
      requestOptions: requestOptions,
      statusCode: statusCode,
    ),
  );
}
