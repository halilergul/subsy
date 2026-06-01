import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:subsy/features/statistics/domain/category_breakdown.dart';
import 'package:subsy/shared/constants/category_style.dart';

/// Donut chart for one currency's category breakdown. A "dumb" renderer: it
/// only draws the already-computed [CategoryBreakdown] slices, sized by raw
/// amount and colored by the shared category color (matching the legend).
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({super.key, required this.breakdown, this.size = 200});

  final CategoryBreakdown breakdown;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: size * 0.28,
          sectionsSpace: 2,
          sections: [
            for (final slice in breakdown.slices)
              PieChartSectionData(
                value: slice.amount,
                color: categoryColor(slice.category),
                radius: size * 0.18,
                showTitle: false,
              ),
          ],
        ),
      ),
    );
  }
}
