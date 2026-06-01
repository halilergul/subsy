import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/currency/domain/exchange_rates.dart';
import 'package:subsy/features/currency/presentation/widgets/conversion_locked_teaser.dart';
import 'package:subsy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/presentation/subscription_form_screen.dart';

import '../support/fakes.dart';

/// Conversion surfaces — gated (SC-005), unlocked (SC-001/004), no-rates (SC-006),
/// and the form preview (FR-013).
void main() {
  final t = DateTime(2026, 6, 1);

  // 1 EUR = 1.10 USD = 45 TRY.
  final rates = ExchangeRates(
    base: Currency.eur,
    ratesPerBase: {Currency.eur: 1.0, Currency.usd: 1.10, Currency.tryl: 45.0},
    fetchedAt: t,
  );

  Subscription sub(double amount, Currency currency) => Subscription(
        name: 'X',
        amount: amount,
        currency: currency,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: t.add(const Duration(days: 5)),
        category: SubscriptionCategory.other,
        createdAt: t,
        updatedAt: t,
      );

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required bool premium,
    required ExchangeRates? rateData,
    Currency target = Currency.tryl,
  }) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        subscriptionsProvider.overrideWith(
            (ref) => Stream.value([sub(100, Currency.tryl), sub(10, Currency.usd)])),
        premiumStatusProvider.overrideWith((ref) => FakePremium(premium)),
        exchangeRatesProvider.overrideWith((ref) => Stream.value(rateData)),
        targetCurrencyProvider.overrideWith((ref) => Stream.value(target)),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('premium + rates → unified ≈ total shown beside per-currency (SC-001)',
      (tester) async {
    await pumpDashboard(tester, premium: true, rateData: rates);
    expect(find.textContaining('Toplam ≈'), findsOneWidget);
    expect(find.textContaining('₺'), findsWidgets); // per-currency rows intact
    expect(find.byType(ConversionLockedTeaser), findsNothing);
  });

  testWidgets('target currency re-expresses the unified total (SC-004)', (tester) async {
    await pumpDashboard(tester, premium: true, rateData: rates, target: Currency.usd);
    // Unified total now in USD.
    expect(find.textContaining('Toplam ≈ \$'), findsOneWidget);
  });

  testWidgets('free user → locked teaser, never a real number (SC-005)', (tester) async {
    await pumpDashboard(tester, premium: false, rateData: rates);
    expect(find.byType(ConversionLockedTeaser), findsOneWidget);
    expect(find.textContaining('Toplam ≈'), findsNothing);
  });

  testWidgets('premium + no rates → honest unavailable, per-currency intact (SC-006)',
      (tester) async {
    await pumpDashboard(tester, premium: true, rateData: null);
    expect(find.textContaining('kurlar henüz alınamadı'), findsOneWidget);
    expect(find.textContaining('Toplam ≈'), findsNothing);
    expect(find.textContaining('₺'), findsWidgets); // per-currency unaffected
  });

  // --- Form preview (FR-013) ---

  Future<void> pumpForm(
    WidgetTester tester, {
    required bool premium,
    required Currency target,
  }) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(FakeSubscriptionRepository()),
        premiumStatusProvider.overrideWith((ref) => FakePremium(premium)),
        exchangeRatesProvider.overrideWith((ref) => Stream.value(rates)),
        targetCurrencyProvider.overrideWith((ref) => Stream.value(target)),
      ],
      child: const MaterialApp(home: SubscriptionFormScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('form shows ≈ preview for a non-target amount (premium)', (tester) async {
    // Default form currency is TRY; target USD → preview appears.
    await pumpForm(tester, premium: true, target: Currency.usd);
    await tester.enterText(find.byType(TextField).at(1), '100'); // Tutar field
    await tester.pumpAndSettle();
    expect(find.textContaining('≈ \$'), findsOneWidget);
  });

  testWidgets('form hides preview when currency equals target', (tester) async {
    await pumpForm(tester, premium: true, target: Currency.tryl); // TRY == TRY
    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.pumpAndSettle();
    expect(find.textContaining('≈'), findsNothing);
  });

  testWidgets('form hides preview for free users', (tester) async {
    await pumpForm(tester, premium: false, target: Currency.usd);
    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.pumpAndSettle();
    expect(find.textContaining('≈'), findsNothing);
  });
}
