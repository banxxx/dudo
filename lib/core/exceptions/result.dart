import 'app_exception.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? getOrNull() => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  AppException? exceptionOrNull() => switch (this) {
        Success<T>() => null,
        Failure<T>(:final exception) => exception,
      };
}

class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

class Failure<T> extends Result<T> {
  const Failure(this.exception);

  final AppException exception;
}
