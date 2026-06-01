import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/currency/domain/currency_constants.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Compact TRY/USD/EUR selector for the unified total. Writes through the
/// target-currency repository (persisted) so every converted figure re-expresses
/// (FR-010). Defaults to TRY until the setting stream resolves.
class TargetCurrencySelector extends ConsumerWidget {
  const TargetCurrencySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target =
        ref.watch(targetCurrencyProvider).asData?.value ?? kDefaultTargetCurrency;

    return DropdownButton<Currency>(
      value: target,
      isDense: true,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(12),
      items: [
        for (final c in Currency.values)
          DropdownMenuItem(value: c, child: Text(c.code)),
      ],
      onChanged: (c) {
        if (c != null) ref.read(targetCurrencyRepositoryProvider).save(c);
      },
    );
  }
}
