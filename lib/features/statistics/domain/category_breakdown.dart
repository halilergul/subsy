import 'package:subsy/features/subscriptions/domain/enums.dart';

/// A single category's share within one currency's breakdown (view-only).
class CategorySlice {
  const CategorySlice({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  final SubscriptionCategory category;

  /// Period-normalized total for this category, within its currency.
  final double amount;

  /// Share of the currency total (0–100), display-rounded so a breakdown's
  /// slices sum to exactly 100 (the largest slice absorbs the remainder).
  final double percentage;
}

/// One currency's category breakdown (view-only). Currencies are never blended.
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.currency,
    required this.total,
    required this.slices,
  });

  final Currency currency;

  /// Period-normalized total across this currency's categories.
  final double total;

  /// Category slices sorted by [CategorySlice.amount] descending; categories
  /// with no subscriptions are omitted.
  final List<CategorySlice> slices;
}
