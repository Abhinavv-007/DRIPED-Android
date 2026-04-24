/// Generic result wrapper for repository calls.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => switch (this) {
        Success<T> s => s.data,
        Failure<T> _ => null,
      };

  String? get error => switch (this) {
        Success<T> _ => null,
        Failure<T> f => f.message,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) =>
      switch (this) {
        Success<T> s => success(s.data),
        Failure<T> f => failure(f.message),
      };
}

class Success<T> extends Result<T> {
  @override
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}
