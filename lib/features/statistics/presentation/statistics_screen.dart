import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/features/currency/presentation/widgets/unified_total_view.dart';
import 'package:subsy/features/statistics/application/statistics_providers.dart';
import 'package:subsy/features/statistics/domain/category_breakdown.dart';
import 'package:subsy/features/statistics/domain/ranked_subscription.dart';
import 'package:subsy/features/statistics/domain/stat_period.dart';
import 'package:subsy/features/statistics/presentation/widgets/category_donut.dart';
import 'package:subsy/features/statistics/presentation/widgets/top_subscriptions.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/shared/constants/category_style.dart';
import 'package:subsy/shared/utils/money_format.dart';

/// Read-only spending statistics: per-currency category breakdown (donut with a
/// top-category center, legend and stat cards), plus the most expensive
/// subscriptions, scaled to the selected period. Dark, gold-accented.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('İstatistik', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is AppError ? error.message : 'İstatistikler yüklenemedi.',
        ),
        data: (view) {
          if (view.isEmpty) return const _EmptyState();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _PeriodToggle(),
              const SizedBox(height: 18),
              const UnifiedTotalView(),
              for (final breakdown in view.breakdowns)
                _CurrencySection(
                  breakdown: breakdown,
                  period: view.period,
                  top: view.topByCurrency[breakdown.currency] ?? const [],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Aylık/Yıllık gold segmented control bound to [statPeriodProvider].
class _PeriodToggle extends ConsumerWidget {
  const _PeriodToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statPeriodProvider);
    Widget tab(StatPeriod p, String label) {
      final active = period == p;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ref.read(statPeriodProvider.notifier).state = p,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppTokens.surface2 : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: active ? AppTokens.segShadow : null,
            ),
            child: Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? AppTokens.text : AppTokens.muted,
                )),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppTokens.fillSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTokens.hair, width: 0.5),
          ),
          child: Row(
            children: [
              tab(StatPeriod.monthly, 'Aylık'),
              const SizedBox(width: 4),
              tab(StatPeriod.yearly, 'Yıllık'),
            ],
          ),
        ),
      ),
    );
  }
}

/// One currency's section: a card with donut + legend, then stat cards and the
/// most-expensive list.
class _CurrencySection extends StatelessWidget {
  const _CurrencySection({required this.breakdown, required this.period, required this.top});

  final CategoryBreakdown breakdown;
  final StatPeriod period;
  final List<RankedSubscription> top;

  CategorySlice? get _topSlice {
    if (breakdown.slices.isEmpty) return null;
    return breakdown.slices.reduce((a, b) => a.amount >= b.amount ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final cur = breakdown.currency;
    // breakdown.total is already period-scaled; derive the monthly base.
    final monthlyTotal = period == StatPeriod.monthly ? breakdown.total : breakdown.total / 12;
    final yearly = monthlyTotal * 12;
    final avg = breakdown.slices.isEmpty ? 0.0 : monthlyTotal / breakdown.slices.length;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${currencySymbol(cur)} ${cur.code}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.tertiary, letterSpacing: 0.5),
                  ),
                ),
                _donut(cur),
                const SizedBox(height: 12),
                _legend(cur),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard('Yıllık', formatMoneyTr(yearly, cur, decimals: 0), 'aylık × 12')),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Ort. / kategori', formatMoneyTr(avg, cur, decimals: 0), 'aylık')),
            ],
          ),
          if (top.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 6),
              child: Text('En pahalı', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTokens.text)),
            ),
            TopSubscriptions(items: top),
          ],
        ],
      ),
    );
  }

  Widget _donut(Currency cur) {
    final top = _topSlice;
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CategoryDonut(breakdown: breakdown),
          if (top != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: categoryColor(top.category), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(categoryLabel(top.category),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTokens.muted)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(formatMoneyTr(top.amount, cur, decimals: 0),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: -1, color: AppTokens.text)),
                const SizedBox(height: 2),
                Text('%${top.percentage.round()} · en yüksek',
                    style: const TextStyle(fontSize: 12.5, color: AppTokens.tertiary)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _legend(Currency cur) {
    final slices = [...breakdown.slices]..sort((a, b) => b.amount.compareTo(a.amount));
    return Column(
      children: [
        for (var i = 0; i < slices.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              border: i == 0 ? null : const Border(top: BorderSide(color: AppTokens.hair, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: categoryColor(slices[i].category), borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(categoryLabel(slices[i].category), style: const TextStyle(fontSize: 14.5, color: AppTokens.text))),
                Text(formatMoneyTr(slices[i].amount, cur, decimals: 0),
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppTokens.text)),
                SizedBox(
                  width: 42,
                  child: Text('%${slices[i].percentage.round()}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12.5, color: AppTokens.tertiary)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _statCard(String label, String value, String hint) {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTokens.tertiary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w300, letterSpacing: -0.6, color: AppTokens.text)),
          ),
          const SizedBox(height: 2),
          Text(hint, style: const TextStyle(fontSize: 12, color: AppTokens.tertiary)),
        ],
      ),
    );
  }

  Widget _card({required Widget child, required EdgeInsets padding}) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTokens.hair, width: 0.5),
        ),
        child: child,
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pie_chart_outline, size: 56, color: AppTokens.tertiary),
            SizedBox(height: 12),
            Text('Görüntülenecek veri yok',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTokens.text), textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text('Abonelik ekleyince harcama dağılımın burada görünecek.',
                style: TextStyle(color: AppTokens.muted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTokens.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppTokens.text)),
          ],
        ),
      ),
    );
  }
}
