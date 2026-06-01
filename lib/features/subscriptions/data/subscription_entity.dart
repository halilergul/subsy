import 'package:isar_community/isar.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

part 'subscription_entity.g.dart';

/// Isar persistence model. Mirrors [Subscription] but carries Isar
/// annotations. Enums are stored by name (`EnumType.name`) so reordering them
/// never corrupts data (see research.md D3). Kept separate from the domain
/// entity to keep storage swappable.
@collection
class SubscriptionEntity {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  String? serviceKey;

  late double amount;

  @Enumerated(EnumType.name)
  late Currency currency;

  @Enumerated(EnumType.name)
  late BillingPeriod billingPeriod;

  late DateTime nextRenewalDate;

  @Enumerated(EnumType.name)
  late SubscriptionCategory category;

  DateTime? startDate;

  String? notes;

  late DateTime createdAt;

  late DateTime updatedAt;

  /// Builds an Isar entity from a domain object. A null domain id maps to
  /// [Isar.autoIncrement] so Isar assigns a fresh id on insert.
  static SubscriptionEntity fromDomain(Subscription s) {
    return SubscriptionEntity()
      ..id = s.id ?? Isar.autoIncrement
      ..name = s.name
      ..serviceKey = s.serviceKey
      ..amount = s.amount
      ..currency = s.currency
      ..billingPeriod = s.billingPeriod
      ..nextRenewalDate = s.nextRenewalDate.toUtc()
      ..category = s.category
      ..startDate = s.startDate?.toUtc()
      ..notes = s.notes
      ..createdAt = s.createdAt.toUtc()
      ..updatedAt = s.updatedAt.toUtc();
  }

  Subscription toDomain() {
    return Subscription(
      id: id,
      name: name,
      serviceKey: serviceKey,
      amount: amount,
      currency: currency,
      billingPeriod: billingPeriod,
      nextRenewalDate: nextRenewalDate.toUtc(),
      category: category,
      startDate: startDate?.toUtc(),
      notes: notes,
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
    );
  }
}
