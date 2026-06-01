# Implementation Plan: Spending Statistics

**Branch**: `005-statistics` | **Date**: 2026-06-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-statistics/spec.md`

## Summary

A read-only statistics screen showing, per currency and per selected period (monthly/yearly), the category spend breakdown (donut chart + list with amounts and percentages), the per-currency total, and the most expensive subscriptions. All figures derive from the existing subscription stream and the dashboard's monthly normalization; the only new logic is pure aggregation (group by category, percentages, ranking, period scaling), which is fully unit-tested. The chart is rendered with `fl_chart`. No Figma → UI/UX decided in research.md.

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (stable)

**Primary Dependencies**: `flutter_riverpod` (derive from core stream); **NEW**: `fl_chart` (donut + bar charts). Reuses `monthlyAmount` (dashboard), `subscriptionsProvider` (core), `formatMoney` + `BrandAvatar` (shared). No new persistence.

**Storage**: None — pure derivation from the in-memory subscription list.

**Testing**: `flutter_test` — pure unit tests for the aggregator (per-currency category totals, percentages summing to 100%, period scaling ×12, ranking, no cross-currency blend); widget test for empty vs data rendering via a `ProviderScope` override of `subscriptionsProvider`. `fl_chart` widgets are not unit-tested (declarative, fed by the tested aggregator).

**Target Platform**: iOS 13+ / Android, offline, dark mode, Turkish UI.

**Performance Goals**: O(n) aggregation over a personal-scale set; recomputed only when the stream emits or the period toggles.

**Constraints**: Per-currency only (no conversion); no payment history (snapshot only — no trends); read-only; typed error state.

**Scale/Scope**: One screen + pure aggregator + a few chart/list widgets + category color/label map + tests.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Business logic separated from UI | ✅ | Pure `statistics_calculator`; widgets only render |
| Reuse over duplication | ✅ | Reuses `monthlyAmount`, `subscriptionsProvider`, `formatMoney`, `BrandAvatar`; no new rules |
| Components get data via provider | ✅ | Derived providers off the core stream + a period state provider |
| Every feature tested; critical path mandatory | ✅ | Aggregator unit-tested (the spec's measurable outcomes) |
| No magic numbers | ✅ | Category colors/labels + period factor (12) named consts |
| Typed error handling, Turkish messages | ✅ | AsyncValue error → Turkish message |
| Offline / no backend | ✅ | No network |
| Dark mode / Turkish UI | ✅ | Mandatory |
| English code / Turkish UI | ✅ | Code English; labels Turkish |

**Initial gate: PASS.** No violations → Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/005-statistics/
├── plan.md · research.md · data-model.md · quickstart.md
├── contracts/statistics.md
├── checklists/requirements.md
└── tasks.md  (later)
```

### Source Code (repository root)

```text
lib/features/statistics/
├── domain/
│   ├── stat_period.dart              # enum StatPeriod { monthly, yearly } + factor
│   ├── category_breakdown.dart       # value: currency, list of CategorySlice, total
│   ├── statistics_calculator.dart    # PURE: build per-currency breakdowns + ranking
│   └── ranked_subscription.dart      # value: subscription + period amount
├── application/
│   └── statistics_providers.dart     # statPeriodProvider (state) + statisticsProvider (derived)
└── presentation/
    ├── statistics_screen.dart        # period toggle, per-currency sections, states
    └── widgets/
        ├── category_donut.dart        # fl_chart PieChart (donut) for a currency's slices
        ├── category_legend.dart       # list: color dot + Turkish label + amount + %
        └── top_subscriptions.dart     # ranked list (reuses BrandAvatar)

lib/shared/constants/category_style.dart   # SubscriptionCategory → color + Turkish label
lib/app/router/app_router.dart             # add /statistics route
lib/features/dashboard/presentation/dashboard_screen.dart  # AppBar entry to statistics

test/unit/
└── statistics_calculator_test.dart        # totals, %, scaling, ranking, per-currency
test/widget/
└── statistics_screen_test.dart            # empty vs data
```

**Structure Decision**: New `lib/features/statistics/` with the established split. The only logic — `statistics_calculator` — is a pure function producing per-currency `CategoryBreakdown`s + rankings, unit-tested to the spec's numeric criteria. `statisticsProvider` derives `AsyncValue` from the core stream and the period state; the screen renders states and feeds the tested data into `fl_chart`. Category color+label live in a shared `category_style.dart` (reused by legend + future detail screens). `BrandAvatar`, `formatMoney`, and `monthlyAmount` are reused as-is.

## Complexity Tracking

> No constitution violations. Section intentionally empty.
