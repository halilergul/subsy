import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/dashboard/domain/currency_summary.dart';
import 'package:subsy/features/dashboard/domain/upcoming_payment.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';

/// All subscriptions as upcoming payments, sorted by effective renewal date
/// (soonest first), tie-broken by name. Mirrors the source AsyncValue state.
final upcomingPaymentsProvider = Provider<AsyncValue<List<UpcomingPayment>>>((ref) {
  return ref.watch(subscriptionsProvider).whenData((subs) {
    final now = DateTime.now();
    final items = subs.map((s) => UpcomingPayment.from(s, now)).toList()
      ..sort((a, b) {
        final byDate = a.effectiveRenewal.compareTo(b.effectiveRenewal);
        return byDate != 0
            ? byDate
            : a.subscription.name.toLowerCase().compareTo(b.subscription.name.toLowerCase());
      });
    return items;
  });
});

/// Per-currency monthly totals (no cross-currency sum), ordered TRY→USD→EUR.
final monthlySummaryProvider = Provider<AsyncValue<List<CurrencyTotal>>>((ref) {
  return ref.watch(subscriptionsProvider).whenData(currencySummary);
});
