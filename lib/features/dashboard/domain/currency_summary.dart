import 'package:subsy/features/dashboard/domain/monthly_normalizer.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// A per-currency monthly total (view-only).
class CurrencyTotal {
  const CurrencyTotal({required this.currency, required this.monthlyTotal});

  final Currency currency;
  final double monthlyTotal;
}

/// Groups subscriptions by currency and sums their monthly-normalized amounts.
/// Amounts are NEVER summed across currencies. Ordered TRY→USD→EUR; currencies
/// with no subscriptions are omitted.
List<CurrencyTotal> currencySummary(List<Subscription> subs) {
  final totals = <Currency, double>{};
  for (final s in subs) {
    totals[s.currency] = (totals[s.currency] ?? 0) + monthlyAmount(s);
  }
  // Stable, predictable display order.
  const order = [Currency.tryl, Currency.usd, Currency.eur];
  return [
    for (final c in order)
      if (totals.containsKey(c)) CurrencyTotal(currency: c, monthlyTotal: totals[c]!),
  ];
}
