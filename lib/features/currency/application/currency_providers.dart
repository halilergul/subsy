import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/core/exchange/exchange_rate_service.dart';
import 'package:subsy/features/currency/data/isar_exchange_rates_repository.dart';
import 'package:subsy/features/currency/data/isar_target_currency_repository.dart';
import 'package:subsy/features/currency/domain/currency_constants.dart';
import 'package:subsy/features/currency/domain/currency_converter.dart';
import 'package:subsy/features/currency/domain/exchange_rates.dart';
import 'package:subsy/features/currency/domain/exchange_rates_repository.dart';
import 'package:subsy/features/currency/domain/target_currency_repository.dart';
import 'package:subsy/features/currency/domain/unified_total.dart';
import 'package:subsy/features/statistics/application/statistics_providers.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

// --- Infrastructure providers -------------------------------------------------

final exchangeRatesRepositoryProvider = Provider<ExchangeRatesRepository>((ref) {
  final db = ref.watch(isarDatabaseProvider).requireValue;
  return IsarExchangeRatesRepository(db.isar);
});

final targetCurrencyRepositoryProvider = Provider<TargetCurrencyRepository>((ref) {
  final db = ref.watch(isarDatabaseProvider).requireValue;
  return IsarTargetCurrencyRepository(db.isar);
});

/// The network rate fetcher. Overridden in `main()` with an http-backed impl
/// (it needs a real `http.Client`).
final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  throw UnimplementedError('exchangeRateServiceProvider must be overridden in main()');
});

// --- Reactive state providers -------------------------------------------------

/// Cached rates (null until first fetch). Cache-first — always served from Isar.
final exchangeRatesProvider = StreamProvider<ExchangeRates?>((ref) {
  return ref.watch(exchangeRatesRepositoryProvider).watch();
});

/// Chosen target currency (default TRY).
final targetCurrencyProvider = StreamProvider<Currency>((ref) {
  return ref.watch(targetCurrencyRepositoryProvider).watch();
});

/// Conversion is premium-only (FR-014). Reuses the existing premium seam.
final conversionEnabledProvider = Provider<bool>((ref) {
  return ref.watch(premiumStatusProvider).isPremium;
});

// --- Derived, UI-facing states ------------------------------------------------

/// Dashboard unified total as a gated state (locked / unavailable / ready).
final unifiedDashboardTotalProvider = Provider<UnifiedConversionState>((ref) {
  if (!ref.watch(conversionEnabledProvider)) return const UnifiedLocked();

  final subs = ref.watch(subscriptionsProvider).asData?.value;
  final target = ref.watch(targetCurrencyProvider).asData?.value ?? kDefaultTargetCurrency;
  final ratesAsync = ref.watch(exchangeRatesProvider);
  if (subs == null || ratesAsync.isLoading) return const UnifiedLoading();

  final rates = ratesAsync.asData?.value;
  if (rates == null) return const UnifiedUnavailable();

  final total = unifiedMonthlyTotal(subs, target, rates);
  if (total == null) return const UnifiedUnavailable();
  return UnifiedReady(total, rates.fetchedAt);
});

/// Statistics unified breakdown, scaled by the current period; same gating.
final unifiedStatisticsProvider = Provider<UnifiedStatsState>((ref) {
  if (!ref.watch(conversionEnabledProvider)) return const UnifiedStatsLocked();

  final subs = ref.watch(subscriptionsProvider).asData?.value;
  final target = ref.watch(targetCurrencyProvider).asData?.value ?? kDefaultTargetCurrency;
  final period = ref.watch(statPeriodProvider);
  final ratesAsync = ref.watch(exchangeRatesProvider);
  if (subs == null || ratesAsync.isLoading) return const UnifiedStatsLoading();

  final rates = ratesAsync.asData?.value;
  if (rates == null) return const UnifiedStatsUnavailable();

  final breakdown = unifiedCategoryBreakdown(subs, target, period, rates);
  if (breakdown == null) return const UnifiedStatsUnavailable();
  return UnifiedStatsReady(breakdown, rates.fetchedAt);
});
