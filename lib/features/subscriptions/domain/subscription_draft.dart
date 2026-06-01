import 'package:subsy/features/subscriptions/domain/enums.dart';

/// User-supplied input for creating or editing a subscription. Required fields
/// are non-nullable (presence guaranteed by the type system); value rules are
/// checked by [SubscriptionValidator]. [category] is optional — when null the
/// add use case defaults it from the brand catalog, else to `other`.
class SubscriptionDraft {
  const SubscriptionDraft({
    required this.name,
    required this.amount,
    required this.currency,
    required this.billingPeriod,
    required this.nextRenewalDate,
    this.category,
    this.startDate,
    this.notes,
  });

  final String name;
  final double amount;
  final Currency currency;
  final BillingPeriod billingPeriod;
  final DateTime nextRenewalDate;
  final SubscriptionCategory? category;
  final DateTime? startDate;
  final String? notes;
}
