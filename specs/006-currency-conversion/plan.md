# Implementation Plan: Currency Conversion (Premium)

**Branch**: `006-currency-conversion` | **Date**: 2026-06-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-currency-conversion/spec.md`

## Summary

Add a **premium, optional** unified spending total: every subscription's period-normalized amount is converted to one user-chosen target currency (default TRY) and shown as a single approximate figure **alongside** the unchanged per-currency groups, on the dashboard, in statistics (total + unified category breakdown), and as a live preview in the add/edit form. Exchange rates are the only network traffic — fetched from a free public source (frankfurter.app, keyless ECB) when online, **cached on-device** (Isar), and reused offline with a "last updated" indicator. The conversion math is a pure, fully-unit-tested function layer; the network and cache sit behind interfaces (faked in tests); the existing per-currency logic is untouched.

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (stable)

**Primary Dependencies**: `flutter_riverpod`, `isar_community` (cache + setting persistence), `http` (already in pubspec — frankfurter fetch). Reuses `monthlyAmount`, `subscriptionsProvider`, `currencySummary`, `statistics_calculator`, `premiumStatusProvider`, `formatMoney`/`currencySymbol`. **No new package.**

**Storage**: Isar — two single-row collections: cached `ExchangeRatesEntity` and the `TargetCurrencyEntity` setting. (Rates are the only network-sourced data; no personal data.)

**Testing**: `flutter_test` — pure unit tests for `currency_converter` (conversion factor, unified total incl. target==source factor 1.0, sum-before-round, partial total on missing rate, period scaling); a parsing unit test for the frankfurter response via an injected `http.Client` (mock); widget tests for premium-gated vs unlocked vs no-rates states. Network and Isar are behind interfaces → faked.

**Target Platform**: iOS 13+ / Android, offline-first, dark mode, Turkish UI.

**Performance Goals**: O(n) conversion over a personal-scale set; rates fetched at most opportunistically (app open/online), never blocking the UI; per-currency view always renders regardless of rate state.

**Constraints**: Conversion among TRY/USD/EUR only; approximate (≈), display-rounded, sum-before-round; cache-first offline; premium-gated; never mutates per-currency figures; no scheduled background sync.

**Scale/Scope**: One service (frankfurter wrapper) + cache repo + target-currency repo + pure converter + derived providers + a few widgets (unified total card/line, locked teaser, form preview, target selector) + tests.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Business logic separated from UI | ✅ | Pure `currency_converter`; widgets only render |
| Reuse over duplication | ✅ | Reuses `monthlyAmount`, `subscriptionsProvider`, `currencySummary`, `statistics_calculator`, `premiumStatusProvider`, `formatMoney` |
| Data via provider; API only in `core/` service layer | ✅ | `ExchangeRateService` lives in `core/exchange/`; UI reads providers only (CONSTITUTION §"API/servis çağrıları sadece core") |
| Every feature tested; critical path mandatory | ✅ | Converter unit-tested to the spec's numeric criteria; service parsing tested with mock client |
| No magic numbers | ✅ | Base currency, default target, frankfurter URL as named consts |
| Typed error handling, Turkish messages | ✅ | `Result<T>`/`AppError`; offline → cache; no cache → Turkish "unavailable" |
| Offline / no backend | ✅ | **Pre-approved exception**: CONSTITUTION §Güvenlik ("ağ trafiği yalnızca opsiyonel döviz kuru çekme, anonim") + §Hata yönetimi ("Döviz API çevrimdışı/başarısızsa son cache") + Decisions row frankfurter.app. No server we run; only public rates fetched; all user data stays on-device |
| Dark mode / Turkish UI | ✅ | Mandatory |
| English code / Turkish UI | ✅ | Code English; labels Turkish |
| Premium gating | ✅ | Reuses existing `premiumStatusProvider` seam (paywall feature overrides it later) |

**Initial gate: PASS.** The network access is an explicitly pre-approved constitution exception, not a violation → Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/006-currency-conversion/
├── plan.md · research.md · data-model.md · quickstart.md
├── contracts/currency.md
├── checklists/requirements.md
└── tasks.md  (later)
```

### Source Code (repository root)

```text
lib/core/exchange/
├── exchange_rate_service.dart          # interface: Future<Result<ExchangeRates>> fetchLatest()
└── http_exchange_rate_service.dart     # frankfurter.app impl (http.Client injected)

lib/features/currency/
├── domain/
│   ├── exchange_rates.dart             # value: base, Map<Currency,double> ratesPerBase, fetchedAt
│   ├── currency_converter.dart         # PURE: convertAmount, unifiedMonthlyTotal, unifiedCategoryBreakdown
│   ├── unified_total.dart              # value: amount, target, partial, missing[]
│   ├── exchange_rates_repository.dart   # cache contract (load/save/watch)
│   └── target_currency_repository.dart  # setting contract (load/save/watch)
├── data/
│   ├── exchange_rates_entity.dart       # Isar single-row (id=0): base, rates, fetchedAt
│   ├── isar_exchange_rates_repository.dart
│   ├── target_currency_entity.dart      # Isar single-row (id=0): currency code
│   └── isar_target_currency_repository.dart
├── application/
│   ├── currency_providers.dart          # targetCurrency / exchangeRates / conversionEnabled / unifiedTotal providers
│   └── exchange_rate_sync.dart          # opportunistic refresh (startExchangeRateSync, like reminder sync)
└── presentation/
    └── widgets/
        ├── unified_total_card.dart      # dashboard: ≈ total + target selector + "last updated"
        ├── unified_total_view.dart      # statistics: ≈ total + unified category breakdown
        ├── conversion_locked_teaser.dart # free users: upsell in place of the total
        └── converted_amount_preview.dart # form: live ≈ preview

lib/core/storage/isar_database.dart      # register ExchangeRatesEntitySchema + TargetCurrencyEntitySchema
lib/main.dart                            # startExchangeRateSync(ref) after startup (opportunistic fetch)
lib/features/dashboard/presentation/widgets/monthly_summary_card.dart      # host the unified line/teaser under per-currency totals
lib/features/statistics/presentation/statistics_screen.dart                # mount unified view alongside per-currency sections
lib/features/subscriptions/presentation/subscription_form_screen.dart      # mount converted preview

test/unit/
├── currency_converter_test.dart         # factors, unified total, target==source, partial, period scaling
└── http_exchange_rate_service_test.dart # frankfurter JSON parse via MockClient
test/widget/
└── currency_conversion_test.dart        # gated vs unlocked vs no-rates states
test/support/fakes.dart                  # add FakeExchangeRateService + in-memory rate/target repos
```

**Structure Decision**: A new `lib/features/currency/` with the established domain/data/application/presentation split, plus the network wrapper in `lib/core/exchange/` per the constitution's rule that API calls live only in the `core/` service layer. The single piece of logic — `currency_converter` — is pure (no Flutter/http/Isar imports) and unit-tested to the spec's numeric criteria. Rates and the target setting persist as single-row Isar collections mirroring the proven `NotificationSettings` pattern. Derived providers compose `subscriptionsProvider` + `exchangeRatesProvider` + `targetCurrencyProvider` + `premiumStatusProvider` into gated `AsyncValue` outputs the UI renders. The per-currency `currencySummary`/`statistics_calculator` outputs are reused **unchanged** — conversion is purely additive.

## Complexity Tracking

> No constitution violations (network is a pre-approved exception). Section intentionally empty.
