import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/currency/domain/exchange_rates.dart';
import 'package:subsy/features/home_widget/domain/widget_payload.dart';
import 'package:subsy/features/home_widget/domain/widget_payload_builder.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Pure payload builder — next payment (SC-001), totals + unified (SC-002),
/// gating/states (SC-004).
void main() {
  final now = DateTime(2026, 6, 1);

  Subscription sub({
    required String name,
    required int daysFromNow,
    double amount = 50,
    Currency currency = Currency.tryl,
    String? serviceKey,
  }) =>
      Subscription(
        name: name,
        serviceKey: serviceKey,
        amount: amount,
        currency: currency,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: now.add(Duration(days: daysFromNow)),
        category: SubscriptionCategory.other,
        createdAt: now,
        updatedAt: now,
      );

  // 1 EUR = 1.10 USD = 45 TRY.
  final rates = ExchangeRates(
    base: Currency.eur,
    ratesPerBase: {Currency.eur: 1.0, Currency.usd: 1.10, Currency.tryl: 45.0},
    fetchedAt: now,
  );

  group('gating & states', () {
    test('free user → locked, no figures (SC-004)', () {
      final p = buildWidgetPayload(
        subs: [sub(name: 'Netflix', daysFromNow: 3)],
        now: now,
        isPremium: false,
        target: Currency.tryl,
        rates: rates,
      );
      expect(p.state, WidgetState.locked);
      expect(p.nextTitle, isEmpty);
      expect(p.totalLine, isEmpty);
      expect(p.unifiedLine, isEmpty);
    });

    test('no subscriptions → empty', () {
      final p = buildWidgetPayload(
        subs: const [],
        now: now,
        isPremium: true,
        target: Currency.tryl,
        rates: rates,
      );
      expect(p.state, WidgetState.empty);
    });
  });

  group('ready — next payment (SC-001)', () {
    test('selects the soonest effective renewal with label + amount', () {
      final p = buildWidgetPayload(
        subs: [
          sub(name: 'Late', daysFromNow: 10, amount: 100),
          sub(name: 'Soon', daysFromNow: 3, amount: 149.99),
        ],
        now: now,
        isPremium: true,
        target: Currency.tryl,
        rates: null,
      );
      expect(p.state, WidgetState.ready);
      expect(p.nextTitle, 'Soon');
      expect(p.nextWhen, '3 gün sonra');
      expect(p.nextAmount, '₺149.99');
    });
  });

  group('ready — totals & unified (SC-002)', () {
    final subs = [
      sub(name: 'A', daysFromNow: 5, amount: 100, currency: Currency.tryl),
      sub(name: 'B', daysFromNow: 8, amount: 1, currency: Currency.eur), // 45 TRY
    ];

    test('totalLine lists per-currency monthly totals', () {
      final p = buildWidgetPayload(
        subs: subs, now: now, isPremium: true, target: Currency.tryl, rates: null,
      );
      expect(p.totalLine, contains('₺100.00'));
      expect(p.totalLine, contains('€1.00'));
      expect(p.totalLine, endsWith('/ ay'));
      expect(p.unifiedLine, isEmpty); // no rates
    });

    test('unifiedLine present only when rates available', () {
      final p = buildWidgetPayload(
        subs: subs, now: now, isPremium: true, target: Currency.tryl, rates: rates,
      );
      // 100 TRY + 1 EUR(=45 TRY) = 145 TRY
      expect(p.unifiedLine, '≈ ₺145.00 / ay');
    });
  });
}
