import 'package:flutter/material.dart';
import 'package:subsy/features/currency/presentation/widgets/unified_total_card.dart';
import 'package:subsy/features/dashboard/domain/currency_summary.dart';
import 'package:subsy/shared/utils/money_format.dart';

/// Monthly spend summary. One row per currency (no cross-currency total),
/// each showing the monthly-normalized amount with a "/ay" suffix. Below the
/// per-currency rows, the premium unified total (or its teaser) is shown.
class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({super.key, required this.totals});

  final List<CurrencyTotal> totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (totals.isEmpty) return const SizedBox.shrink();

    return Card(
      color: const Color(0xFF17171D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aylık toplam',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final t in totals)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatMoney(t.monthlyTotal, t.currency),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ay',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            const UnifiedTotalCard(),
          ],
        ),
      ),
    );
  }
}
