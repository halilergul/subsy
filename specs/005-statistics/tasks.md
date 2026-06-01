---

description: "Task list for Spending Statistics implementation"
---

# Tasks: Spending Statistics

**Input**: Design documents from `/specs/005-statistics/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/statistics.md, quickstart.md

**Tests**: Included — the spec's Success Criteria (SC-001..SC-006) are numeric/behavioral and require unit + widget coverage of the pure aggregator and the screen states.

**Organization**: Tasks are grouped by user story (P1→P3) so each story is an independently testable increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story the task belongs to (US1..US4)
- Exact file paths are included.

## Path Conventions

Flutter feature-first layout: `lib/features/statistics/{domain,application,presentation}`, shared additions in `lib/shared/`, tests under `test/unit/` and `test/widget/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the one new dependency and the shared category style map that every story relies on.

- [X] T001 Add `fl_chart` dependency: run `flutter pub add fl_chart` then `flutter pub get` (updates `pubspec.yaml` / `pubspec.lock`)
- [X] T002 [P] Create `lib/shared/constants/category_style.dart` with `Color categoryColor(SubscriptionCategory c)` + `String categoryLabel(SubscriptionCategory c)` (Turkish) for all categories (streaming, music, cloud, AI, productivity, shopping, other) using the named-const color table from research.md — no magic numbers

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain value types that the pure aggregator and all stories depend on. No story can proceed until these compile.

- [X] T003 [P] Create `lib/features/statistics/domain/stat_period.dart` — `enum StatPeriod { monthly, yearly }` with a `factor` getter (monthly→1, yearly→12) as a named const, no Flutter imports
- [X] T004 [P] Create `lib/features/statistics/domain/category_breakdown.dart` — immutable value types `CategorySlice` (category, amount, percentage) and `CategoryBreakdown` (currency, total, slices), no Flutter imports
- [X] T005 [P] Create `lib/features/statistics/domain/ranked_subscription.dart` — immutable value type `RankedSubscription` (subscription, amount), no Flutter imports

**Checkpoint**: Domain value types compile; aggregator can be written against them.

---

## Phase 3: User Story 1 — See spending broken down by category (Priority: P1) 🎯 MVP

**Goal**: Per currency, compute each category's period-normalized total and its percentage share (summing to 100%), render a donut chart + legend list with matching stable colors. No cross-currency blending; empty categories omitted.

**Independent Test**: Seed subscriptions across categories/currencies (monthly period) → verify per-currency totals, each category percentage, slices sorted desc, percentages sum to 100, no currency mixing; screen renders donut + legend.

### Tests for User Story 1

- [X] T006 [P] [US1] Create `test/unit/statistics_calculator_test.dart` covering `categoryBreakdowns`: per-currency category totals (SC-001), percentages sum to 100 with largest-slice remainder absorption (SC-002), slices sorted by amount desc, zero categories omitted, and no cross-currency blending (SC-004) — uses a fake/builder for `Subscription`

### Implementation for User Story 1

- [X] T007 [US1] Create `lib/features/statistics/domain/statistics_calculator.dart` with `periodAmount` (= `monthlyAmount(s) * p.factor`) and `categoryBreakdowns` per the data-model rules (group by currency, sum per category, drop zero, total, percentage with largest-slice remainder, sort desc, currency order TRY→USD→EUR) — pure, reuses `monthlyAmount`, no Flutter imports
- [X] T008 [US1] Add `buildStatistics(List<Subscription>, StatPeriod) → StatisticsView` to `statistics_calculator.dart` and create `StatisticsView` (period, breakdowns, topByCurrency, isEmpty) — empty input → `isEmpty == true`
- [X] T009 [US1] Create `lib/features/statistics/application/statistics_providers.dart` with `statPeriodProvider` (StateProvider<StatPeriod> default monthly) and `statisticsProvider` (Provider<AsyncValue<StatisticsView>> deriving from `subscriptionsProvider.whenData` + period) per contracts §3
- [X] T010 [P] [US1] Create `lib/features/statistics/presentation/widgets/category_donut.dart` — `CategoryDonut({required CategoryBreakdown breakdown})` fl_chart `PieChart` (donut, centerSpaceRadius) using `categoryColor`; "dumb" renderer fed by tested data
- [X] T011 [P] [US1] Create `lib/features/statistics/presentation/widgets/category_legend.dart` — `CategoryLegend({required CategoryBreakdown breakdown})` list rows: color dot (`categoryColor`) + Turkish label (`categoryLabel`) + `formatMoney(amount, currency)` + percentage
- [X] T012 [US1] Create `lib/features/statistics/presentation/statistics_screen.dart` — `ConsumerWidget` watching `statisticsProvider`; renders loading/error(Turkish)/empty/data; for data, one section per currency with the per-currency total + `CategoryDonut` + `CategoryLegend`; dark mode + Turkish AppBar title ("İstatistikler")
- [X] T013 [US1] Add `Routes.statistics = '/statistics'` + GoRoute in `lib/app/router/app_router.dart`, and add an insights `IconButton` to the dashboard AppBar in `lib/features/dashboard/presentation/dashboard_screen.dart` navigating to it (FR-013)
- [X] T014 [P] [US1] Create `test/widget/statistics_screen_test.dart` — via `ProviderScope` override of `subscriptionsProvider`: non-empty list → donut + legend present; (empty-state assertion completed in US4)

