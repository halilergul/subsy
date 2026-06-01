# Implementation Plan: Home Screen Widget (Premium)

**Branch**: `008-home-widget` | **Date**: 2026-06-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-home-widget/spec.md`

## Summary

A premium home-screen widget that mirrors, on-device, the **next upcoming payment** (brand, name, relative-day label, amount) and the **monthly total** (per currency + the premium unified ≈ total). The only new logic is a **pure `buildWidgetPayload` function** that turns the existing subscription/dashboard/conversion data into ready-to-display strings + a state flag (ready / empty / locked) — fully unit-tested. A thin `HomeWidgetService` (behind an interface) pushes that payload to the OS via the `home_widget` plugin (`saveWidgetData` + `updateWidget`), and a reactive sync recomputes it whenever subscriptions, rates, target currency, or premium status change. The **native widget UI** (Android App Widget, iOS WidgetKit) renders those strings; native targets are scaffolded here and **verified on a device** (not buildable in this environment).

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (stable); Kotlin (Android widget), Swift/WidgetKit (iOS widget)

**Primary Dependencies**: `flutter_riverpod`, `home_widget` (^0.9.2, already in pubspec). Reuses `subscriptionsProvider`, `effectiveNextRenewal`/`UpcomingPayment`, `relativeDateLabel`, `currencySummary`, `monthlyAmount`, the currency-conversion `unifiedMonthlyTotal`/`targetCurrencyProvider`/`exchangeRatesProvider`, `premiumStatusProvider`, `formatMoney`, `brandByKey`. **No new package.**

**Storage**: None new. The widget reads a small key/value snapshot written by `home_widget` (shared on-device store / iOS App Group); no Isar collection.

**Testing**: `flutter_test` — pure unit tests for `buildWidgetPayload` (next-payment selection via effective renewal, relative-day label, per-currency totals, unified ≈ only when available, empty state, locked state when not premium). The `HomeWidgetService` is behind an interface and faked; the reactive sync is tested with fakes. Native render is **device-verified** (manual, per quickstart) — not unit-testable here.

**Target Platform**: iOS 14+ (WidgetKit) / Android (App Widget), offline, dark, Turkish.

**Performance Goals**: O(n) payload build over a personal-scale set; pushed only on data/settings change (no polling).

**Constraints**: Premium-gated; offline (widget reads on-device data only — no network for the widget); never shows real figures to free users; one compact size for v1; native UI is a dumb string renderer (logic stays in Dart).

**Scale/Scope**: One pure builder + one service interface + one reactive sync + main wiring + Android & iOS native widget scaffolds + tests.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Business logic separated from UI | ✅ | Pure `buildWidgetPayload`; native widget only renders pre-formatted strings |
| Reuse over duplication | ✅ | Reuses effective-renewal, `currencySummary`, `unifiedMonthlyTotal`, `relativeDateLabel`, `formatMoney`, `premiumStatusProvider` — no new rules |
| Data via provider; platform behind a service | ✅ | `HomeWidgetService` wraps the plugin; UI/sync read providers |
| Every feature tested; critical path mandatory | ✅ | Payload builder unit-tested to the spec's measurable criteria; service/sync faked |
| No magic numbers/strings | ✅ | Widget data keys + widget provider names as named consts |
| Typed error handling, Turkish messages | ✅ | Sync is best-effort; failures swallowed (cache/last payload remains) |
| Offline / no backend | ✅ | Widget reads on-device snapshot only; no network. The premium home-widget is a CONSTITUTION-approved feature (Stack: `home_widget` premium) |
| Dark mode / Turkish UI | ✅ | Native widget dark + Turkish strings (built in Dart) |
| Premium gating | ✅ | Reuses `premiumStatusProvider` seam; free → locked payload |
| English code / Turkish UI | ✅ | Code English; widget strings Turkish |

**Initial gate: PASS.** `home_widget` is an explicitly planned premium feature in CONSTITUTION (Stack + Ürün kapsamı). The native render-verification gap is an environment limitation, documented — not a constitution violation → Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/008-home-widget/
├── plan.md · research.md · data-model.md · quickstart.md
├── contracts/home-widget.md
├── checklists/requirements.md
└── tasks.md  (later)
```

### Source Code (repository root)

```text
lib/features/home_widget/
├── domain/
│   ├── widget_payload.dart          # value: state + pre-formatted strings (next payment, totals, unified)
│   ├── widget_payload_builder.dart  # PURE: buildWidgetPayload(subs, now, premium, target, rates)
│   └── home_widget_service.dart      # interface: publish(WidgetPayload) / clear()
├── data/
│   └── plugin_home_widget_service.dart  # home_widget impl: saveWidgetData(keys) + updateWidget(...)
└── application/
    ├── home_widget_providers.dart    # homeWidgetServiceProvider (overridden in main)
    └── home_widget_sync.dart         # startHomeWidgetSync(ref): watch sources → publish

lib/main.dart                         # startHomeWidgetSync(ref); HomeWidget.setAppGroupId (iOS) at boot

# Native scaffolds (device-verified)
android/app/src/main/kotlin/.../SubsyWidgetProvider.kt   # HomeWidgetProvider subclass
android/app/src/main/res/layout/subsy_widget.xml          # compact dark layout (text fields)
android/app/src/main/res/xml/subsy_widget_info.xml        # AppWidget metadata (size, preview)
android/app/src/main/AndroidManifest.xml                  # <receiver> for the widget + APPWIDGET_UPDATE
ios/SubsyWidget/                                          # WidgetKit extension (SwiftUI) + Info.plist
ios/Runner/Runner.entitlements + SubsyWidget.entitlements # App Group (shared UserDefaults)

test/unit/
└── widget_payload_builder_test.dart  # selection, label, totals, unified, empty, locked
test/support/fakes.dart               # add FakeHomeWidgetService (records published payloads)
```

**Structure Decision**: New `lib/features/home_widget/` with the established split. The sole logic — `buildWidgetPayload` — is pure (no Flutter/plugin imports) and produces **display-ready Turkish strings + a state enum**, so the native widget is a dumb renderer (keeps logic testable and the two platforms consistent). `HomeWidgetService` hides the `home_widget` plugin behind an interface (faked in tests; overridden in `main`). `startHomeWidgetSync` mirrors `startReminderSync`/`startExchangeRateSync`: it watches the subscription stream + target currency + rates + premium and republishes the payload on any change. Native widget targets (Android App Widget, iOS WidgetKit) are scaffolded and flagged for on-device verification.

## Complexity Tracking

> No constitution violations. Section intentionally empty.
