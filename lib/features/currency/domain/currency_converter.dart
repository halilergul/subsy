import 'package:subsy/features/currency/domain/exchange_rates.dart';
import 'package:subsy/features/currency/domain/unified_total.dart';
import 'package:subsy/features/dashboard/domain/monthly_normalizer.dart';
import 'package:subsy/features/statistics/domain/category_breakdown.dart';
import 'package:subsy/features/statistics/domain/stat_period.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Converts [amount] from currency [from] to [to] via the base-relative rates.
/// Returns the amount unchanged when [from] == [to] (factor 1.0, no drift).
/// Returns null when either currency is absent from the rate map.
double? convertAmount(double amount, Currency from, Currency to, ExchangeRates rates) {
  if (from == to) return amount;
  final rFrom = rates.ratesPerBase[from];
  final rTo = rates.ratesPerBase[to];
  if (rFrom == null || rTo == null) return null;
  return amount * rTo / rFrom;
}

/// Sum of each subscription's monthly-normalized amount converted to [target].
/// Sums BEFORE rounding (no per-item drift). Subscriptions whose currency has
/// no rate are excluded and reported via [UnifiedTotal.missing]. Returns null
/// only when nothing could be converted (no usable rates / empty input).
UnifiedTotal? unifiedMonthlyTotal(
  List<Subscription> subs,
  Currency target,
  ExchangeRates rates,
) {
  var total = 0.0;
  var convertedAny = false;
  final missing = <Currency>{};

  for (final s in subs) {
    final converted = convertAmount(monthlyAmount(s), s.currency, target, rates);
    if (converted == null) {
      missing.add(s.currency);
      continue;
    }
    total += converted;
    convertedAny = true;
  }

  if (!convertedAny) return null;
  return UnifiedTotal(amount: total, target: target, missing: missing.toList());
}

/// Per-category converted, period-scaled breakdown for the unified statistics
/// view. Categories are summed across currencies after conversion to [target],
/// multiplied by the period factor, sorted by amount desc, and given
/// whole-number percentages summing to 100 (largest slice absorbs remainder).
/// Returns null when nothing could be converted.
UnifiedCategoryBreakdown? unifiedCategoryBreakdown(
  List<Subscription> subs,
  Currency target,
  StatPeriod period,
  ExchangeRates rates,
) {
  final byCategory = <SubscriptionCategory, double>{};
  final missing = <Currency>{};
  var convertedAny = false;

  for (final s in subs) {
    final converted = convertAmount(monthlyAmount(s), s.currency, target, rates);
    if (converted == null) {
      missing.add(s.currency);
      continue;
    }
    final scaled = converted * period.factor;
    byCategory[s.category] = (byCategory[s.category] ?? 0) + scaled;
    convertedAny = true;
  }

  if (!convertedAny) return null;

  final total = byCategory.values.fold<double>(0, (a, b) => a + b);
  final entries = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final percentages = _roundedPercentages([for (final e in entries) e.value], total);
  final slices = [
    for (var i = 0; i < entries.length; i++)
      CategorySlice(
        category: entries[i].key,
        amount: entries[i].value,
        percentage: percentages[i],
      ),
  ];

  return UnifiedCategoryBreakdown(
    target: target,
    total: total,
    slices: slices,
    missing: missing.toList(),
  );
}

/// Whole-number percentages summing to exactly 100; inputs pre-sorted desc so
/// index 0 (largest) absorbs the rounding remainder (mirrors statistics_calculator).
List<double> _roundedPercentages(List<double> amounts, double total) {
  if (total <= 0) return List<double>.filled(amounts.length, 0);
  final rounded = [for (final a in amounts) (a / total * 100).roundToDouble()];
  final othersSum = rounded.skip(1).fold<double>(0, (a, b) => a + b);
  if (rounded.isNotEmpty) rounded[0] = 100 - othersSum;
  return rounded;
}
