import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/subscription_repository.dart';

/// TEMP dev seed so the app isn't empty while testing on device. Set
/// [kSeedMockData] to false (or delete this file + its call in main) to remove.
const bool kSeedMockData = true;

/// Inserts a handful of demo subscriptions when the store is empty. No-ops if
/// any data already exists, so it never duplicates across launches.
Future<void> seedMockSubscriptions(SubscriptionRepository repo) async {
  if (!kSeedMockData) return;

  final all = await repo.getAll();
  final current = switch (all) {
    Success<List<Subscription>>(:final value) => value,
    Failure<List<Subscription>>() => const <Subscription>[],
  };
  if (current.isNotEmpty) return;

  final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final t = DateTime(2026, 1, 1);

  Subscription s({
    required String name,
    required String key,
    required double amount,
    required Currency currency,
    required BillingPeriod period,
    required int inDays,
    required SubscriptionCategory category,
  }) =>
      Subscription(
        name: name,
        serviceKey: key,
        amount: amount,
        currency: currency,
        billingPeriod: period,
        nextRenewalDate: now.add(Duration(days: inDays)),
        category: category,
        createdAt: t,
        updatedAt: t,
      );

  final demo = <Subscription>[
    s(name: 'Spotify', key: 'spotify', amount: 59.99, currency: Currency.tryl, period: BillingPeriod.monthly, inDays: 2, category: SubscriptionCategory.music),
    s(name: 'Netflix', key: 'netflix', amount: 229.99, currency: Currency.tryl, period: BillingPeriod.monthly, inDays: 3, category: SubscriptionCategory.streaming),
    s(name: 'ChatGPT Plus', key: 'chatgpt', amount: 20, currency: Currency.usd, period: BillingPeriod.monthly, inDays: 6, category: SubscriptionCategory.ai),
    s(name: 'iCloud+', key: 'icloud_plus', amount: 49.99, currency: Currency.tryl, period: BillingPeriod.monthly, inDays: 9, category: SubscriptionCategory.cloud),
    s(name: 'Claude Pro', key: 'claude_pro', amount: 20, currency: Currency.usd, period: BillingPeriod.monthly, inDays: 11, category: SubscriptionCategory.ai),
    s(name: 'YouTube Premium', key: 'youtube_premium', amount: 57.99, currency: Currency.tryl, period: BillingPeriod.monthly, inDays: 14, category: SubscriptionCategory.streaming),
    s(name: 'Xbox Game Pass', key: 'xbox_game_pass', amount: 169, currency: Currency.tryl, period: BillingPeriod.monthly, inDays: 18, category: SubscriptionCategory.gaming),
    s(name: 'Microsoft 365', key: 'microsoft_365', amount: 29.99, currency: Currency.eur, period: BillingPeriod.monthly, inDays: 21, category: SubscriptionCategory.productivity),
    s(name: 'Storytel', key: 'storytel', amount: 99.99, currency: Currency.tryl, period: BillingPeriod.monthly, inDays: 24, category: SubscriptionCategory.books),
    s(name: 'NordVPN', key: 'nordvpn', amount: 59.88, currency: Currency.usd, period: BillingPeriod.yearly, inDays: 27, category: SubscriptionCategory.security),
  ];

  for (final sub in demo) {
    await repo.add(sub);
  }
}
