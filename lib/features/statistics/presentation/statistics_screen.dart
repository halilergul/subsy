import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/features/currency/presentation/widgets/unified_total_view.dart';
import 'package:subsy/features/statistics/application/statistics_providers.dart';
import 'package:subsy/features/statistics/domain/category_breakdown.dart';
import 'package:subsy/features/statistics/domain/ranked_subscription.dart';
import 'package:subsy/features/statistics/domain/stat_period.dart';
import 'package:subsy/features/statistics/presentation/widgets/category_donut.dart';
import 'package:subsy/features/statistics/presentation/widgets/category_legend.dart';
import 'package:subsy/features/statistics/presentation/widgets/top_subscriptions.dart';
import 'package:subsy/shared/utils/money_format.dart';

/// Read-only spending statistics: per-currency category breakdown (donut +
/// legend), per-currency total, and the most expensive subscriptions, scaled
/// to the selected period. Dark mode + Turkish; renders loading/error/empty.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is AppError ? error.message : 'İstatistikler yüklenemedi.',
        ),
        data: (view) {
          if (view.isEmpty) return const _EmptyState();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const _PeriodToggle(),
              const SizedBox(height: 20),
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

/// Aylık/Yıllık segmented control bound to [statPeriodProvider].
class _PeriodToggle extends ConsumerWidget {
  const _PeriodToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statPeriodProvider);
    return Center(
      child: SegmentedButton<StatPeriod>(
        segments: const [
          ButtonSegment(value: StatPeriod.monthly, label: Text('Aylık')),
          ButtonSegment(value: StatPeriod.yearly, label: Text('Yıllık')),
        ],
        selected: {period},
        onSelectionChanged: (selection) =>
            ref.read(statPeriodProvider.notifier).state = selection.first,
      ),
    );
  }
}

/// One currency's section: total + donut + legend + the top list.
class _CurrencySection extends StatelessWidget {
  const _CurrencySection({
    required this.breakdown,
    required this.period,
    required this.top,
  });

  final CategoryBreakdown breakdown;
  final StatPeriod period;
  final List<RankedSubscription> top;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodLabel = period == StatPeriod.monthly ? 'aylık' : 'yıllık';

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Toplam ($periodLabel)',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(breakdown.total, breakdown.currency),
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Center(child: CategoryDonut(breakdown: breakdown)),
          const SizedBox(height: 16),
          CategoryLegend(breakdown: breakdown),
          if (top.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('En pahalı', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            TopSubscriptions(items: top),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pie_chart_outline,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Görüntülenecek veri yok',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Abonelik ekleyince harcama dağılımın burada görünecek.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
