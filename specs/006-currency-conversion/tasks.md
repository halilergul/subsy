---

description: "Task list for Currency Conversion (Premium) implementation"
---

# Tasks: Currency Conversion (Premium)

**Input**: Design documents from `/specs/006-currency-conversion/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/currency.md, quickstart.md

**Tests**: Included — the spec's Success Criteria (SC-001..008) are numeric/behavioral and require unit coverage of the pure converter, a parse test for the rate service, and widget coverage of the gated/unlocked/no-rates states.

**Organization**: Grouped by user story (P1→P3). The shared conversion engine (values, converter, persistence, service, providers, sync) is Foundational because every story depends on it.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1..US5 (maps to spec.md user stories)
- Exact file paths included.

## Path Conventions

Flutter feature-first: `lib/features/currency/{domain,data,application,presentation}`; network wrapper in `lib/core/exchange/`; tests under `test/unit/` and `test/widget/`. Isar codegen produces `*.g.dart` (gitignored).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Named constants used across the engine (no magic strings/numbers). No new package — `http` is already present.

- [X] T001 [P] Create `lib/features/currency/domain/currency_constants.dart` with named consts: `kFrankfurterLatestUrl` (`https://api.frankfurter.dev/v1/latest`), `kRateBaseCurrency = Currency.eur`, `kRateSymbols` (USD,TRY), and `kDefaultTargetCurrency = Currency.tryl`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The entire non-UI conversion engine — pure converter, persistence, network service, providers, sync. MUST complete before any story's UI.

### Domain values & pure converter

- [X] T002 [P] Create `lib/features/currency/domain/exchange_rates.dart` — `ExchangeRates` value (`base`, `Map<Currency,double> ratesPerBase` incl. `base→1.0`, `fetchedAt`) + `bool has(Currency)`; no Flutter/http/Isar imports
- [X] T003 [P] Create `lib/features/currency/domain/unified_total.dart` — `UnifiedTotal` (amount, target, partial, missing) and `UnifiedCategoryBreakdown` (target, total, `List<CategorySlice>`) value types
- [X] T004 Create `lib/features/currency/domain/currency_converter.dart` — PURE `convertAmount` (from==to → ×1; missing → null), `unifiedMonthlyTotal` (sum-before-round, excluded→`missing`/`partial`, null if none convertible), `unifiedCategoryBreakdown` (convert + group by category + ×`StatPeriod.factor` + largest-remainder %); reuses `monthlyAmount`; no Flutter/http/Isar imports
- [X] T005 [P] Create `test/unit/currency_converter_test.dart` — factor math, target==source ×1 (SC-002), unified total (SC-001), sum-before-round, partial/missing (SC-006/FR-007), period ×12 + % invariance (SC-007)

### Persistence (Isar single-row, mirrors NotificationSettings)

- [X] T006 [P] Create repository interfaces `lib/features/currency/domain/exchange_rates_repository.dart` (`load/save/watch` → `ExchangeRates?`) and `lib/features/currency/domain/target_currency_repository.dart` (`load/save/watch` → `Currency`, default TRY)
- [X] T007 Create Isar entities `lib/features/currency/data/exchange_rates_entity.dart` (id=0: baseCode, currencyCodes+rateValues lists, fetchedAt; `fromDomain`/`toDomain` via `Currency.fromCode`) and `lib/features/currency/data/target_currency_entity.dart` (id=0: code String)
- [X] T008 Register `ExchangeRatesEntitySchema` + `TargetCurrencyEntitySchema` in `lib/core/storage/isar_database.dart`, then run `dart run build_runner build --delete-conflicting-outputs`
- [X] T009 Create `lib/features/currency/data/isar_exchange_rates_repository.dart` and `lib/features/currency/data/isar_target_currency_repository.dart` (single-row `watchObject(0, fireImmediately: true)`)

### Network service (`core/exchange/`)

- [X] T010 [P] Create `lib/core/exchange/exchange_rate_service.dart` — `abstract interface class ExchangeRateService { Future<Result<ExchangeRates>> fetchLatest(); }` (never throws; typed Failure)
- [X] T011 Create `lib/core/exchange/http_exchange_rate_service.dart` — frankfurter `.dev/v1/latest?base=EUR&symbols=USD,TRY` via injected `http.Client`; parse `{amount,base,date,rates}`, **inject `base→1.0`**, `fetchedAt = DateTime.now()`; map errors → `Failure(NetworkError)`
- [X] T012 [P] Create `test/unit/http_exchange_rate_service_test.dart` — `MockClient` returns sample JSON → asserts `ratesPerBase[base]==1.0` + symbols parsed; non-200/garbage → `Failure`

