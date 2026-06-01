---
description: "Task list for Dashboard (Home Screen)"
---

# Tasks: Dashboard (Home Screen)

**Input**: Design documents from `/specs/002-dashboard/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/dashboard_providers.md, quickstart.md

**Tests**: INCLUDED — the pure view-calculators are the critical path mapped to Success Criteria; unit tests for them are mandatory, widget tests cover the render states.

**Organization**: Grouped by user story (US1 list / US2 summary / US3 empty state). Consumes `subscriptions-core`; adds no persistence.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelizable (different files, no incomplete dependency)
- **[Story]**: US1 (upcoming list), US2 (monthly summary), US3 (empty state)

## Path Conventions

`lib/features/dashboard/{domain,application,presentation}`, reusable widgets in `lib/shared/widgets`, constants in `lib/shared/constants`. Tests in `test/unit` and `test/widget`. Matches plan.md.

---

## Phase 1: Setup

- [X] T001 Create `test/widget/` directory (unit dir already exists); confirm no new packages needed (`flutter pub get`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared constants used by more than one story.

- [X] T002 [P] Add `lib/shared/constants/dashboard_constants.dart` — `kWeeksPerYear = 52`, `kMonthsPerYear = 12`, `kRelativeDayThreshold = 30`

**Checkpoint**: Constants ready — stories can begin.

---

## Phase 3: User Story 1 - See upcoming payments at a glance (Priority: P1) 🎯 MVP

**Goal**: A brand-colored, date-sorted list of subscriptions with effective-renewal + relative-time labels.

**Independent Test**: Override `subscriptionsProvider` with seeded fakes (past/today/soon/far, mixed periods); assert sort order, rolled-forward dates, and labels.

### Implementation for User Story 1

- [X] T003 [P] [US1] Implement `effectiveNextRenewal(Subscription, DateTime now)` in `lib/features/dashboard/domain/renewal_calculator.dart` (calendar-aware roll-forward per data-model.md)
- [X] T004 [P] [US1] Implement `relativeDateLabel(DateTime renewal, DateTime now)` in `lib/features/dashboard/domain/relative_date_label.dart` (Bugün/Yarın/N gün sonra/date tr_TR, threshold const)
- [X] T005 [US1] Create `UpcomingPayment` view model in `lib/features/dashboard/domain/upcoming_payment.dart` (subscription + effectiveRenewal + daysUntil) (depends on T003)
- [X] T006 [US1] Add `upcomingPaymentsProvider` (AsyncValue<List<UpcomingPayment>>, sorted by effectiveRenewal then name) in `lib/features/dashboard/application/dashboard_providers.dart` (depends on T005)
- [X] T007 [P] [US1] Create reusable `BrandAvatar` in `lib/shared/widgets/brand_avatar.dart` — flutter_svg logo via brand catalog/`BrandResolver`, else initial + default color
- [X] T008 [US1] Create `PaymentListItem` in `lib/features/dashboard/presentation/widgets/payment_list_item.dart` — BrandAvatar + name (truncated) + amount/currency (intl) + relative label; brand color accent (depends on T004, T005, T007)
- [X] T009 [US1] Rewrite `lib/features/dashboard/presentation/dashboard_screen.dart` (replaces scaffold placeholder) — `ConsumerWidget`, render `AsyncValue` loading/error states + `ListView.builder` of `PaymentListItem`; dark mode (depends on T006, T008)
- [X] T010 [P] [US1] Unit tests `test/unit/renewal_calculator_test.dart` — past/today/future × weekly/monthly/yearly, month-end clamp (depends on T003) — maps SC-003
- [X] T011 [P] [US1] Unit tests `test/unit/relative_date_label_test.dart` — 0/1/N/threshold boundaries (depends on T004)
- [X] T012 [P] [US1] Widget test `test/widget/dashboard_screen_test.dart` — seeded list renders sorted, soonest on top (depends on T009) — maps SC-001

**Checkpoint**: US1 is a usable MVP — open app, see sorted upcoming payments.

---

## Phase 4: User Story 2 - Monthly spend, grouped by currency (Priority: P2)

**Goal**: Per-currency monthly-normalized totals (no conversion) shown atop the list.

**Independent Test**: Seed mixed periods/currencies; assert per-currency totals match hand math; no cross-currency sum.

### Implementation for User Story 2

- [X] T013 [P] [US2] Implement `monthlyAmount(Subscription)` in `lib/features/dashboard/domain/monthly_normalizer.dart` (weekly×52/12, yearly/12, monthly×1) (depends on T002)
- [X] T014 [US2] Implement `CurrencyTotal` + `currencySummary(List<Subscription>)` in `lib/features/dashboard/domain/currency_summary.dart` — group by currency, order TRY→USD→EUR, drop empties (depends on T013)
- [X] T015 [US2] Add `monthlySummaryProvider` (AsyncValue<List<CurrencyTotal>>) in `lib/features/dashboard/application/dashboard_providers.dart` (depends on T014; same file as T006 → sequential)
- [X] T016 [US2] Create `MonthlySummaryCard` in `lib/features/dashboard/presentation/widgets/monthly_summary_card.dart` — one row per currency, large amount + "/ay" (intl) (depends on T014)
- [X] T017 [US2] Integrate `MonthlySummaryCard` (fed by `monthlySummaryProvider`) at the top of `dashboard_screen.dart` (depends on T015, T016, T009; same file as T009 → sequential)
- [X] T018 [P] [US2] Unit tests `test/unit/monthly_normalizer_test.dart` — each period (depends on T013) — maps SC-002
- [X] T019 [P] [US2] Unit tests `test/unit/currency_summary_test.dart` — single/multi currency, no cross-sum, empty omitted (depends on T014) — maps SC-002/004

**Checkpoint**: US1 + US2 both work — list + per-currency summary.

---

## Phase 5: User Story 3 - Empty state guides first action (Priority: P3)

**Goal**: Friendly empty state + add CTA when there are no subscriptions.

**Independent Test**: Override `subscriptionsProvider` with an empty list; assert empty state + CTA shown, list/summary not rendered.

### Implementation for User Story 3

- [X] T020 [P] [US3] Create `DashboardEmptyState` in `lib/features/dashboard/presentation/widgets/dashboard_empty_state.dart` — icon + "Henüz abonelik yok" + primary "Abonelik ekle" CTA
- [X] T021 [US3] In `dashboard_screen.dart`: show `DashboardEmptyState` when data is empty; show a `FloatingActionButton` (+) when populated; both navigate toward the add flow via a placeholder route (depends on T009, T020; same file → sequential)
- [X] T022 [P] [US3] Widget test `test/widget/dashboard_empty_state_test.dart` — empty list → empty state + CTA visible (depends on T021) — maps SC-007

**Checkpoint**: All three stories functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T023 [P] Run `flutter analyze` and resolve any issues across the feature
- [X] T024 Run `flutter test` (unit + widget) green; confirm SC-001..007 coverage per quickstart.md
- [ ] T025 [P] Verify the app launches to the dashboard (`flutter run`) and the screen renders in dark mode with seeded data

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)** → **Foundational (P2)** → **Stories (P3–P5)** → **Polish (P6)**.
- US1 and US2 logic are independent; both feed the shared `dashboard_screen.dart` and shared `dashboard_providers.dart` (those integration tasks are sequential). US3 extends the screen last.

### Within Each Story

- US1: {T003, T004, T007} → T005 → T006; T008 after T004/T005/T007; T009 after T006/T008; tests T010/T011 after their fns, T012 after T009.
- US2: T013 → T014 → {T015, T016}; T017 after T015/T016/T009; tests T018/T019 after their fns.
- US3: T020 → T021 (after T009) → T022.

### Parallel Opportunities

- Foundational T002 alone.
- US1 pure fns + BrandAvatar: T003 ∥ T004 ∥ T007. Tests T010 ∥ T011 ∥ T018 ∥ T019 (different files).
- US1 and US2 domain/tests can progress in parallel; only the shared screen/providers edits serialize.

---

## Parallel Example: US1 domain + US2 domain

```bash
Task: "T003 renewal_calculator.dart"     # US1
Task: "T004 relative_date_label.dart"    # US1
Task: "T007 brand_avatar.dart"           # US1 (shared widget)
Task: "T013 monthly_normalizer.dart"     # US2
```

---

## Implementation Strategy

### MVP First (User Story 1)

Setup → Foundational → US1 → **STOP & VALIDATE** (`flutter test test/unit test/widget`, `flutter run`). The sorted upcoming-payments list alone is a usable home screen.

### Incremental Delivery

1. Setup + Foundational.
2. US1 → list works (MVP).
3. US2 → summary appears.
4. US3 → empty state polish.
5. Polish → analyze clean, suite green, app launches.

---

## Notes

- [P] = different files, no incomplete dependency. `dashboard_screen.dart` (T009/T017/T021) and `dashboard_providers.dart` (T006/T015) are shared → sequential.
- Read-only: do NOT call any core write use case; only watch `subscriptionsProvider`. Never mutate `nextRenewalDate`.
- `domain/` calculators take an injected `now` for deterministic tests.
- Commit per story checkpoint (English messages).
