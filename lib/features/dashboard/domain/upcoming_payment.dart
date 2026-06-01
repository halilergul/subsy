import 'package:subsy/features/dashboard/domain/renewal_calculator.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// View model: a subscription plus its computed display data for the
/// upcoming-payments list. Not persisted.
class UpcomingPayment {
  const UpcomingPayment({
    required this.subscription,
    required this.effectiveRenewal,
    required this.daysUntil,
  });

  final Subscription subscription;
  final DateTime effectiveRenewal;
  final int daysUntil;

  factory UpcomingPayment.from(Subscription s, DateTime now) {
    final renewal = effectiveNextRenewal(s, now);
    final days = DateTime(renewal.year, renewal.month, renewal.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    return UpcomingPayment(
      subscription: s,
      effectiveRenewal: renewal,
      daysUntil: days,
    );
  }
}
