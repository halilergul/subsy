import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/statistics/domain/stat_period.dart';
import 'package:subsy/features/statistics/domain/statistics_calculator.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Pure aggregator tests — maps SC-001 (totals/%), SC-002 (% sum to 100),
/// SC-003 (×12 scaling, % unchanged), SC-004 (no cross-currency blend), and
/// the ranking rules (US3).
void main() {
  final t = DateTime(2026, 1, 1);

  Subscription sub({
    String name = 'X',
    required double amount,
    Currency currency = Currency.tryl,
    BillingPeriod period = BillingPeriod.monthly,
    required SubscriptionCategory category,
  }) =>
      Subscription(
        name: name,
        amount: amount,
        currency: currency,
        billingPeriod: period,
        nextRenewalDate: t,
        category: category,
        createdAt: t,
        updatedAt: t,
      );

  group('categoryBreakdowns', () {
    test('per-category totals and percentages within a currency (SC-001/002)', () {
      final r = categoryBreakdowns([
        sub(amount: 100, category: SubscriptionCategory.streaming),
        sub(amount: 100, category: SubscriptionCategory.music),
      ], StatPeriod.monthly);

      expect(r.length, 1);
      final tryl = r.single;
      expect(tryl.currency, Currency.tryl);
      expect(tryl.total, 200);
      expect(tryl.slices.map((s) => s.percentage), everyElement(50));
      expect(tryl.slices.map((s) => s.percentage).reduce((a, b) => a + b), 100);
    });

    test('percentages always sum to 100 with remainder absorption (SC-002)', () {
      // 1/3 each → naive rounding gives 33+33+33=99; largest absorbs remainder.
      final r = categoryBreakdowns([
        sub(amount: 100, category: SubscriptionCategory.streaming),
        sub(amount: 100, category: SubscriptionCategory.music),
        sub(amount: 100, category: SubscriptionCategory.cloud),
      ], StatPeriod.monthly);

      final sum = r.single.slices.map((s) => s.percentage).reduce((a, b) => a + b);
      expect(sum, 100);
    });

    test('slices sorted by amount desc; zero categories omitted', () {
      final r = categoryBreakdowns([
        sub(amount: 30, category: SubscriptionCategory.music),
        sub(amount: 90, category: SubscriptionCategory.streaming),
        sub(amount: 60, category: SubscriptionCategory.cloud),
      ], StatPeriod.monthly);

      expect(r.single.slices.map((s) => s.category).toList(), [
        SubscriptionCategory.streaming,
        SubscriptionCategory.cloud,
        SubscriptionCategory.music,
      ]);
      // Only 3 categories present → no empty ones.
      expect(r.single.slices.length, 3);
    });

    test('currencies never blended, ordered TRY→USD→EUR (SC-004)', () {
      final r = categoryBreakdowns([
        sub(amount: 10, currency: Currency.eur, category: SubscriptionCategory.music),
        sub(amount: 20, currency: Currency.tryl, category: SubscriptionCategory.streaming),
        sub(amount: 5, currency: Currency.usd, category: SubscriptionCategory.cloud),
      ], StatPeriod.monthly);

      expect(r.map((b) => b.currency).toList(),
          [Currency.tryl, Currency.usd, Currency.eur]);
      expect(r[0].total, 20);
      expect(r[1].total, 5);
      expect(r[2].total, 10);
    });

    test('mixed billing periods normalized to monthly', () {
      final r = categoryBreakdowns([
        sub(amount: 100, category: SubscriptionCategory.streaming),
        sub(amount: 1200, period: BillingPeriod.yearly, category: SubscriptionCategory.music),
      ], StatPeriod.monthly);
      expect(r.single.total, closeTo(200, 0.0001)); // 100 + 1200/12
    });
  });

  group('period scaling (SC-003)', () {
    final subs = [
      sub(amount: 100, category: SubscriptionCategory.streaming),
      sub(amount: 100, category: SubscriptionCategory.music),
    ];

    test('yearly = monthly × 12 for every amount; percentages unchanged', () {
      final monthly = categoryBreakdowns(subs, StatPeriod.monthly).single;
      final yearly = categoryBreakdowns(subs, StatPeriod.yearly).single;

      expect(yearly.total, monthly.total * 12);
      for (var i = 0; i < monthly.slices.length; i++) {
        expect(yearly.slices[i].amount, monthly.slices[i].amount * 12);
        expect(yearly.slices[i].percentage, monthly.slices[i].percentage);
      }
    });
  });

  group('topSubscriptions (US3)', () {
    test('ranked by period amount desc within a currency', () {
      final r = topSubscriptions([
        sub(name: 'Cheap', amount: 10, category: SubscriptionCategory.other),
        sub(name: 'Pricey', amount: 90, category: SubscriptionCategory.other),
        sub(name: 'Mid', amount: 50, category: SubscriptionCategory.other),
      ], StatPeriod.monthly);

      expect(r[Currency.tryl]!.map((e) => e.subscription.name).toList(),
          ['Pricey', 'Mid', 'Cheap']);
    });

    test('limit keeps only the top N', () {
      final r = topSubscriptions([
        sub(name: 'A', amount: 10, category: SubscriptionCategory.other),
        sub(name: 'B', amount: 20, category: SubscriptionCategory.other),
        sub(name: 'C', amount: 30, category: SubscriptionCategory.other),
      ], StatPeriod.monthly, limit: 2);
      expect(r[Currency.tryl]!.map((e) => e.subscription.name).toList(), ['C', 'B']);
    });

    test('never ranks across currencies', () {
      final r = topSubscriptions([
        sub(name: 'TRY big', amount: 100, currency: Currency.tryl, category: SubscriptionCategory.other),
        sub(name: 'USD small', amount: 5, currency: Currency.usd, category: SubscriptionCategory.other),
      ], StatPeriod.monthly);

      expect(r.keys.toSet(), {Currency.tryl, Currency.usd});
      expect(r[Currency.tryl]!.single.subscription.name, 'TRY big');
      expect(r[Currency.usd]!.single.subscription.name, 'USD small');
    });
  });

  group('buildStatistics', () {
    test('empty input → isEmpty true, empty breakdowns', () {
      final view = buildStatistics([], StatPeriod.monthly);
      expect(view.isEmpty, isTrue);
      expect(view.breakdowns, isEmpty);
      expect(view.topByCurrency, isEmpty);
    });

    test('non-empty → isEmpty false', () {
      final view = buildStatistics(
        [sub(amount: 10, category: SubscriptionCategory.other)],
        StatPeriod.monthly,
      );
      expect(view.isEmpty, isFalse);
      expect(view.period, StatPeriod.monthly);
    });
  });
}
