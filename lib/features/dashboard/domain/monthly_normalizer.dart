import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/shared/constants/dashboard_constants.dart';

/// Normalizes a subscription's amount to a monthly figure:
/// weekly × (52/12), yearly ÷ 12, monthly × 1.
double monthlyAmount(Subscription s) => switch (s.billingPeriod) {
      BillingPeriod.weekly => s.amount * kWeeksPerYear / kMonthsPerYear,
      BillingPeriod.yearly => s.amount / kMonthsPerYear,
      BillingPeriod.monthly => s.amount,
    };
