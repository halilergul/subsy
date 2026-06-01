import 'package:subsy/core/errors/app_error.dart';

/// Lightweight result type used by the domain/service layers instead of
/// throwing. Lets the UI handle success/failure explicitly.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      Failure<T>(:final error) => failure(error),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppError error;
}
