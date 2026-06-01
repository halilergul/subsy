import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Returns the next renewal date that is today or in the future. If the stored
/// [Subscription.nextRenewalDate] has already passed, it is rolled forward by
/// the billing period (calendar-aware, end-of-month clamped). Display-only —
/// the stored value is never mutated. Compared at day granularity.
DateTime effectiveNextRenewal(Subscription s, DateTime now) {
  final today = _dateOnly(now);
  var next = _dateOnly(s.nextRenewalDate);
  if (!next.isBefore(today)) return next;

  switch (s.billingPeriod) {
    case BillingPeriod.weekly:
      while (next.isBefore(today)) {
        next = next.add(const Duration(days: 7));
      }
    case BillingPeriod.monthly:
      while (next.isBefore(today)) {
        next = _addMonthsClamped(next, 1);
      }
    case BillingPeriod.yearly:
      while (next.isBefore(today)) {
        next = _addMonthsClamped(next, 12);
      }
  }
  return next;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Adds [months] to [date], clamping the day to the target month's length
/// (e.g. Jan 31 + 1 month → Feb 28/29, not Mar 3).
DateTime _addMonthsClamped(DateTime date, int months) {
  final total = date.month - 1 + months;
  final year = date.year + total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day; // day 0 = last day of `month`
  final day = date.day <= lastDay ? date.day : lastDay;
  return DateTime(year, month, day);
}
