import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Small muted section heading (e.g. "Yaklaşan ödemeler", "Haziran 2026").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: color ?? AppTokens.muted,
      ),
    );
  }
}

/// Billing-cadence pill (Haftalık / Aylık / Yıllık) shown next to amounts.
class PeriodPill extends StatelessWidget {
  const PeriodPill({super.key, required this.period});

  final BillingPeriod period;

  static String labelOf(BillingPeriod p) => switch (p) {
        BillingPeriod.weekly => 'Haftalık',
        BillingPeriod.monthly => 'Aylık',
        BillingPeriod.yearly => 'Yıllık',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTokens.fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTokens.hair, width: 0.5),
      ),
      child: Text(
        labelOf(period),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTokens.tertiary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
