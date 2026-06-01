import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/dashboard/domain/renewal_calculator.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// US1 — effective renewal roll-forward (maps SC-003).
void main() {
  Subscription sub(DateTime renewal, BillingPeriod period) {
    final t = DateTime(2026, 1, 1);
    return Subscription(
      name: 'X',
      amount: 10,
      currency: Currency.tryl,
      billingPeriod: period,
      nextRenewalDate: renewal,
      category: SubscriptionCategory.other,
      createdAt: t,
      updatedAt: t,
    );
  }

  test('future date is returned unchanged', () {
    final now = DateTime(2026, 6, 1);
    final r = effectiveNextRenewal(sub(DateTime(2026, 6, 15), BillingPeriod.monthly), now);
    expect(r, DateTime(2026, 6, 15));
  });

  test('today is returned unchanged', () {
    final now = DateTime(2026, 6, 1);
    final r = effectiveNextRenewal(sub(DateTime(2026, 6, 1), BillingPeriod.monthly), now);
    expect(r, DateTime(2026, 6, 1));
  });

  test('past monthly rolls forward to next future occurrence', () {
    final now = DateTime(2026, 6, 10);
    // renews on the 5th; last was Jun 5 (past) → next Jul 5
    final r = effectiveNextRenewal(sub(DateTime(2026, 3, 5), BillingPeriod.monthly), now);
    expect(r, DateTime(2026, 7, 5));
  });

  test('past weekly rolls forward', () {
    final now = DateTime(2026, 6, 10);
    final r = effectiveNextRenewal(sub(DateTime(2026, 6, 1), BillingPeriod.weekly), now);
    // Jun 1 +7=Jun 8 (<10) +7=Jun 15
    expect(r, DateTime(2026, 6, 15));
  });

  test('past yearly rolls forward', () {
    final now = DateTime(2026, 6, 10);
    final r = effectiveNextRenewal(sub(DateTime(2024, 3, 1), BillingPeriod.yearly), now);
    expect(r, DateTime(2027, 3, 1));
  });

  test('month-end clamps (Jan 31 + 1 month → Feb 28)', () {
    final now = DateTime(2026, 2, 15);
    final r = effectiveNextRenewal(sub(DateTime(2026, 1, 31), BillingPeriod.monthly), now);
    expect(r, DateTime(2026, 2, 28));
  });
}
