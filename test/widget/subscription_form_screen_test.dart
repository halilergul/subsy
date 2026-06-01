import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/presentation/subscription_form_screen.dart';

import '../support/fakes.dart';

void main() {
  late FakeSubscriptionRepository repo;

  setUp(() => repo = FakeSubscriptionRepository());

  Widget harness({Subscription? editing}) {
    return ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repo),
        premiumStatusProvider.overrideWith((ref) => FakePremium(false)),
      ],
      child: MaterialApp(home: SubscriptionFormScreen(subscription: editing)),
    );
  }

  // Tall surface so the whole scrollable form (incl. the bottom "Kaydet"
  // button) is laid out and hit-testable in tests.
  Future<void> pump(WidgetTester tester, {Subscription? editing}) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(harness(editing: editing));
    await tester.pumpAndSettle();
  }

  Subscription sub() => Subscription(
        id: 1,
        name: 'Spotify',
        serviceKey: 'spotify',
        amount: 59.99,
        currency: Currency.tryl,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: DateTime(2026, 6, 20),
        category: SubscriptionCategory.music,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  testWidgets('add mode renders title and save button', (tester) async {
    await pump(tester);
    expect(find.text('Abonelik ekle'), findsOneWidget);
    expect(find.text('Kaydet'), findsOneWidget);
  });

  testWidgets('invalid save shows a Turkish validation message, writes nothing',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Servis adı boş olamaz.'), findsOneWidget);
    expect(repo.items, isEmpty);
  });

  testWidgets('edit mode pre-fills fields and shows edit title', (tester) async {
    await pump(tester, editing: sub());
    expect(find.text('Aboneliği düzenle'), findsOneWidget);
    expect(find.text('Spotify'), findsOneWidget); // name field prefilled
  });

  testWidgets('delete shows a confirmation dialog (edit mode)', (tester) async {
    repo.items.add(sub());
    await pump(tester, editing: sub());

    await tester.tap(find.byTooltip('Sil'));
    await tester.pumpAndSettle();

    expect(find.text('Aboneliği sil?'), findsOneWidget);
    expect(find.text('Vazgeç'), findsOneWidget);
  });
}
