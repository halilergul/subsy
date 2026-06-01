import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/currency/domain/currency_constants.dart';
import 'package:subsy/features/currency/domain/exchange_rates.dart';
import 'package:subsy/features/home_widget/application/home_widget_providers.dart';
import 'package:subsy/features/home_widget/domain/home_widget_service.dart';
import 'package:subsy/features/home_widget/domain/widget_payload_builder.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Builds the payload and pushes it to the widget. Thin, directly testable
/// orchestration (mirrors the dashboard/notifications "reschedule" helpers).
Future<void> publishWidget(
  HomeWidgetService service, {
  required List<Subscription> subs,
  required DateTime now,
  required bool isPremium,
  required Currency target,
  ExchangeRates? rates,
}) {
  return service.publish(buildWidgetPayload(
    subs: subs,
    now: now,
    isPremium: isPremium,
    target: target,
    rates: rates,
  ));
}

/// Keeps the home-screen widget in sync. Republishes whenever subscriptions,
/// target currency, rates, or premium status change (FR-005/006/009).
/// Best-effort + guarded so the provider never throws at build (boot-safe).
final homeWidgetSyncProvider = Provider<void>((ref) {
  Future<void> sync() async {
    try {
      final subs = ref.read(subscriptionsProvider).asData?.value;
      if (subs == null) return;
      await publishWidget(
        ref.read(homeWidgetServiceProvider),
        subs: subs,
        now: DateTime.now(),
        isPremium: ref.read(premiumStatusProvider).isPremium,
        target: ref.read(targetCurrencyProvider).asData?.value ?? kDefaultTargetCurrency,
        rates: ref.read(exchangeRatesProvider).asData?.value,
      );
    } catch (_) {
      // Best-effort: leave the last published content in place.
    }
  }

  ref.listen(subscriptionsProvider, (_, _) => sync());
  ref.listen(targetCurrencyProvider, (_, _) => sync());
  ref.listen(exchangeRatesProvider, (_, _) => sync());
  ref.listen(premiumStatusProvider, (_, _) => sync());
  sync();
});

/// Call once at the app root (with the widget ref) to keep the widget current.
void startHomeWidgetSync(WidgetRef ref) => ref.watch(homeWidgetSyncProvider);
