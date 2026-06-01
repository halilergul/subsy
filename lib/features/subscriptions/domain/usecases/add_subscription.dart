import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/domain/brand_resolver.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/premium_status.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/subscription_draft.dart';
import 'package:subsy/features/subscriptions/domain/subscription_repository.dart';
import 'package:subsy/features/subscriptions/domain/subscription_validator.dart';
import 'package:subsy/shared/constants/limits.dart';

/// The single funnel for creating a subscription. Enforces validation, brand
/// enrichment, and the free-tier limit so no caller can bypass them (FR-016).
class AddSubscription {
  AddSubscription(
    this._repo,
    this._premium,
    this._resolver, {
    SubscriptionValidator validator = const SubscriptionValidator(),
  }) : _validator = validator;

  final SubscriptionRepository _repo;
  final PremiumStatus _premium;
  final BrandResolver _resolver;
  final SubscriptionValidator _validator;

  Future<Result<Subscription>> call(SubscriptionDraft draft) async {
    final validation = _validator.validate(draft);
    if (validation case Failure<void>(:final error)) {
      return Failure(error);
    }

    // Free-tier limit (skipped for premium). Counts net current records.
    if (!_premium.isPremium) {
      final countResult = await _repo.count();
      switch (countResult) {
        case Failure<int>(:final error):
          return Failure(error);
        case Success<int>(:final value):
          if (value >= kFreeSubscriptionLimit) {
            return const Failure(LimitReachedError());
          }
      }
    }

    final brand = _resolver.resolve(draft.name);
    final now = DateTime.now().toUtc();
    final subscription = Subscription(
      name: draft.name.trim(),
      serviceKey: brand?.serviceKey,
      amount: draft.amount,
      currency: draft.currency,
      billingPeriod: draft.billingPeriod,
      nextRenewalDate: draft.nextRenewalDate,
      category: draft.category ?? brand?.defaultCategory ?? SubscriptionCategory.other,
      startDate: draft.startDate,
      notes: draft.notes,
      createdAt: now,
      updatedAt: now,
    );
    return _repo.add(subscription);
  }
}
