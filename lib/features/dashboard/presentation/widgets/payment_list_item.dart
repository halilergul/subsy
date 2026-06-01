import 'package:flutter/material.dart';
import 'package:subsy/features/dashboard/domain/relative_date_label.dart';
import 'package:subsy/features/dashboard/domain/upcoming_payment.dart';
import 'package:subsy/features/subscriptions/domain/brand_catalog.dart';
import 'package:subsy/shared/utils/money_format.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';

/// A single upcoming-payment card: brand avatar + name + amount + relative
/// renewal label, with a brand-color left accent.
class PaymentListItem extends StatelessWidget {
  const PaymentListItem({
    super.key,
    required this.payment,
    this.now,
    this.onTap,
  });

  final UpcomingPayment payment;

  /// Injectable for deterministic tests; defaults to DateTime.now().
  final DateTime? now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = payment.subscription;
    final accent = brandByKey(sub.serviceKey)?.brandColor;
    final label = relativeDateLabel(payment.effectiveRenewal, now ?? DateTime.now());

    return Card(
      color: const Color(0xFF17171D),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Brand-color left accent.
              Container(width: 4, color: accent != null ? Color(accent) : Colors.transparent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      BrandAvatar(serviceKey: sub.serviceKey, fallbackName: sub.name),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatMoney(sub.amount, sub.currency),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
