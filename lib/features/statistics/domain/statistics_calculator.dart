import 'package:subsy/features/dashboard/domain/monthly_normalizer.dart';
import 'package:subsy/features/statistics/domain/category_breakdown.dart';
import 'package:subsy/features/statistics/domain/ranked_subscription.dart';
import 'package:subsy/features/statistics/domain/stat_period.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Stable display order for currency sections (mirrors the dashboard summary).
const List<Currency> _currencyOrder = [Currency.tryl, Currency.usd, Currency.eur];

/// View-only aggregate produced by [buildStatistics]. All figures derive from
/// the current subscription set; nothing is persisted.
class StatisticsView {
  const StatisticsView({
    required this.period,
    required this.breakdowns,
    required this.topByCurrency,
    required this.isEmpty,
  });

  final StatPeriod period;

  /// One breakdown per currency present, ordered TRY→USD→EUR.
  final List<CategoryBreakdown> breakdowns;

  /// Most-expensive subscriptions per currency, ranked descending.
  final Map<Currency, List<RankedSubscription>> topByCurrency;

  /// True when there are no subscriptions at all (drives the empty state).
  final bool isEmpty;
}

/// A subscription's amount normalized to the selected period:
/// monthly-normalized amount × the period factor (monthly→×1, yearly→×12).
double periodAmount(Subscription s, StatPeriod p) => monthlyAmount(s) * p.factor;

/// Per-currency category breakdowns. Within a currency, sums [periodAmount] per
/// category (dropping empty ones), computes each slice's percentage of the
/// currency total, and sorts slices by amount descending. Currencies are never
/// blended and are ordered TRY→USD→EUR. Percentages are display-rounded so each
/// breakdown's slices sum to exactly 100 (the largest slice absorbs the
/// remainder).
List<CategoryBreakdown> categoryBreakdowns(List<Subscription> subs, StatPeriod p) {
  // currency → (category → summed period amount)
  final byCurrency = <Currency, Map<SubscriptionCategory, double>>{};
  for (final s in subs) {
    final cats = byCurrency.putIfAbsent(s.currency, () => {});
    cats[s.category] = (cats[s.category] ?? 0) + periodAmount(s, p);
  }

  final result = <CategoryBreakdown>[];
  for (final currency in _currencyOrder) {
    final cats = byCurrency[currency];
    if (cats == null || cats.isEmpty) continue;

    final total = cats.values.fold<double>(0, (a, b) => a + b);
    final entries = cats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // amount desc

    final percentages = _roundedPercentages([for (final e in entries) e.value], total);
    final slices = [
      for (var i = 0; i < entries.length; i++)
        CategorySlice(
          category: entries[i].key,
          amount: entries[i].value,
          percentage: percentages[i],
        ),
    ];
    result.add(CategoryBreakdown(currency: currency, total: total, slices: slices));
  }
  return result;
}

/// Whole-number percentages that sum to exactly 100. Inputs are pre-sorted
/// descending, so index 0 (the largest) absorbs the rounding remainder
/// (research.md D2). Returns zeros when [total] is not positive.
List<double> _roundedPercentages(List<double> amounts, double total) {
  if (total <= 0) return List<double>.filled(amounts.length, 0);
  final rounded = [for (final a in amounts) (a / total * 100).roundToDouble()];
  // Largest slice (index 0) takes whatever keeps the visible total at 100.
  final othersSum = rounded.skip(1).fold<double>(0, (a, b) => a + b);
  if (rounded.isNotEmpty) rounded[0] = 100 - othersSum;
  return rounded;
}

/// Most-expensive subscriptions per currency, ranked by [periodAmount]
/// descending (tie-broken by name). Never compares across currencies. An
/// optional [limit] keeps only the top N per currency.
Map<Currency, List<RankedSubscription>> topSubscriptions(
  List<Subscription> subs,
  StatPeriod p, {
  int? limit,
}) {
  final byCurrency = <Currency, List<RankedSubscription>>{};
  for (final s in subs) {
    byCurrency
        .putIfAbsent(s.currency, () => [])
        .add(RankedSubscription(subscription: s, amount: periodAmount(s, p)));
  }

  final result = <Currency, List<RankedSubscription>>{};
  for (final currency in _currencyOrder) {
    final items = byCurrency[currency];
    if (items == null || items.isEmpty) continue;
    items.sort((a, b) {
      final byAmount = b.amount.compareTo(a.amount);
      return byAmount != 0
          ? byAmount
          : a.subscription.name.toLowerCase().compareTo(b.subscription.name.toLowerCase());
    });
    result[currency] = limit == null ? items : items.take(limit).toList();
  }
  return result;
}

/// Builds the full statistics view for the given subscriptions + period.
/// Empty input → [StatisticsView.isEmpty] is true with empty breakdowns.
StatisticsView buildStatistics(List<Subscription> subs, StatPeriod p) {
  return StatisticsView(
    period: p,
    breakdowns: categoryBreakdowns(subs, p),
    topByCurrency: topSubscriptions(subs, p, limit: 5),
    isEmpty: subs.isEmpty,
  );
}