### Application wiring & test fakes

- [X] T013 Create `lib/features/currency/application/currency_providers.dart` — `exchangeRatesProvider` (StreamProvider off rates repo watch), `targetCurrencyProvider` (StreamProvider off target repo watch, default TRY), `conversionEnabledProvider` (`premiumStatusProvider.isPremium`), and the rate/target repository + service providers (derived from `isarDatabaseProvider`; service provider overridden in main)
- [X] T014 Create `lib/features/currency/application/exchange_rate_sync.dart` — `startExchangeRateSync(WidgetRef)`: fire `service.fetchLatest()` once; on Success `ratesRepo.save(...)`, on Failure no-op (cache kept). Wire into `lib/main.dart` (`SubsyApp`, beside `startReminderSync`) + override the service provider with `HttpExchangeRateService(http.Client())`
- [X] T015 [P] Extend `test/support/fakes.dart` — `FakeExchangeRateService` (returns a canned `ExchangeRates`/Failure) + in-memory `ExchangeRatesRepository`/`TargetCurrencyRepository`

**Checkpoint**: Engine compiles & unit-tested; converter green; providers resolvable. No UI yet.

---

## Phase 3: User Story 1 — See one unified spending total (Priority: P1) 🎯 MVP

**Goal**: A premium user sees, under the per-currency dashboard totals, a single ≈ total in the target currency (default TRY) with a "last updated" caption; per-currency view unchanged.

**Independent Test**: Premium + known rates + mixed-currency subs → unified ≈ total equals the hand-calculated converted sum; per-currency lines still present.

- [X] T016 [US1] Add `UnifiedConversionState` (locked / unavailable / ready(UnifiedTotal, fetchedAt)) + `unifiedDashboardTotalProvider` (compose subscriptions + rates + target + `conversionEnabledProvider`) to `lib/features/currency/application/currency_providers.dart`
- [X] T017 [US1] Create `lib/features/currency/presentation/widgets/unified_total_card.dart` — `UnifiedTotalCard` rendering the **ready** state: "Toplam ≈ {formatMoney}" + "Kurlar: {fetchedAt}" caption + partial note when `partial`; dark mode + Turkish
- [X] T018 [US1] Mount `UnifiedTotalCard` under the per-currency rows in `lib/features/dashboard/presentation/widgets/monthly_summary_card.dart` (per-currency content untouched — additive)
- [X] T019 [P] [US1] Create `test/widget/currency_conversion_test.dart` — premium + rates override → ≈ total present alongside per-currency totals (SC-001)

**Checkpoint**: MVP — unified total visible on the dashboard for premium users.

---

## Phase 4: User Story 2 — Choose the target currency (Priority: P2)

**Goal**: A selector (TRY/USD/EUR) re-expresses all unified figures and persists.

**Independent Test**: Change target → unified figure re-expresses immediately; choice survives restart (persisted).

- [X] T020 [US2] Add a target-currency selector (TRY/USD/EUR `SegmentedButton`/dropdown) to `unified_total_card.dart` writing through `targetCurrencyProvider` (→ `TargetCurrencyRepository.save`)
- [X] T021 [P] [US2] Extend `test/widget/currency_conversion_test.dart` — changing the target currency re-expresses the unified total in the new currency (SC-004)

**Checkpoint**: Target currency selectable + persisted on top of US1.

---

## Phase 5: User Story 3 — Unified view in statistics (Priority: P2)

**Goal**: Statistics shows a unified ≈ total + unified category breakdown (donut+legend), period-scaled, beside the per-currency sections.

**Independent Test**: Mixed-currency subs across categories + known rates → unified category amounts = converted, period-scaled sums; % sum to 100; ×12 on yearly.

- [X] T022 [US3] Add `unifiedStatisticsProvider` (compose subscriptions + rates + target + `statPeriodProvider` + gating → `UnifiedConversionState` with `UnifiedCategoryBreakdown`) to `currency_providers.dart`
- [X] T023 [US3] Create `lib/features/currency/presentation/widgets/unified_total_view.dart` — ready state: ≈ total + unified breakdown reusing `CategoryDonut` + `CategoryLegend` (fed the converted `CategorySlice`s)
- [X] T024 [US3] Mount `UnifiedTotalView` in `lib/features/statistics/presentation/statistics_screen.dart` as a "Birleşik" section beside the per-currency sections (per-currency untouched)
- [X] T025 [P] [US3] Extend `test/unit/currency_converter_test.dart` (or widget) — unified category sums + % to 100 + yearly ×12 (SC-007)

