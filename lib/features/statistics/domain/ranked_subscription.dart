import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// A subscription paired with its period-normalized amount, for the
/// "most expensive" ranking (view-only). Ranked within a currency only.
class RankedSubscription {
  const RankedSubscription({required this.subscription, required this.amount});

  final Subscription subscription;

  /// Period-normalized amount used for ordering.
  final double amount;
}
