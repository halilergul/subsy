import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/dashboard/domain/monthly_normalizer.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// US2 — monthly normalization (maps SC-002).
void main() {
  Subscription sub(double amount, BillingPeriod period) {
    final t = DateTime(2026, 1, 1);
    return Subscription(
      name: 'X',
      amount: amount,
      currency: Currency.tryl,
      billingPeriod: period,
      nextRenewalDate: t,
      category: SubscriptionCategory.other,
      createdAt: t,
      updatedAt: t,
    );
  }

  test('monthly is unchanged', () {
    expect(monthlyAmount(sub(100, BillingPeriod.monthly)), 100);
  });

  test('yearly divided by 12', () {
    expect(monthlyAmount(sub(1200, BillingPeriod.yearly)), 100);
  });

  test('weekly × 52 / 12', () {
    expect(monthlyAmount(sub(12, BillingPeriod.weekly)), closeTo(52, 0.0001));
  });
}
