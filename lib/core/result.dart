import 'errors/app_error.dart';

/// 函数式 Result 类型，替代 try/catch 在 UseCase 边界的使用
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get value => (this as Success<T>).data;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) {
    return switch (this) {
      Success<T>(data: final d) => success(d),
      Failure<T>(error: final e) => failure(e),
    };
  }

  Result<R> map<R>(R Function(T) transform) {
    return switch (this) {
      Success<T>(data: final d) => Success(transform(d)),
      Failure<T>(error: final e) => Failure(e),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppError error;
}
