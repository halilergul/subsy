import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/presentation/widgets/add_sheet.dart';

import '../support/fakes.dart';

/// Add flow via the brand-picker sheet → detail form sheet → save.
void main() {
  late FakeSubscriptionRepository repo;

  Widget harness() {
    return ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repo),
        premiumStatusProvider.overrideWith((ref) => FakePremium(false)),
        exchangeRatesProvider.overrideWith((ref) => Stream.value(null)),
        targetCurrencyProvider.overrideWith((ref) => Stream.value(Currency.tryl)),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAddSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  setUp(() => repo = FakeSubscriptionRepository());

  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('picker shows search, popular grid and scan footer', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Abonelik Ekle'), findsOneWidget);
    expect(find.text('Servis ara'), findsOneWidget); // search hint
    expect(find.text('Popüler Servisler'), findsOneWidget);
    expect(find.text('Dokümandan Tara'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });

  testWidgets('pick a brand → form opens → save persists and closes the sheets',
      (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();

    // Detail form sheet.
    expect(find.text('Kaydet'), findsOneWidget);

    // Enter the amount (field identified by its 0,00 hint).
    final amountField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == '0,00',
    );
    expect(amountField, findsOneWidget);
    await tester.enterText(amountField, '50');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    // Saved through the real use case + both sheets dismissed.
    expect(repo.items, hasLength(1));
    expect(repo.items.first.name, 'Netflix');
    expect(repo.items.first.amount, 50);
    expect(repo.items.first.serviceKey, 'netflix'); // brand enrichment ran
    expect(find.text('Abonelik Ekle'), findsNothing);
  });
}
