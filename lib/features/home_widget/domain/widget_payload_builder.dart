import 'package:subsy/features/currency/domain/currency_converter.dart';
import 'package:subsy/features/currency/domain/exchange_rates.dart';
import 'package:subsy/features/dashboard/domain/currency_summary.dart';
import 'package:subsy/features/dashboard/domain/relative_date_label.dart';
import 'package:subsy/features/dashboard/domain/renewal_calculator.dart';
import 'package:subsy/features/home_widget/domain/widget_payload.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/shared/utils/money_format.dart';

/// Builds the home-widget payload from the current app state. Pure and
/// deterministic ([now] injected); no Flutter/plugin/Isar imports. Produces
/// display-ready Turkish strings so the native widget only renders text.
///
/// Gating order (FR-008/004): not premium → locked; no subscriptions → empty;
/// otherwise ready with the soonest payment + per-currency total (+ unified ≈
/// total when premium rates are available).
WidgetPayload buildWidgetPayload({
  required List<Subscription> subs,
  required DateTime now,
  required bool isPremium,
  required Currency target,
  ExchangeRates? rates,
}) {
  if (!isPremium) return const WidgetPayload.locked();
  if (subs.isEmpty) return const WidgetPayload.empty();

  // Next payment = soonest effective renewal (tie-break by name).
  final next = subs.reduce((a, b) {
    final ra = effectiveNextRenewal(a, now);
    final rb = effectiveNextRenewal(b, now);
    final byDate = ra.compareTo(rb);
    if (byDate != 0) return byDate < 0 ? a : b;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase()) <= 0 ? a : b;
  });
  final nextRenewal = effectiveNextRenewal(next, now);

  // Per-currency monthly total (reuses the dashboard summary), e.g.
  // "₺549.99 · $12.99 / ay".
  final totals = currencySummary(subs);
  final totalLine =
      '${totals.map((t) => formatMoney(t.monthlyTotal, t.currency)).join(' · ')} / ay';

  // Unified ≈ total only when rates allow it (premium already established).
  var unifiedLine = '';
  if (rates != null) {
    final unified = unifiedMonthlyTotal(subs, target, rates);
    if (unified != null) {
      unifiedLine = '≈ ${formatMoney(unified.amount, target)} / ay';
    }
  }

  return WidgetPayload(
    state: WidgetState.ready,
    nextTitle: next.name,
    nextWhen: relativeDateLabel(nextRenewal, now),
    nextAmount: formatMoney(next.amount, next.currency),
    nextServiceKey: next.serviceKey ?? '',
    totalLine: totalLine,
    unifiedLine: unifiedLine,
  );
}
