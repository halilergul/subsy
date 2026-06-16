import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/core/storage/isar_database.dart';
import 'package:subsy/features/subscriptions/data/isar_subscription_repository.dart';
import 'package:subsy/features/subscriptions/domain/brand_resolver.dart';
import 'package:subsy/features/subscriptions/domain/premium_status.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/subscription_repository.dart';
import 'package:subsy/features/subscriptions/domain/usecases/add_subscription.dart';
import 'package:subsy/features/subscriptions/domain/usecases/delete_subscription.dart';
import 'package:subsy/features/subscriptions/domain/usecases/update_subscription.dart';

/// Opens (and owns) the app-wide Isar database. Closed automatically when the
/// provider is disposed. UI/startup must resolve this future before reading
/// [subscriptionRepositoryProvider].
final isarDatabaseProvider = FutureProvider<IsarDatabase>((ref) async {
  final db = await IsarDatabase.open();
  ref.onDispose(db.close);
  return db;
});

/// The subscription storage contract. UI/use cases depend on this, never on
/// the concrete Isar implementation. Requires the Isar database to be open.
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final db = ref.watch(isarDatabaseProvider).requireValue;
  return IsarSubscriptionRepository(db.isar);
});

/// Offline brand catalog resolver (FR-010..014).
final brandResolverProvider = Provider<BrandResolver>(
  (ref) => const BrandResolver(),
);

/// TEMP debug toggle: flips the premium stub at runtime so the premium UI can
/// be tested before the RevenueCat paywall ships. Driven by the Settings switch
/// (gated by `kShowDebugPremiumToggle`). Remove with the paywall feature.
class PremiumOverride extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final premiumOverrideProvider = NotifierProvider<PremiumOverride, bool>(
  PremiumOverride.new,
);

/// Premium status. Stub = free tier (or premium when the debug toggle is on);
/// the `paywall` feature OVERRIDES this provider with a RevenueCat-backed
/// implementation (research.md D6).
final premiumStatusProvider = Provider<PremiumStatus>(
  (ref) => ref.watch(premiumOverrideProvider)
      ? const PremiumActive()
      : const FreePremiumStatus(),
);

/// Create funnel — enforces validation, brand enrichment, and the free limit.
final addSubscriptionProvider = Provider<AddSubscription>((ref) {
  return AddSubscription(
    ref.watch(subscriptionRepositoryProvider),
    ref.watch(premiumStatusProvider),
    ref.watch(brandResolverProvider),
  );
});

final updateSubscriptionProvider = Provider<UpdateSubscription>((ref) {
  return UpdateSubscription(
    ref.watch(subscriptionRepositoryProvider),
    ref.watch(brandResolverProvider),
  );
});

final deleteSubscriptionProvider = Provider<DeleteSubscription>((ref) {
  return DeleteSubscription(ref.watch(subscriptionRepositoryProvider));
});

/// Reactive list of all subscriptions for downstream UI features.
final subscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  return ref.watch(subscriptionRepositoryProvider).watchAll();
});
