import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/dashboard/domain/calendar_month.dart';
import 'package:subsy/features/dashboard/domain/upcoming_payment.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Calendar grid layout + per-day grouping (pure domain).
void main() {
  final t = DateTime(2026, 1, 1);

  Subscription sub(String name, DateTime renewal) => Subscription(
        name: name,
        amount: 10,
        currency: Currency.tryl,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: renewal,
        category: SubscriptionCategory.other,
        createdAt: t,
        updatedAt: t,
      );

  UpcomingPayment pay(String name, DateTime renewal) =>
      UpcomingPayment.from(sub(name, renewal), DateTime(2026, 6, 1));

  test('June 2026 grid is Monday-first with the right leading blanks', () {
    // 1 June 2026 is a Monday → no leading blanks; 30 days.
    final month = buildCalendarMonth(const [], DateTime(2026, 6, 15));
    expect(month.cells.first, 1);
    expect(month.cells.whereType<int>().length, 30);
    expect(month.cells.last, 30);
  });

  test('July 2026 has 2 leading blanks (1 July is a Wednesday)', () {
    final month = buildCalendarMonth(const [], DateTime(2026, 7, 10));
    expect(month.cells.take(2).every((c) => c == null), isTrue);
    expect(month.cells[2], 1);
  });

  test('groups renewals by day, only for the reference month, sorted by name', () {
    final payments = [
      pay('Netflix', DateTime(2026, 6, 4)),
      pay('Disney', DateTime(2026, 6, 4)),
      pay('Spotify', DateTime(2026, 6, 3)),
      pay('NextMonth', DateTime(2026, 7, 9)), // excluded
    ];
    final month = buildCalendarMonth(payments, DateTime(2026, 6, 1));

    expect(month.dayHasPayments(3), isTrue);
    expect(month.paymentsOn(4).map((p) => p.subscription.name), ['Disney', 'Netflix']);
    expect(month.dayHasPayments(9), isFalse); // July renewal not in June grid
    expect(month.paymentsOn(15), isEmpty);
  });
}
