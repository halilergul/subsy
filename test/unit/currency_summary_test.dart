import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/dashboard/domain/currency_summary.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// US2 — per-currency grouping, no cross-currency sum (maps SC-002/004).
void main() {
  final t = DateTime(2026, 1, 1);
  Subscription sub(double amount, Currency c, BillingPeriod p) => Subscription(
        name: 'X',
        amount: amount,
        currency: c,
        billingPeriod: p,
        nextRenewalDate: t,
        category: SubscriptionCategory.other,
        createdAt: t,
        updatedAt: t,
      );

  test('single currency, mixed periods sums to one monthly total', () {
    final r = currencySummary([
      sub(100, Currency.tryl, BillingPeriod.monthly),
      sub(1200, Currency.tryl, BillingPeriod.yearly), // → 100/mo
    ]);
    expect(r.length, 1);
    expect(r.single.currency, Currency.tryl);
    expect(r.single.monthlyTotal, closeTo(200, 0.0001));
  });

  test('multiple currencies kept separate, ordered TRY→USD→EUR', () {
    final r = currencySummary([
      sub(10, Currency.eur, BillingPeriod.monthly),
      sub(20, Currency.tryl, BillingPeriod.monthly),
      sub(5, Currency.usd, BillingPeriod.monthly),
    ]);
    expect(r.map((e) => e.currency).toList(),
        [Currency.tryl, Currency.usd, Currency.eur]);
    expect(r[0].monthlyTotal, 20);
    expect(r[1].monthlyTotal, 5);
    expect(r[2].monthlyTotal, 10);
  });

  test('currencies with no subscriptions are omitted', () {
    final r = currencySummary([sub(50, Currency.usd, BillingPeriod.monthly)]);
    expect(r.length, 1);
    expect(r.single.currency, Currency.usd);
  });

  test('empty input → empty summary', () {
    expect(currencySummary([]), isEmpty);
  });
}
