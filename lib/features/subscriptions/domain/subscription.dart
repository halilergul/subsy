import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Immutable domain entity for a tracked subscription.
///
/// Pure Dart — no Isar or Flutter-plugin imports — so the storage engine
/// stays swappable (see plan.md). [id] is null until persisted; the storage
/// layer assigns a stable id that does not change on update (FR-003).
class Subscription {
  const Subscription({
    this.id,
    required this.name,
    this.serviceKey,
    required this.amount,
    required this.currency,
    required this.billingPeriod,
    required this.nextRenewalDate,
    required this.category,
    this.startDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;

  /// Brand catalog key, or null if no brand was matched (FR-013).
  final String? serviceKey;
  final double amount;
  final Currency currency;
  final BillingPeriod billingPeriod;
  final DateTime nextRenewalDate;
  final SubscriptionCategory category;
  final DateTime? startDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription copyWith({
    int? id,
    String? name,
    String? serviceKey,
    bool clearServiceKey = false,
    double? amount,
    Currency? currency,
    BillingPeriod? billingPeriod,
    DateTime? nextRenewalDate,
    SubscriptionCategory? category,
    DateTime? startDate,
    bool clearStartDate = false,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      serviceKey: clearServiceKey ? null : (serviceKey ?? this.serviceKey),
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
      category: category ?? this.category,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Subscription &&
      other.id == id &&
      other.name == name &&
      other.serviceKey == serviceKey &&
      other.amount == amount &&
      other.currency == currency &&
      other.billingPeriod == billingPeriod &&
      other.nextRenewalDate == nextRenewalDate &&
      other.category == category &&
      other.startDate == startDate &&
      other.notes == notes &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        serviceKey,
        amount,
        currency,
        billingPeriod,
        nextRenewalDate,
        category,
        startDate,
        notes,
        createdAt,
        updatedAt,
      );
}