**Checkpoint**: US1 delivers the core value — category breakdown chart + list, per currency, reachable from the dashboard. Independently demoable.

---

## Phase 4: User Story 2 — Switch between monthly and yearly (Priority: P2)

**Goal**: A monthly/yearly toggle re-derives every total/amount (yearly = monthly × 12); percentages unchanged; period clearly labeled.

**Independent Test**: With a fixed set, toggle monthly↔yearly → every amount ×12, percentages identical, label updates.

### Tests for User Story 2

- [X] T015 [P] [US2] Extend `test/unit/statistics_calculator_test.dart` — yearly view scales every total/category amount by exactly 12 (SC-003) and leaves percentages unchanged vs monthly

### Implementation for User Story 2

- [X] T016 [US2] Add an aylık/yıllık `SegmentedButton` (bound to `statPeriodProvider`) to `lib/features/statistics/presentation/statistics_screen.dart`, with the selected period clearly labeled and currency totals reflecting it (FR-006/007)

**Checkpoint**: Period toggle works end-to-end on top of US1; figures scale, shares stable.

---

## Phase 5: User Story 3 — See the heaviest subscriptions (Priority: P3)

**Goal**: A ranked list of the most expensive subscriptions for the period (descending by normalized amount), brand-colored, per currency (never cross-currency).

**Independent Test**: Seed differing amounts → ranked descending within currency; mixed currencies not compared.

### Tests for User Story 3

- [X] T017 [P] [US3] Extend `test/unit/statistics_calculator_test.dart` — `topSubscriptions` orders by `periodAmount` desc within a currency, respects optional `limit`, and never ranks across currencies (FR-009)

### Implementation for User Story 3

- [X] T018 [US3] Add `topSubscriptions(List<Subscription>, StatPeriod, {int? limit}) → Map<Currency, List<RankedSubscription>>` to `statistics_calculator.dart` and wire it into `buildStatistics` (`topByCurrency`)
- [X] T019 [P] [US3] Create `lib/features/statistics/presentation/widgets/top_subscriptions.dart` — `TopSubscriptions({required List<RankedSubscription> items})` ranked list reusing `BrandAvatar` + `formatMoney`
- [X] T020 [US3] Render `TopSubscriptions` under each currency section in `statistics_screen.dart` (per-currency `topByCurrency`)

**Checkpoint**: All three insight surfaces (breakdown, period, top list) present.

---

## Phase 6: User Story 4 — Empty state (Priority: P3)

**Goal**: With no subscriptions, a friendly Turkish empty state instead of blank charts.

**Independent Test**: Open statistics with zero subscriptions → empty state, no chart.

### Tests for User Story 4

- [X] T021 [P] [US4] Extend `test/widget/statistics_screen_test.dart` — empty subscription list → empty-state message shown, no `CategoryDonut`/percentages rendered (SC-006)

### Implementation for User Story 4

- [X] T022 [US4] Add the empty-state branch (`StatisticsView.isEmpty`) to `statistics_screen.dart` — Turkish message, no chart (FR-011)

**Checkpoint**: All user stories complete and independently verifiable.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T023 [P] Run `flutter analyze` and resolve any warnings in new files
- [X] T024 [P] Run `flutter test test/unit/statistics_calculator_test.dart test/widget/statistics_screen_test.dart` and confirm green
- [ ] T025 Manual device/simulator check per quickstart.md (dashboard → statistics; toggle monthly/yearly; mixed currencies; empty state) — defer if no device available and note it

---

## Dependencies & Execution Order

- **Setup (T001–T002)**: T001 (fl_chart) blocks the donut widget (T010); T002 (category_style) blocks legend (T011) + donut (T010).
- **Foundational (T003–T005)**: block the aggregator (T007) and providers/widgets. Must complete first.
- **US1 (T006–T014)**: the MVP. T007→T008→T009 sequential (same file / dependency chain); T010/T011 parallel after T002/T003/T004; T012 needs T009/T010/T011; T013 after T012.
- **US2 (T015–T016)**: depends on US1 screen + providers. No aggregator change (period is already a param).
- **US3 (T017–T020)**: T018 extends the aggregator; T019 parallel; T020 needs T018/T019 + the screen.
- **US4 (T021–T022)**: depends on the US1 screen.
- **Polish (T023–T025)**: after all implementation.

User stories are independently testable; US2/US3/US4 each layer onto the US1 screen without breaking it.

## Parallel Opportunities

- Setup: T002 ∥ (after) — alongside other foundational files.
- Foundational: **T003 ∥ T004 ∥ T005** (separate files, no deps).
- US1: **T010 ∥ T011** (donut/legend widgets); **T006 ∥ T014** (test files) authored alongside.
- Cross-story tests T015 / T017 / T021 are [P] (distinct assertions/files).
- Polish: **T023 ∥ T024**.

## Implementation Strategy

**MVP = User Story 1** (T001–T014): the category breakdown chart + legend, per currency, reachable from the dashboard — the feature's core value, fully shippable on its own. Layer US2 (period toggle), then US3 (top list), then US4 (empty state) as incremental, independently verifiable additions. The pure `statistics_calculator` is unit-tested to the spec's numeric Success Criteria before/as the UI consumes it.
