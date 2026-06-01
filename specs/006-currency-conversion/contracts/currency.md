# Contracts: Currency Conversion

---

## 1. Consumed (existing)

```dart
final subscriptionsProvider;              // StreamProvider<List<Subscription>> (core)
final premiumStatusProvider;              // Provider<PremiumStatus> (seam; paywall overrides)
double monthlyAmount(Subscription s);     // dashboard domain
List<CurrencyTotal> currencySummary(...); // dashboard domain (kept as-is)
String formatMoney(double, Currency);     // shared util
enum StatPeriod { monthly, yearly }       // statistics domain (.factor)
class IsarDatabase ...                     // single Isar instance owner
```

---

## 2. Network service (this feature, `core/exchange/`)

```dart
abstract interface class ExchangeRateService {
  /// Fetches latest rates. Anonymous, public data only. Never throws —
  /// returns a typed Failure on network/parse errors.
  Future<Result<ExchangeRates>> fetchLatest();
}

class HttpExchangeRateService implements ExchangeRateService {
  HttpExchangeRateService(this._client, {this.base = Currency.eur});
  // GET https://api.frankfurter.dev/v1/latest?base=EUR&symbols=USD,TRY
  // parse {amount, base, date, rates}; inject base->1.0; fetchedAt = now.
}
```

**Contract**
- No personal/subscription data in the request (FR-002/SC-008).
- Missing/garbage response → `Failure(NetworkError)`; caller keeps cache.
- `ExchangeRates.ratesPerBase` always contains `base → 1.0` plus each requested symbol present in the response.

---

## 3. Pure converter (this feature)

```dart
double? convertAmount(double amount, Currency from, Currency to, ExchangeRates rates);
UnifiedTotal? unifiedMonthlyTotal(List<Subscription> subs, Currency target, ExchangeRates rates);
UnifiedCategoryBreakdown? unifiedCategoryBreakdown(
    List<Subscription> subs, Currency target, StatPeriod period, ExchangeRates rates);
```

**Contract**
- `from == to` → returns `amount` exactly (×1, FR-004/SC-002).
- Missing currency → excluded; reported via `UnifiedTotal.missing`, `partial = true` (FR-007).
- Sum performed before rounding (FR-005).
- Yearly = monthly × 12; percentages period-invariant (SC-007).
- No Flutter/http/Isar imports; deterministic.

---

## 4. Persistence (this feature)

```dart
abstract interface class ExchangeRatesRepository {   // Isar single-row, id=0
  Future<ExchangeRates?> load();
  Future<void> save(ExchangeRates rates);
  Stream<ExchangeRates?> watch();
}
abstract interface class TargetCurrencyRepository {  // Isar single-row, id=0
  Future<Currency> load();          // default TRY
  Future<void> save(Currency c);
  Stream<Currency> watch();
}
```

---

## 5. Application wiring

```dart
final exchangeRatesProvider   = StreamProvider<ExchangeRates?>(...);   // cache watch
final targetCurrencyProvider  = StreamProvider<Currency>(...);         // setting watch (default TRY)
final conversionEnabledProvider = Provider<bool>((ref) =>
    ref.watch(premiumStatusProvider).isPremium);

/// Dashboard unified total as a UI-facing state (locked / unavailable / ready).
final unifiedDashboardTotalProvider = Provider<AsyncValue<UnifiedConversionState>>(...);
/// Statistics unified breakdown (same gating), scaled by statPeriodProvider.
final unifiedStatisticsProvider = Provider<AsyncValue<UnifiedConversionState>>(...);

void startExchangeRateSync(WidgetRef ref);  // opportunistic fetch+save in SubsyApp
```
- Recompute on subscription / rates / target / premium / period change (FR-010/017, SC-004).
- Fetch failure is silent; cache continues to serve (FR-003).

---

## 6. UI + integration

```dart
class UnifiedTotalCard extends ConsumerWidget { ... }       // dashboard (hosts target selector + "last updated")
class UnifiedTotalView extends ConsumerWidget { ... }       // statistics section
class ConversionLockedTeaser extends StatelessWidget { ... }// free-user upsell slot
class ConvertedAmountPreview extends ConsumerWidget { ... } // form inline ≈ preview
```

**UI contract**
- Per-currency widgets render unconditionally and unchanged (FR-018).
- Premium → real figures with "≈" + "last updated" (+ partial note); free → `ConversionLockedTeaser`; premium+no-rates → Turkish "unavailable" note (FR-014/015/016).
- Target selector (TRY/USD/EUR) writes `targetCurrencyProvider`; everything re-expresses (FR-010).
- Form preview hidden when chosen currency == target or no rates (FR-013).
- Dark mode + Turkish (FR-017).
```
