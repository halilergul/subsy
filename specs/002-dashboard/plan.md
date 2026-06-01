# Implementation Plan: Dashboard (Home Screen)

**Branch**: `002-dashboard` | **Date**: 2026-06-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-dashboard/spec.md`

## Summary

Build Subsy's home screen on top of `subscriptions-core`. It renders two derived views from the reactive subscription stream: an **upcoming-payments list** (all subscriptions sorted by effective next renewal, brand-colored cards, relative-time labels, past dates rolled forward) and a **monthly summary grouped by currency** (no conversion). Plus loading / error / empty states and an add-subscription navigation CTA. Read-only. The derived calculations (renewal rollover, monthly normalization, per-currency grouping, relative-time labels) are pure, unit-tested functions; the UI is thin. Because there is no Figma, this plan also fixes the UI/UX decisions (see research.md) per CONSTITUTION.md.

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (stable)

**Primary Dependencies**: `flutter_riverpod` (consume `subscriptionsProvider` from core), `flutter_svg` (brand logos), `intl` (tr_TR currency/date formatting), `go_router` (already wired). No new packages.

**Storage**: None added — reads through `subscriptions-core`'s repository/stream.

**Testing**: `flutter_test` unit tests for the pure calculators (renewal rollover, monthly normalization, grouping, relative-time); optional widget tests for empty/loading/list states using a `ProviderScope` override of `subscriptionsProvider`.

**Target Platform**: iOS 13+ / Android, offline, dark mode mandatory.

**Project Type**: Mobile app (Flutter), feature-first layered architecture.

**Performance Goals**: Smooth scroll with 100+ items via lazy `ListView.builder`; derived computation O(n) recomputed only when the stream emits.

**Constraints**: No currency conversion (per-currency grouping only); no mutation of stored data (display-only renewal rollover); Turkish UI strings; typed error state from `AppError`.

**Scale/Scope**: Personal-scale lists; one screen + a few widgets + 4 pure helpers.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Business logic separated from UI | ✅ | Renewal/normalization/grouping/label logic in `dashboard/domain`, pure & tested; widgets are thin |
| Components get data via provider, not direct fetch | ✅ | Screen watches `dashboardProvider`s; never touches Isar/repo directly |
| Reuse over duplication | ✅ | Consumes core's `subscriptionsProvider`, brand catalog/resolver; no new storage |
| Every feature tested; critical path mandatory | ✅ | Pure calculators unit-tested (the spec's measurable outcomes) |
| No magic numbers | ✅ | `kWeeksPerYear`/normalization + relative-time thresholds are named consts |
| Typed error handling, Turkish messages | ✅ | Error state derived from `AppError`; no raw exceptions in UI |
| Offline / no backend | ✅ | No network |
| Dark mode | ✅ | Mandatory; theme already dark |
| English code / Turkish UI | ✅ | Code English; UI strings Turkish |

**Initial gate: PASS.** No violations → Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/002-dashboard/
├── plan.md          # This file
├── research.md      # Phase 0 — incl. UI/UX decisions (no Figma)
├── data-model.md    # Phase 1 — derived view models
├── quickstart.md    # Phase 1
├── contracts/
│   └── dashboard_providers.md   # provider + widget contracts
├── checklists/requirements.md
└── tasks.md         # /speckit-tasks output (later)
```

### Source Code (repository root)

```text
lib/features/dashboard/
├── domain/
│   ├── renewal_calculator.dart   # effectiveNextRenewal(sub, now) — rolls past dates forward
│   ├── monthly_normalizer.dart   # monthlyAmount(sub) — weekly×52/12, yearly/12, monthly×1
│   ├── currency_summary.dart     # groups monthly amounts by Currency → list of totals
│   ├── upcoming_payment.dart     # view model: subscription + effectiveRenewal + sort key
│   └── relative_date_label.dart  # DateTime → "Bugün"/"Yarın"/"N gün sonra"/date (tr)
├── application/
│   └── dashboard_providers.dart  # upcomingPaymentsProvider, monthlySummaryProvider (derive from core stream)
└── presentation/
    ├── dashboard_screen.dart     # replaces the placeholder screen; AsyncValue → loading/error/empty/data
    └── widgets/
        ├── monthly_summary_card.dart
        ├── payment_list_item.dart   # brand-colored card; flutter_svg logo or initial fallback
        └── dashboard_empty_state.dart

lib/shared/
├── constants/dashboard_constants.dart   # kWeeksPerYear=52, kMonthsPerYear=12, relative-time threshold
└── widgets/brand_avatar.dart            # reusable: svg logo by serviceKey, else initial + color

test/unit/
├── renewal_calculator_test.dart
├── monthly_normalizer_test.dart
├── currency_summary_test.dart
└── relative_date_label_test.dart
test/widget/
└── dashboard_screen_test.dart   # empty/loading/data via ProviderScope overrides (optional but included)
```

**Structure Decision**: New `lib/features/dashboard/` mirroring the established `domain` / `application` / `presentation` split. All view math lives in `domain` as pure functions (no Flutter imports where avoidable) so it is unit-testable and the widgets stay declarative. `dashboard/application` providers transform core's `subscriptionsProvider` (an `AsyncValue<List<Subscription>>`) into the sorted upcoming list and the per-currency summary; the screen renders the `AsyncValue` states. A reusable `BrandAvatar` widget (logo-or-initial) goes in `shared/widgets` since later features (statistics, detail) will reuse it.

## Complexity Tracking

> No constitution violations. Section intentionally empty.
