import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/statistics/presentation/statistics_screen.dart';
import 'package:subsy/features/statistics/presentation/widgets/category_donut.dart';
import 'package:subsy/features/statistics/presentation/widgets/category_legend.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Screen states — empty (SC-006) vs data (US1 render).
void main() {
  final t = DateTime(2026, 1, 1);

  Subscription sub(double amount, SubscriptionCategory category) => Subscription(
        name: 'X',
        amount: amount,
        currency: Currency.tryl,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: t,
        category: category,
        createdAt: t,
        updatedAt: t,
      );

  Widget harness(List<Subscription> subs) => ProviderScope(
        overrides: [
          subscriptionsProvider.overrideWith((ref) => Stream.value(subs)),
        ],
        child: const MaterialApp(home: StatisticsScreen()),
      );

  testWidgets('empty subscriptions → empty state, no chart', (tester) async {
    await tester.pumpWidget(harness([]));
    await tester.pumpAndSettle();

    expect(find.text('Görüntülenecek veri yok'), findsOneWidget);
    expect(find.byType(CategoryDonut), findsNothing);
  });

  testWidgets('non-empty → donut + legend rendered', (tester) async {
    await tester.pumpWidget(harness([
      sub(100, SubscriptionCategory.streaming),
      sub(50, SubscriptionCategory.music),
    ]));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryDonut), findsOneWidget);
    expect(find.byType(CategoryLegend), findsOneWidget);
    expect(find.text('Görüntülenecek veri yok'), findsNothing);
  });
}
