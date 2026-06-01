import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/domain/brand_resolver.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/subscription_draft.dart';
import 'package:subsy/features/subscriptions/domain/subscription_repository.dart';
import 'package:subsy/features/subscriptions/domain/subscription_validator.dart';

/// Edits an existing subscription. Validates, re-resolves the brand from the
/// (possibly changed) name, preserves id + createdAt, and bumps updatedAt.
/// No free-tier limit check (editing is always allowed — FR-018).
class UpdateSubscription {
  UpdateSubscription(
    this._repo,
    this._resolver, {
    SubscriptionValidator validator = const SubscriptionValidator(),
  }) : _validator = validator;

  final SubscriptionRepository _repo;
  final BrandResolver _resolver;
  final SubscriptionValidator _validator;

  Future<Result<Subscription>> call(int id, SubscriptionDraft draft) async {
    final validation = _validator.validate(draft);
    if (validation case Failure<void>(:final error)) {
      return Failure(error);
    }

    final existingResult = await _repo.getById(id);
    final Subscription existing;
    switch (existingResult) {
      case Failure<Subscription?>(:final error):
        return Failure(error);
      case Success<Subscription?>(:final value):
        if (value == null) return const Failure(NotFoundError());
        existing = value;
    }

    final brand = _resolver.resolve(draft.name);
    final updated = existing.copyWith(
      name: draft.name.trim(),
      serviceKey: brand?.serviceKey,
      clearServiceKey: brand == null,
      amount: draft.amount,
      currency: draft.currency,
      billingPeriod: draft.billingPeriod,
      nextRenewalDate: draft.nextRenewalDate,
      category: draft.category ?? brand?.defaultCategory ?? SubscriptionCategory.other,
      startDate: draft.startDate,
      clearStartDate: draft.startDate == null,
      notes: draft.notes,
      clearNotes: draft.notes == null,
      updatedAt: DateTime.now().toUtc(),
    );
    return _repo.update(updated);
  }
}
