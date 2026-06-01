import 'package:subsy/features/statistics/domain/category_breakdown.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// The sum of all subscriptions' period-normalized amounts converted to one
/// [target] currency (view-only, approximate). [amount] is un-rounded (callers
/// round for display). [missing] lists currencies excluded because no rate was
/// available; [partial] is true when any were excluded (FR-007).
class UnifiedTotal {
  const UnifiedTotal({
    required this.amount,
    required this.target,
    required this.missing,
  });

  final double amount;
  final Currency target;
  final List<Currency> missing;

  bool get partial => missing.isNotEmpty;
}

/// UI-facing gating state for the dashboard unified total (research.md D6).
sealed class UnifiedConversionState {
  const UnifiedConversionState();
}

/// Source data still loading (subscriptions/rates/target not resolved yet).
class UnifiedLoading extends UnifiedConversionState {
  const UnifiedLoading();
}

/// Not premium — show the upsell teaser instead of a real number (FR-014/015).
class UnifiedLocked extends UnifiedConversionState {
  const UnifiedLocked();
}

/// Premium but no usable rates — honest "unavailable" (FR-016).
class UnifiedUnavailable extends UnifiedConversionState {
  const UnifiedUnavailable();
}

/// Premium + rates — the real converted total.
class UnifiedReady extends UnifiedConversionState {
  const UnifiedReady(this.total, this.fetchedAt);
  final UnifiedTotal total;
  final DateTime fetchedAt;
}

/// Statistics counterpart carrying a converted category breakdown.
sealed class UnifiedStatsState {
  const UnifiedStatsState();
}

class UnifiedStatsLoading extends UnifiedStatsState {
  const UnifiedStatsLoading();
}

class UnifiedStatsLocked extends UnifiedStatsState {
  const UnifiedStatsLocked();
}

class UnifiedStatsUnavailable extends UnifiedStatsState {
  const UnifiedStatsUnavailable();
}

class UnifiedStatsReady extends UnifiedStatsState {
  const UnifiedStatsReady(this.breakdown, this.fetchedAt);
  final UnifiedCategoryBreakdown breakdown;
  final DateTime fetchedAt;
}

/// A unified, converted category breakdown for the statistics screen: category
/// slices already converted to [target] and period-scaled (view-only).
class UnifiedCategoryBreakdown {
  const UnifiedCategoryBreakdown({
    required this.target,
    required this.total,
    required this.slices,
    required this.missing,
  });

  final Currency target;
  final double total;
  final List<CategorySlice> slices;
  final List<Currency> missing;

  bool get partial => missing.isNotEmpty;
}
