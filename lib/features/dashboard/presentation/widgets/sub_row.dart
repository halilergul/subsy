import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/dashboard/domain/relative_date_label.dart';
import 'package:subsy/features/dashboard/domain/upcoming_payment.dart';
import 'package:subsy/features/dashboard/presentation/widgets/dashboard_chrome.dart';
import 'package:subsy/shared/utils/money_format.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';

/// One upcoming-payment row: circular logo + name + relative renewal +
/// amount + period pill. Renewals due within 3 days are tinted gold.
class SubRow extends StatelessWidget {
  const SubRow({super.key, required this.payment, this.now, this.onTap});

  final UpcomingPayment payment;
  final DateTime? now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sub = payment.subscription;
    final label = relativeDateLabel(payment.effectiveRenewal, now ?? DateTime.now());
    final soon = payment.daysUntil <= 3;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            BrandAvatar(serviceKey: sub.serviceKey, fallbackName: sub.name, size: 44, circle: true),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.text,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: soon ? AppTokens.accentFg : AppTokens.muted,
                      fontWeight: soon ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoneyTr(sub.amount, sub.currency),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.text),
                ),
                const SizedBox(height: 5),
                PeriodPill(period: sub.billingPeriod),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Groups rows into a single rounded card with inset hairline dividers, as in
/// the design (one surface, logo-aligned separators).
class SubscriptionListCard extends StatelessWidget {
  const SubscriptionListCard({
    super.key,
    required this.payments,
    this.now,
    this.onTap,
  });

  final List<UpcomingPayment> payments;
  final DateTime? now;
  final void Function(UpcomingPayment payment)? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < payments.length; i++) ...[
            SubRow(
              payment: payments[i],
              now: now,
              onTap: onTap == null ? null : () => onTap!(payments[i]),
            ),
            if (i < payments.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 71),
                child: Divider(height: 0.5, thickness: 0.5, color: AppTokens.hair),
              ),
          ],
        ],
      ),
    );
  }
}
