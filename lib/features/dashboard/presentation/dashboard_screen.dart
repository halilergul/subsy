import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/features/dashboard/application/dashboard_providers.dart';
import 'package:subsy/features/dashboard/presentation/widgets/dashboard_empty_state.dart';
import 'package:subsy/features/dashboard/presentation/widgets/monthly_summary_card.dart';
import 'package:subsy/features/dashboard/presentation/widgets/payment_list_item.dart';

/// Home screen: read-only view of upcoming payments + monthly summary.
/// Renders loading / error / empty / data states from the derived providers.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingPaymentsProvider);
    final hasItems = upcoming.asData?.value.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Subsy')),
      body: upcoming.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is AppError ? error.message : 'Abonelikler yüklenemedi.',
        ),
        data: (items) {
          if (items.isEmpty) {
            return DashboardEmptyState(onAdd: () => _onAdd(context));
          }
          final totals = ref.watch(monthlySummaryProvider).asData?.value ?? const [];
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MonthlySummaryCard(totals: totals),
                );
              }
              final payment = items[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PaymentListItem(payment: payment),
              );
            },
          );
        },
      ),
      floatingActionButton: hasItems
          ? FloatingActionButton(
              onPressed: () => _onAdd(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// Navigates toward the add-subscription flow. The destination screen is a
  /// separate, later feature; for now this is a placeholder.
  void _onAdd(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abonelik ekleme yakında.')),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
