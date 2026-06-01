import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3.x moved StateProvider to the legacy export.
import 'package:flutter_riverpod/legacy.dart';
import 'package:subsy/features/statistics/domain/stat_period.dart';
import 'package:subsy/features/statistics/domain/statistics_calculator.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';

/// Selected statistics horizon (UI state); default monthly.
final statPeriodProvider = StateProvider<StatPeriod>((_) => StatPeriod.monthly);

/// Derived statistics view. Recomputes when the subscription stream emits
/// (add/edit/delete — FR-010) or the period toggles. Mirrors the source
/// AsyncValue's loading/error states.
final statisticsProvider = Provider((ref) {
  final period = ref.watch(statPeriodProvider);
  return ref
      .watch(subscriptionsProvider)
      .whenData((subs) => buildStatistics(subs, period));
});
