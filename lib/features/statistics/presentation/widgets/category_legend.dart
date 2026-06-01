import 'package:flutter/material.dart';
import 'package:subsy/features/statistics/domain/category_breakdown.dart';
import 'package:subsy/shared/utils/money_format.dart';
import 'package:subsy/shared/constants/category_style.dart';

/// Legend list for a currency's breakdown: one row per category with a color
/// dot (matching the donut), the Turkish label, the period amount, and the
/// percentage. Doubles as the textual "bar" representation of the chart.
class CategoryLegend extends StatelessWidget {
  const CategoryLegend({super.key, required this.breakdown});

  final CategoryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final slice in breakdown.slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: categoryColor(slice.category),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    categoryLabel(slice.category),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  formatMoney(slice.amount, breakdown.currency),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 44,
                  child: Text(
                    '%${slice.percentage.toStringAsFixed(0)}',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
