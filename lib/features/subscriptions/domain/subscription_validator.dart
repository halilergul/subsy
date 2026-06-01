import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/domain/subscription_draft.dart';
import 'package:subsy/shared/constants/limits.dart';

/// Validates a [SubscriptionDraft] before it is persisted. Returns a typed
/// [ValidationError] (Turkish message) on the first failing rule; never throws
/// (FR-006..009). Rules mirror data-model.md.
class SubscriptionValidator {
  const SubscriptionValidator();

  Result<void> validate(SubscriptionDraft draft) {
    final name = draft.name.trim();
    if (name.isEmpty) {
      return const Failure(ValidationError(message: 'Servis adı boş olamaz.'));
    }
    if (name.length > kMaxNameLength) {
      return const Failure(ValidationError(message: 'Servis adı çok uzun.'));
    }
    if (!draft.amount.isFinite || draft.amount <= 0) {
      return const Failure(ValidationError(message: 'Tutar sıfırdan büyük olmalı.'));
    }
    if (!kSupportedCurrencies.contains(draft.currency)) {
      return const Failure(ValidationError(message: 'Desteklenmeyen para birimi.'));
    }
    final notes = draft.notes;
    if (notes != null && notes.length > kMaxNotesLength) {
      return const Failure(ValidationError(message: 'Not çok uzun.'));
    }
    return const Success(null);
  }
}
