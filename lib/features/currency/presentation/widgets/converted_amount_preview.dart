import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/currency/domain/currency_constants.dart';
import 'package:subsy/features/currency/domain/currency_converter.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/shared/utils/money_format.dart';

/// Inline live preview of [amount] in [from] converted to the target currency,
/// shown in the subscription form. Premium-only; hidden when the amount is
/// empty/invalid, when [from] equals the target, or when no rates are available
/// (FR-013).
class ConvertedAmountPreview extends ConsumerWidget {
  const ConvertedAmountPreview({super.key, required this.amount, required this.from});

  final double? amount;
  final Currency from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(conversionEnabledProvider)) return const SizedBox.shrink();

    final amt = amount;
    if (amt == null || amt <= 0) return const SizedBox.shrink();

    final target =
        ref.watch(targetCurrencyProvider).asData?.value ?? kDefaultTargetCurrency;
    if (from == target) return const SizedBox.shrink();

    final rates = ref.watch(exchangeRatesProvider).asData?.value;
    if (rates == null) return const SizedBox.shrink();

    final converted = convertAmount(amt, from, target, rates);
    if (converted == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '≈ ${formatMoney(converted, target)}',
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