**Checkpoint**: Unified statistics view alongside per-currency.

---

## Phase 6: User Story 5 — Premium gating & offline honesty (Priority: P2)

**Goal**: Free users see a locked teaser (never a real number); premium-with-no-rates sees an honest Turkish "unavailable"; per-currency view always intact.

**Independent Test**: Toggle premium/rate availability → teaser for free, working total + freshness for premium, honest unavailable when no rates.

- [X] T026 [US5] Create `lib/features/currency/presentation/widgets/conversion_locked_teaser.dart` — `ConversionLockedTeaser` (lock icon + "Premium ile tüm aboneliklerini tek para biriminde gör" + CTA)
- [X] T027 [US5] Render the **locked** (free) and **unavailable** (premium, no usable rates) branches in `unified_total_card.dart` and `unified_total_view.dart` — locked → `ConversionLockedTeaser`, unavailable → Turkish note; never a real number when free (FR-014/015/016)
- [X] T028 [P] [US5] Extend `test/widget/currency_conversion_test.dart` — free user → teaser shown, no converted number (SC-005)
- [X] T029 [P] [US5] Extend `test/widget/currency_conversion_test.dart` — premium + null rates → "unavailable" note, per-currency totals still present (SC-006)

**Checkpoint**: Gating + offline honesty across dashboard and statistics.

---

## Phase 7: User Story 4 — Live converted preview in the form (Priority: P3)

**Goal**: While entering a non-target-currency amount (premium), an inline ≈ preview updates live; hidden when equal/no-rates/free.

**Independent Test**: Enter non-target amount + rates → ≈ preview updates; equal currency or no rates → hidden.

- [X] T030 [US4] Create `lib/features/currency/presentation/widgets/converted_amount_preview.dart` — `ConvertedAmountPreview` watching amount/currency + rates + target + gating; shows "≈ {formatMoney}" only when premium, rates exist, and chosen currency ≠ target
- [X] T031 [US4] Mount `ConvertedAmountPreview` under the amount field in `lib/features/subscriptions/presentation/subscription_form_screen.dart`
- [X] T032 [P] [US4] Extend `test/widget/currency_conversion_test.dart` — non-target → preview shown; equal currency → hidden; free → hidden (FR-013)

**Checkpoint**: All user stories complete.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T033 [P] Run `flutter analyze` and resolve warnings in new files
- [X] T034 [P] Run `flutter test` (new converter/service/widget tests + full suite green; no regression in dashboard/statistics/form)
- [ ] T035 Manual device/simulator check per quickstart.md (premium unified total; toggle target; offline → cached rates + "last updated"; free → teaser) — defer if no device available and note it

---

## Dependencies & Execution Order

- **Setup (T001)** → blocks the converter/service that reference the consts.
- **Foundational (T002–T015)**: T002/T003 → T004 → T005; T006 → T007 → T008 (codegen) → T009; T010 → T011 → T012; T013 needs T006/T009; T014 needs T010/T013; T015 needs T006/T010. All foundational before any story UI.
- **US1 (T016–T019)**: T016 (provider/state) → T017 (card) → T018 (mount) → T019 (test).
- **US2 (T020–T021)**: needs the US1 card + `targetCurrencyProvider`.
- **US3 (T022–T025)**: T022 → T023 → T024; reuses statistics donut/legend.
- **US5 (T026–T029)**: T027 edits the US1 card (T017) **and** US3 view (T023) → US5 runs after US1 + US3.
- **US4 (T030–T032)**: needs the engine + form; independent of US3/US5.
- **Polish (T033–T035)**: after all implementation.

## Parallel Opportunities

- Foundational: **T002 ∥ T003**; **T005 / T010 / T012 / T015** test/interface files are [P]; T006 ∥ (T002/T003).
- Per story, the test task is [P]: **T019, T021, T025, T028, T029, T032**.
- Polish: **T033 ∥ T034**.
- Note: T017 (card) and T023 (view) are edited again by T027 (US5) — sequence those, don't parallelize across stories.

## Implementation Strategy

**MVP = Foundational + User Story 1** (T001–T019): the conversion engine + the dashboard unified ≈ total for premium users — the feature's core value, shippable on its own (default TRY, premium-assumed). Then layer US2 (target selector), US3 (statistics unified view), US5 (gating + offline honesty across surfaces), and US4 (form preview) as incremental, independently verifiable additions. The pure `currency_converter` is unit-tested to the spec's numeric criteria before the UI consumes it; the per-currency `currencySummary`/`statistics_calculator` outputs are reused unchanged (conversion is purely additive).
