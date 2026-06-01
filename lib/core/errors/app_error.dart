/// Domain-level error model. Service/repository layers map low-level
/// exceptions into these so the UI can show user-friendly Turkish messages
/// without leaking technical details (see CONSTITUTION.md — Hata yönetimi).
sealed class AppError {
  const AppError({required this.message, this.cause});

  /// User-facing message (Turkish). Must never contain stack traces or
  /// raw exception text.
  final String message;

  /// Original error/exception, for logging only.
  final Object? cause;
}

/// Local storage (Isar) failures.
final class StorageError extends AppError {
  const StorageError({super.message = 'Veriler kaydedilirken bir sorun oluştu.', super.cause});
}

/// Network failures (only the optional exchange-rate fetch touches the network).
final class NetworkError extends AppError {
  const NetworkError({super.message = 'Bağlantı kurulamadı.', super.cause});
}

/// Requested record does not exist.
final class NotFoundError extends AppError {
  const NotFoundError({super.message = 'Kayıt bulunamadı.', super.cause});
}

/// Input validation failure. Carries a field-specific Turkish message.
final class ValidationError extends AppError {
  const ValidationError({required super.message, super.cause});
}

/// Free-tier limit reached (e.g. max 5 subscriptions without premium).
final class LimitReachedError extends AppError {
  const LimitReachedError({super.message = 'Ücretsiz sürüm sınırına ulaştınız.', super.cause});
}

/// Catch-all for unexpected failures.
final class UnknownError extends AppError {
  const UnknownError({super.message = 'Beklenmeyen bir hata oluştu.', super.cause});
}
