import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:subsy/features/dashboard/presentation/widgets/payment_list_item.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// US1 — list renders sorted by effective renewal (maps SC-001).
void main() {
  final now = DateTime.now();

  Subscription sub(String name, int daysFromNow) {
    final t = DateTime(2026, 1, 1);
    return Subscription(
      name: name,
      // serviceKey null → BrandAvatar uses initial fallback (no asset load in tests)
      amount: 50,
      currency: Currency.tryl,
      billingPeriod: BillingPeriod.monthly,
      nextRenewalDate: now.add(Duration(days: daysFromNow)),
      category: SubscriptionCategory.other,
      createdAt: t,
      updatedAt: t,
    );
  }

  Widget harness(List<Subscription> subs) {
    return ProviderScope(
      overrides: [
        subscriptionsProvider.overrideWith((ref) => Stream.value(subs)),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    );
  }

  testWidgets('renders subscriptions sorted by soonest renewal', (tester) async {
    await tester.pumpWidget(harness([sub('Late', 10), sub('Soon', 2)]));
    await tester.pumpAndSettle();

    final names = tester
        .widgetList<PaymentListItem>(find.byType(PaymentListItem))
        .map((w) => w.payment.subscription.name)
        .toList();
    expect(names, ['Soon', 'Late']);
  });

  testWidgets('shows a FAB when there are subscriptions', (tester) async {
    await tester.pumpWidget(harness([sub('Netflix', 3)]));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
