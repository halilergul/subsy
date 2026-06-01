import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/currency/domain/currency_converter.dart';
import 'package:subsy/features/currency/domain/exchange_rates.dart';
import 'package:subsy/features/statistics/domain/stat_period.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Pure converter tests — SC-001 (unified total), SC-002 (target==source ×1),
/// SC-006/FR-007 (partial/missing), SC-007 (period ×12 + % invariance).
void main() {
  final t = DateTime(2026, 1, 1);

  // 1 EUR = 1.10 USD = 45.0 TRY (base EUR).
  final rates = ExchangeRates(
    base: Currency.eur,
    ratesPerBase: {Currency.eur: 1.0, Currency.usd: 1.10, Currency.tryl: 45.0},
    fetchedAt: t,
  );

  Subscription sub({
    required double amount,
    required Currency currency,
    BillingPeriod period = BillingPeriod.monthly,
    SubscriptionCategory category = SubscriptionCategory.other,
  }) =>
      Subscription(
        name: 'X',
        amount: amount,
        currency: currency,
        billingPeriod: period,
        nextRenewalDate: t,
        category: category,
        createdAt: t,
        updatedAt: t,
      );

  group('convertAmount', () {
    test('target == source returns amount unchanged (×1, no drift)', () {
      expect(convertAmount(149.99, Currency.tryl, Currency.tryl, rates), 149.99);
    });

    test('cross conversion via base', () {
      // 10 USD -> EUR = 10 * 1.0/1.10
      expect(convertAmount(10, Currency.usd, Currency.eur, rates),
          closeTo(10 * 1.0 / 1.10, 1e-9));
      // 1 EUR -> TRY = 45.0
      expect(convertAmount(1, Currency.eur, Currency.tryl, rates), closeTo(45.0, 1e-9));
    });

    test('missing currency returns null', () {
      final partialRates = ExchangeRates(
        base: Currency.eur,
        ratesPerBase: {Currency.eur: 1.0, Currency.tryl: 45.0},
        fetchedAt: t,
      );
      expect(convertAmount(10, Currency.usd, Currency.tryl, partialRates), isNull);
    });
  });

  group('unifiedMonthlyTotal', () {
    test('sums converted monthly amounts (SC-001)', () {
      final u = unifiedMonthlyTotal([
        sub(amount: 100, currency: Currency.tryl), // 100 TRY
        sub(amount: 1, currency: Currency.eur), //    45 TRY
        sub(amount: 11, currency: Currency.usd), //  11 * 45/1.10 = 450 TRY
      ], Currency.tryl, rates)!;
      expect(u.partial, isFalse);
      expect(u.amount, closeTo(100 + 45 + 450, 1e-6));
      expect(u.target, Currency.tryl);
    });

    test('all-target set equals plain sum, no drift (SC-002)', () {
      final u = unifiedMonthlyTotal([
        sub(amount: 50, currency: Currency.tryl),
        sub(amount: 1200, currency: Currency.tryl, period: BillingPeriod.yearly), // 100/mo
      ], Currency.tryl, rates)!;
      expect(u.amount, closeTo(150, 1e-9));
      expect(u.partial, isFalse);
    });

    test('missing-rate currency excluded + reported partial (FR-007)', () {
      final partialRates = ExchangeRates(
        base: Currency.eur,
        ratesPerBase: {Currency.eur: 1.0, Currency.tryl: 45.0},
        fetchedAt: t,
      );
      final u = unifiedMonthlyTotal([
        sub(amount: 100, currency: Currency.tryl),
        sub(amount: 10, currency: Currency.usd), // no USD rate
      ], Currency.tryl, partialRates)!;
      expect(u.amount, 100);
      expect(u.partial, isTrue);
      expect(u.missing, contains(Currency.usd));
    });

    test('nothing convertible → null (SC-006)', () {
      final onlyEur = ExchangeRates(
        base: Currency.eur,
        ratesPerBase: {Currency.eur: 1.0},
        fetchedAt: t,
      );
      expect(unifiedMonthlyTotal([sub(amount: 10, currency: Currency.usd)],
          Currency.tryl, onlyEur), isNull);
      expect(unifiedMonthlyTotal([], Currency.tryl, rates), isNull);
    });
  });

  group('unifiedCategoryBreakdown', () {
    final subs = [
      sub(amount: 100, currency: Currency.tryl, category: SubscriptionCategory.streaming),
      sub(amount: 1, currency: Currency.eur, category: SubscriptionCategory.music), // 45 TRY
    ];

    test('converts, groups, percentages sum to 100', () {
      final b = unifiedCategoryBreakdown(subs, Currency.tryl, StatPeriod.monthly, rates)!;
      expect(b.total, closeTo(145, 1e-6));
      expect(b.slices.map((s) => s.percentage).reduce((a, c) => a + c), 100);
      // streaming (100) is the largest slice → first.
      expect(b.slices.first.category, SubscriptionCategory.streaming);
    });

    test('yearly scales amounts ×12, percentages unchanged (SC-007)', () {
      final m = unifiedCategoryBreakdown(subs, Currency.tryl, StatPeriod.monthly, rates)!;
      final y = unifiedCategoryBreakdown(subs, Currency.tryl, StatPeriod.yearly, rates)!;
      expect(y.total, closeTo(m.total * 12, 1e-6));
      for (var i = 0; i < m.slices.length; i++) {
        expect(y.slices[i].amount, closeTo(m.slices[i].amount * 12, 1e-6));
        expect(y.slices[i].percentage, m.slices[i].percentage);
      }
    });
  });
}
