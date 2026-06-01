import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';

/// Opportunistic, best-effort rate refresh. Fires once when watched: waits for
/// the database, fetches the latest rates and, on success, writes them to the
/// cache (the cache stream then re-emits). Any failure — offline, fetch error,
/// or an unconfigured environment (e.g. tests) — is swallowed; the existing
/// cache keeps serving (cache-first; CONSTITUTION §Hata yönetimi). No background
/// sync. Reads happen inside the guarded async body so the provider never throws
/// at build time.
final exchangeRateSyncProvider = Provider<void>((ref) {
  Future<void> refresh() async {
    try {
      await ref.read(isarDatabaseProvider.future); // ensure DB is open
      final service = ref.read(exchangeRateServiceProvider);
      final repo = ref.read(exchangeRatesRepositoryProvider);
      final result = await service.fetchLatest();
      switch (result) {
        case Success(:final value):
          await repo.save(value);
        case Failure():
          break; // keep cached rates
      }
    } catch (_) {
      // Best-effort: offline / unconfigured → keep whatever cache exists.
    }
  }

  refresh();
});

/// Call once at the app root (with the widget ref) to trigger a rate refresh
/// for this app session.
void startExchangeRateSync(WidgetRef ref) => ref.watch(exchangeRateSyncProvider);
