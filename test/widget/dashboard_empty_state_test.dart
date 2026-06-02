import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:subsy/features/dashboard/presentation/widgets/dashboard_empty_state.dart';
import 'package:subsy/features/dashboard/presentation/widgets/dashboard_fab.dart';
import 'package:subsy/features/dashboard/presentation/widgets/sub_row.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// US3 — empty state (maps SC-007).
void main() {
  testWidgets('shows empty state + add CTA when there are no subscriptions',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionsProvider
              .overrideWith((ref) => Stream.value(<Subscription>[])),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DashboardEmptyState), findsOneWidget);
    expect(find.text('Henüz abonelik yok'), findsOneWidget);
    expect(find.text('Abonelik ekle'), findsOneWidget);
    expect(find.byType(SubRow), findsNothing);
    // No FAB in the empty state (the CTA button is used instead).
    expect(find.byType(DashboardFab), findsNothing);
  });
}
