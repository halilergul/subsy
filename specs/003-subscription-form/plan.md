# Implementation Plan: Subscription Form (Add / Edit / Delete)

**Branch**: `003-subscription-form` | **Date**: 2026-06-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-subscription-form/spec.md`

## Summary

A single form screen (add + edit modes, edit also offers delete) that writes subscriptions through `subscriptions-core`'s existing use cases. A Riverpod form controller holds the field state, builds a `SubscriptionDraft`, calls `AddSubscription`/`UpdateSubscription`/`DeleteSubscription`, and maps the typed `Result` to UI (close on success, Turkish message on validation/limit/storage failure). A live brand preview uses the existing `BrandResolver`. The dashboard's placeholder add CTA and card taps are wired to this screen. All business rules already exist in core; this feature is the thin, testable UI surface over them. No Figma → UI/UX decisions are fixed in research.md.

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (stable)

**Primary Dependencies**: `flutter_riverpod` (form controller + use-case providers from core), `go_router` (form routes), `intl` (none new). Reuses core `AddSubscription`/`UpdateSubscription`/`DeleteSubscription`, `SubscriptionValidator`, `BrandResolver`, and the shared `BrandAvatar`. No new packages.

**Storage**: None added — writes go through core's repository via use cases.

**Testing**: `flutter_test` — controller unit tests (submit success / validation failure / limit reached / edit / delete) with `ProviderScope` overriding the repository (the existing fake) and premium flag; widget tests for render, validation message, edit pre-fill, and delete confirmation.

**Target Platform**: iOS 13+ / Android, offline, dark mode mandatory, Turkish labels.

**Project Type**: Mobile app (Flutter), feature-first layered architecture.

**Performance Goals**: Instant local writes; form interactions at 60 fps. No heavy work on the UI thread.

**Constraints**: No duplication of business rules (validation/limit/brand enrichment stay in core); typed `Result`/`AppError` → Turkish messages; read-only rules unchanged.

**Scale/Scope**: One screen + one controller + a few field widgets + route wiring + tests.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Business logic separated from UI | ✅ | Validation/limit/enrichment in core; controller orchestrates, widgets render |
| Reuse over duplication | ✅ | Calls existing use cases/validator/resolver; reuses `BrandAvatar`; adds no rules |
| Components get data via provider | ✅ | Controller is a Riverpod Notifier; widgets watch it; use cases injected |
| Every feature tested; critical path mandatory | ✅ | Controller submit/edit/delete/limit unit-tested; key widget flows covered |
| No magic numbers/strings | ✅ | Field limits/currencies/periods come from core enums/consts |
| Typed error handling, Turkish messages | ✅ | `Result`→ `AppError.message`; no raw exceptions surfaced |
| Offline / no backend | ✅ | No network |
| Dark mode / Turkish UI | ✅ | Mandatory; labels Turkish |
| English code / Turkish UI | ✅ | Code English, UI strings Turkish |

**Initial gate: PASS.** No violations → Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/003-subscription-form/
├── plan.md          # This file
├── research.md      # Phase 0 — design + UI/UX decisions
├── data-model.md    # Phase 1 — form state model
├── quickstart.md    # Phase 1
├── contracts/
│   └── subscription_form.md   # controller + route + widget contracts
├── checklists/requirements.md
└── tasks.md         # /speckit-tasks output (later)
```

### Source Code (repository root)

```text
lib/features/subscriptions/
├── application/
│   └── subscription_form_controller.dart   # Notifier: SubscriptionFormState + submit()/delete()
└── presentation/
    ├── subscription_form_screen.dart        # add/edit screen; renders state, handles Result
    └── widgets/
        ├── currency_selector.dart           # SegmentedButton over Currency
        ├── period_selector.dart             # SegmentedButton over BillingPeriod
        └── brand_preview.dart               # BrandAvatar + resolved name (reuses shared BrandAvatar)

lib/app/router/app_router.dart               # add routes: /subscription/add, /subscription/edit (extra: Subscription)

lib/features/dashboard/presentation/
├── dashboard_screen.dart                     # wire add CTA + FAB → add route (replace placeholder SnackBar)
└── widgets/payment_list_item.dart            # onTap → edit route with the subscription

test/unit/
└── subscription_form_controller_test.dart    # submit success/validation/limit, edit, delete (fake repo + premium)
test/widget/
└── subscription_form_screen_test.dart        # render, validation message, edit pre-fill, delete confirm
```

**Structure Decision**: The form lives in the existing `subscriptions` feature (it is the write surface for that aggregate), filling its previously-empty `presentation/` and extending `application/`. A `SubscriptionFormController` (Riverpod `Notifier`, autoDispose, optionally seeded with the editing `Subscription`) holds all field state and the submit/delete orchestration, so the screen widget stays declarative and the logic is unit-testable by overriding the repository/premium providers. Routes are added to the central `app_router.dart`; the dashboard's existing CTA/`onTap` hooks are pointed at them (replacing the placeholder).

## Complexity Tracking

> No constitution violations. Section intentionally empty.
