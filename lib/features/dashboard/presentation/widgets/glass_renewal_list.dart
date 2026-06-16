import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/dashboard/domain/relative_date_label.dart';
import 'package:subsy/features/dashboard/domain/upcoming_payment.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/presentation/glass_detail_sheet.dart';
import 'package:subsy/shared/utils/money_format.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// A grouped glass card of upcoming-renewal rows (logo · name · relative date ·
/// amount · period pill). Shared by Pano and Takvim. Tapping a row opens the
/// subscription detail.
class GlassRenewalCard extends StatelessWidget {
  const GlassRenewalCard({super.key, required this.payments, required this.now});

  final List<UpcomingPayment> payments;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 26,
      fill: GlassFill.strong,
      child: Column(
        children: [
          for (var i = 0; i < payments.length; i++)
            GlassRenewalRow(
              payment: payments[i],
              now: now,
              last: i == payments.length - 1,
            ),
        ],
      ),
    );
  }
}

/// One renewal row. Highlights the relative date in gold when due within 3 days.
class GlassRenewalRow extends StatelessWidget {
  const GlassRenewalRow({
    super.key,
    required this.payment,
    required this.now,
    this.last = true,
  });

  final UpcomingPayment payment;
  final DateTime now;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final sub = payment.subscription;
    final soon = payment.daysUntil <= 3;
    final when = relativeDateLabel(payment.effectiveRenewal, now);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showSubscriptionDetailSheet(context, sub),
        child: Container(
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(bottom: BorderSide(color: AppTokens.hair, width: 0.5)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          child: Row(
            children: [
              BrandAvatar(
                serviceKey: sub.serviceKey,
                fallbackName: sub.name,
                size: 44,
                circle: true,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.text,
                            letterSpacing: -0.2)),
                    const SizedBox(height: 2),
                    Text(when,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: soon ? FontWeight.w600 : FontWeight.w400,
                            color: soon ? AppTokens.accentFg : AppTokens.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatMoneyTr(sub.amount, sub.currency),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.text)),
                  const SizedBox(height: 5),
                  GlassPill(text: periodLabel(sub.billingPeriod)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Turkish billing-period label.
String periodLabel(BillingPeriod p) => switch (p) {
      BillingPeriod.weekly => 'Haftalık',
      BillingPeriod.monthly => 'Aylık',
      BillingPeriod.yearly => 'Yıllık',
    };

/// Small soft-glass pill used for period badges and inline tags.
class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 8,
      fill: GlassFill.soft,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTokens.tertiary,
              letterSpacing: 0.2)),
    );
  }
}
