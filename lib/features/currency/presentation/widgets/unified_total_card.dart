import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/currency/domain/unified_total.dart';
import 'package:subsy/features/currency/presentation/widgets/conversion_locked_teaser.dart';
import 'package:subsy/features/currency/presentation/widgets/target_currency_selector.dart';
import 'package:subsy/shared/utils/money_format.dart';

/// Dashboard unified spending total, expressed in the chosen target currency.
/// Premium → "Toplam ≈ {amount}" + target selector + "last updated"; free →
/// locked teaser; premium-without-rates → honest Turkish note. Always additive
/// — the per-currency rows above it are untouched (FR-018).
class UnifiedTotalCard extends ConsumerWidget {
  const UnifiedTotalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unifiedDashboardTotalProvider);
    final theme = Theme.of(context);

    final Widget content = switch (state) {
      UnifiedLoading() => const SizedBox.shrink(),
      UnifiedLocked() => const ConversionLockedTeaser(),
      UnifiedUnavailable() => Text(
          'Birleşik toplam için kurlar henüz alınamadı — çevrimiçi olunca güncellenecek.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      UnifiedReady(:final total, :final fetchedAt) =>
        _ReadyTotal(total: total, fetchedAt: fetchedAt),
    };

    if (state is UnifiedLoading) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}

class _ReadyTotal extends StatelessWidget {
  const _ReadyTotal({required this.total, required this.fetchedAt});

  final UnifiedTotal total;
  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Toplam ≈ ${formatMoney(total.amount, total.target)}',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  Text('/ay',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const TargetCurrencySelector(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Kurlar: ${_formatDate(fetchedAt)} (en son güncelleme)',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (total.partial) ...[
          const SizedBox(height: 2),
          Text(
            'Bazı para birimleri güncel kur olmadan hariç tutuldu.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  static String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}.${l.year}';
  }
}
