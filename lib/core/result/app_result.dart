sealed class AppResult<T> {
  const AppResult();

  bool get isSuccess => this is AppSuccess<T>;
  bool get isFailure => this is AppFailure<T>;

  T? get valueOrNull => switch (this) {
    AppSuccess<T>(:final value) => value,
    AppFailure<T>() => null,
  };

  AppError? get errorOrNull => switch (this) {
    AppSuccess<T>() => null,
    AppFailure<T>(:final error) => error,
  };

  R fold<R>(
    R Function(T value) onSuccess,
    R Function(AppError error) onFailure,
  ) {
    return switch (this) {
      AppSuccess<T>(:final value) => onSuccess(value),
      AppFailure<T>(:final error) => onFailure(error),
    };
  }
}

class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);

  final T value;
}

class AppFailure<T> extends AppResult<T> {
  const AppFailure(this.error);

  final AppError error;
}

class AppError {
  const AppError({required this.code, required this.message, this.cause});

  final String code;
  final String message;
  final Object? cause;
}
