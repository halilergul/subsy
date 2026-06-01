# Phase 1 Data Model: Currency Conversion

Two persisted single-row entities (cached rates + target setting), a few derived/transient values, and one pure converter. Per-currency types are reused unchanged.

---

## `ExchangeRates` (domain value, persisted as cache)

| Field | Type | Notes |
|-------|------|-------|
| `base` | `Currency` | the base the rates are relative to (EUR from frankfurter) |
| `ratesPerBase` | `Map<Currency, double>` | units of currency per 1 `base`; **includes `base → 1.0`** |
| `fetchedAt` | `DateTime` | when WE fetched (drives the "last updated" caption) |

Helpers: `bool has(Currency c) => ratesPerBase.containsKey(c)`.

### Persistence: `ExchangeRatesEntity` (Isar `@collection`, id=0)
Single row. Stores `baseCode` (String), `currencyCodes`+`rateValues` (parallel lists, or a small JSON string), `fetchedAt`. `fromDomain`/`toDomain` map via `Currency.fromCode`. Registered in `IsarDatabase` schemas.

---

## `TargetCurrency` (persisted setting)

Just a `Currency` (TRY/USD/EUR), default **TRY**. Constant `kDefaultTargetCurrency = Currency.tryl`.

### Persistence: `TargetCurrencyEntity` (Isar `@collection`, id=0)
Single row storing the ISO `code` (String). `load()` → `Currency.fromCode(code) ?? kDefaultTargetCurrency`.

---

## `UnifiedTotal` (transient value)

| Field | Type | Notes |
|-------|------|-------|
| `amount` | `double` | sum of converted, period-normalized amounts (un-rounded) |
| `target` | `Currency` | currency the total is expressed in |
| `partial` | `bool` | true if any subscription currency was missing from the rates |
| `missing` | `List<Currency>` | the excluded currencies (for the partial note) |

---

## `UnifiedCategoryBreakdown` (transient value, statistics)

Reuses the shapes from `statistics_calculator`: a `target` currency, a `total`, and a `List<CategorySlice>` (category, converted period amount, percentage). Percentages use the same largest-remainder rule (sum to 100).

---

## Pure functions (`currency_converter`)

```dart
/// amount in [from] expressed in [to]; null if either currency is absent.
double? convertAmount(double amount, Currency from, Currency to, ExchangeRates rates);

/// Sum of monthlyAmount(sub) converted to [target]; null only if NOTHING
/// could be converted. Excluded currencies are reported via UnifiedTotal.missing.
UnifiedTotal? unifiedMonthlyTotal(
    List<Subscription> subs, Currency target, ExchangeRates rates);

/// Per-category converted+period-scaled breakdown for the unified view.
UnifiedCategoryBreakdown? unifiedCategoryBreakdown(
    List<Subscription> subs, Currency target, StatPeriod period, ExchangeRates rates);
```

### Rules
1. `convertAmount`: `from == to` → returns `amount` (×1, no drift). Else `amount * rates.ratesPerBase[to]! / rates.ratesPerBase[from]!`; any missing → `null`.
2. `unifiedMonthlyTotal`: for each sub, `c = convertAmount(monthlyAmount(sub), sub.currency, target, rates)`; if `null`, add `sub.currency` to `missing` and skip; else accumulate. `amount` is **summed before any rounding** (FR-005). Return `null` if every subscription was skipped (no usable conversion).
3. `unifiedCategoryBreakdown`: same conversion, grouped by `category`, each multiplied by `period.factor`; total = sum of category amounts; percentages largest-remainder to 100. Empty/all-missing → `null`.
4. Period scaling for the unified total in statistics = multiply the monthly unified amount by `period.factor` (×1/×12) — percentages period-invariant (SC-007).

> No Flutter / http / Isar imports. Deterministic given inputs.

---

## Orchestration & state

```
exchangeRatesProvider  = stream of cached ExchangeRates? (Isar watch)
targetCurrencyProvider = stream of Currency (Isar watch, default TRY)
conversionEnabledProvider = premiumStatusProvider.isPremium

startExchangeRateSync(ref):   // once, in SubsyApp (like startReminderSync)
  result = service.fetchLatest()
  if Success: ratesRepo.save(result)      // stream re-emits
  if Failure: keep existing cache (no-op)  // offline-first

unifiedDashboardTotalProvider = derive(subscriptions, target, rates) -> AsyncValue<UnifiedConversionState>
```

### `UnifiedConversionState` (UI-facing)
| State | Condition | UI |
|-------|-----------|----|
| `locked` | not premium | locked teaser + CTA |
| `unavailable` | premium, no usable rates | Turkish "kurlar alınamadı" note |
| `ready(UnifiedTotal, fetchedAt)` | premium + rates | ≈ total (+ partial note if `partial`) + "last updated" |

---

## Reuse map (unchanged dependencies)

| Reused | From | Used for |
|--------|------|----------|
| `Subscription`, `Currency` | subscriptions-core | inputs |
| `monthlyAmount` | dashboard | per-sub normalization before conversion |
| `currencySummary` | dashboard | per-currency lines (kept as-is, beside the unified line) |
| `StatPeriod`, `CategorySlice`, statistics aggregator shape | statistics | unified period scaling + breakdown |
| `premiumStatusProvider` | subscriptions-core | gating |
| `formatMoney` / `currencySymbol` | shared | display (with "≈ " prefix) |
| single-row Isar pattern | notifications | rates + target persistence |
