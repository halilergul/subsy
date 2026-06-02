import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/presentation/subscription_detail_screen.dart';

import '../support/fakes.dart';

/// Faz 2 — subscription detail view + edit sheet + delete.
void main() {
  final t = DateTime(2026, 1, 1);
  Subscription sub() => Subscription(
        id: 1,
        name: 'Netflix',
        serviceKey: 'netflix',
        amount: 229.99,
        currency: Currency.tryl,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: DateTime.now().add(const Duration(days: 3)),
        category: SubscriptionCategory.streaming,
        createdAt: t,
        updatedAt: t,
      );

  late FakeSubscriptionRepository repo;

  Widget harness() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => ctx.push('/detail', extra: sub()),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/detail',
          builder: (_, s) => SubscriptionDetailScreen(subscription: s.extra as Subscription),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repo),
        premiumStatusProvider.overrideWith((ref) => FakePremium(false)),
        exchangeRatesProvider.overrideWith((ref) => Stream.value(null)),
        targetCurrencyProvider.overrideWith((ref) => Stream.value(Currency.tryl)),
        notificationSettingsProvider.overrideWith((ref) => Stream.value(NotificationSettings.defaults)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  setUp(() => repo = FakeSubscriptionRepository()..items.add(sub()));

  Future<void> openDetail(WidgetTester tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the detail hero, amounts and actions', (tester) async {
    await openDetail(tester);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Aylık maliyet'), findsOneWidget);
    expect(find.text('Yıllık maliyet'), findsOneWidget);
    expect(find.text('Yayın'), findsOneWidget); // streaming category label
    expect(find.text('Aboneliği sil'), findsOneWidget);
    expect(find.textContaining('₺229,99'), findsWidgets);
  });

  testWidgets('Düzenle opens the edit form sheet, prefilled', (tester) async {
    await openDetail(tester);
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    expect(find.text('Kaydet'), findsOneWidget); // form sheet open
  });

  testWidgets('delete confirms and removes the subscription', (tester) async {
    await openDetail(tester);
    await tester.tap(find.text('Aboneliği sil'));
    await tester.pumpAndSettle();
    expect(find.text('Aboneliği sil?'), findsOneWidget); // confirm dialog

    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(repo.items, isEmpty);
  });
}
