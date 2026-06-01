import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/home_widget/application/home_widget_sync.dart';
import 'package:subsy/features/home_widget/domain/widget_payload.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

import '../support/fakes.dart';

/// Orchestration: publishWidget builds the right payload and pushes it to the
/// service (maps SC-003 — a changed input republishes a matching payload).
void main() {
  final now = DateTime(2026, 6, 1);

  Subscription sub(String name) => Subscription(
        name: name,
        amount: 100,
        currency: Currency.tryl,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: now.add(const Duration(days: 4)),
        category: SubscriptionCategory.other,
        createdAt: now,
        updatedAt: now,
      );

  test('premium + subscriptions → publishes a ready payload', () async {
    final fake = FakeHomeWidgetService();
    await publishWidget(fake,
        subs: [sub('Netflix')],
        now: now,
        isPremium: true,
        target: Currency.tryl,
        rates: null);
    expect(fake.lastPayload?.state, WidgetState.ready);
    expect(fake.lastPayload?.nextTitle, 'Netflix');
  });

  test('republishing reflects a changed subscription set', () async {
    final fake = FakeHomeWidgetService();
    await publishWidget(fake,
        subs: [sub('Netflix')], now: now, isPremium: true, target: Currency.tryl);
    await publishWidget(fake,
        subs: const [], now: now, isPremium: true, target: Currency.tryl);
    expect(fake.lastPayload?.state, WidgetState.empty);
    expect(fake.publishCount, 2);
  });

  test('free user → locked payload published', () async {
    final fake = FakeHomeWidgetService();
    await publishWidget(fake,
        subs: [sub('Netflix')], now: now, isPremium: false, target: Currency.tryl);
    expect(fake.lastPayload?.state, WidgetState.locked);
  });
}
