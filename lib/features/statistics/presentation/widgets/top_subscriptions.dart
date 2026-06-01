import 'package:flutter/material.dart';
import 'package:subsy/features/statistics/domain/ranked_subscription.dart';
import 'package:subsy/shared/utils/money_format.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';

/// Ranked "most expensive" list for one currency. A dumb renderer of the
/// already-sorted [items] (descending by period amount); reuses [BrandAvatar].
class TopSubscriptions extends StatelessWidget {
  const TopSubscriptions({super.key, required this.items});

  final List<RankedSubscription> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                BrandAvatar(
                  serviceKey: item.subscription.serviceKey,
                  fallbackName: item.subscription.name,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.subscription.name,
                    style: theme.textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatMoney(item.amount, item.subscription.currency),
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
