import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/currency/domain/unified_total.dart';
import 'package:subsy/features/currency/presentation/widgets/conversion_locked_teaser.dart';
import 'package:subsy/features/statistics/domain/category_breakdown.dart';
import 'package:subsy/features/statistics/presentation/widgets/category_donut.dart';
import 'package:subsy/features/statistics/presentation/widgets/category_legend.dart';
import 'package:subsy/shared/utils/money_format.dart';

/// Statistics "Birleşik" section: the converted ≈ total + a unified category
/// breakdown (reusing the donut + legend), period-scaled. Premium → real
/// figures; free → locked teaser; premium-without-rates → honest note. Shown
/// alongside (never replacing) the per-currency sections.
class UnifiedTotalView extends ConsumerWidget {
  const UnifiedTotalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unifiedStatisticsProvider);
    final theme = Theme.of(context);

    switch (state) {
      case UnifiedStatsLoading():
        return const SizedBox.shrink();
      case UnifiedStatsLocked():
        return _section(theme, const ConversionLockedTeaser());
      case UnifiedStatsUnavailable():
        return _section(
          theme,
          Text(
            'Birleşik toplam için kurlar henüz alınamadı.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        );
      case UnifiedStatsReady(:final breakdown):
        return _section(theme, _Ready(breakdown: breakdown));
    }
  }

  Widget _section(ThemeData theme, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Birleşik', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.breakdown});

  final UnifiedCategoryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Adapt to the existing per-currency widgets (currency = target).
    final adapted = CategoryBreakdown(
      currency: breakdown.target,
      total: breakdown.total,
      slices: breakdown.slices,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '≈ ${formatMoney(breakdown.total, breakdown.target)}',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Center(child: CategoryDonut(breakdown: adapted)),
        const SizedBox(height: 16),
        CategoryLegend(breakdown: adapted),
        if (breakdown.partial) ...[
          const SizedBox(height: 4),
          Text(
            'Bazı para birimleri güncel kur olmadan hariç tutuldu.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
