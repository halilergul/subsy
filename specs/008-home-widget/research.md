# Phase 0 Research: Home Screen Widget

Framework + the premium `home_widget` choice are fixed by CONSTITUTION.md. Resolves widget-specific design + UI/UX (no Figma). No `NEEDS CLARIFICATION` remain.

---

## D1 — Pure payload over native logic

**Decision**: All decisions (which subscription is next, the relative-day label, formatted amounts, per-currency totals, the unified ≈ total, and the ready/empty/locked state) are computed in a pure `buildWidgetPayload` and emitted as **display-ready Turkish strings + a state enum**. The native widget only reads keys and draws text.

**Rationale**: Keeps logic in tested Dart (constitution), guarantees Android and iOS show identical content, and avoids re-implementing money/date/currency rules in Kotlin and Swift. `home_widget` stores primitive key/values, which maps cleanly to "a few preformatted strings".

**Alternatives**: compute in native — duplicated, untested, drift between platforms; rejected. `home_widget.renderFlutterWidget` (render a Flutter widget to an image) — heavier, fuzzy text, harder to theme per-OS; rejected for v1 (spec prefers native layout).

---

## D2 — Data transport (keys) & update trigger

**Decision**: Publish with `HomeWidget.saveWidgetData(key, value)` for a small fixed key set, then `HomeWidget.updateWidget(androidName: 'SubsyWidgetProvider', iOSName: 'SubsyWidget')`. Keys (all primitive):

| key | type | example |
|-----|------|---------|
| `state` | String | `ready` / `empty` / `locked` |
| `next_title` | String | `Netflix` |
| `next_when` | String | `3 gün sonra` |
| `next_amount` | String | `₺149,99` |
| `next_service_key` | String | `netflix` (for an optional native accent/color) |
| `total_line` | String | `₺549,99 / ay` (per-currency, joined) |
| `unified_line` | String | `≈ ₺1.240,50 / ay` (empty when N/A) |

**Rationale**: Primitive keys are the plugin's native contract; preformatted strings keep native trivial. A single state key drives which layout branch native shows.

**iOS specifics**: rates/data are shared via an **App Group** (`group.com.halilergul.subsy`); `HomeWidget.setAppGroupId(...)` is called at app start and the WidgetKit extension reads the same suite. Android uses the plugin's `SharedPreferences`-backed store automatically.

---

## D3 — Reactive sync

**Decision**: `startHomeWidgetSync(ref)` (called once in `SubsyApp`, beside `startReminderSync`/`startExchangeRateSync`) watches `subscriptionsProvider`, `targetCurrencyProvider`, `exchangeRatesProvider`, and `premiumStatusProvider`; on any emission it builds the payload (`now = DateTime.now()`) and calls `service.publish(payload)`. Best-effort: failures are swallowed (the last published payload remains).

**Rationale**: Add/edit/delete and rate/target/premium changes already flow through these providers, so the widget stays correct with no per-action wiring (FR-005/006/009). Mirrors the proven sync pattern.

---

## D4 — Next-payment selection (reuse)

**Decision**: Reuse `UpcomingPayment.from(sub, now)` (effective rolled-forward renewal) + `relativeDateLabel`. The "next" item is the one with the soonest `effectiveRenewal` (tie-broken by name) — exactly the dashboard's top item (FR-001/002, SC-001).

---

## D5 — Totals (reuse) & unified gating

**Decision**: `total_line` = `currencySummary(subs)` formatted with `formatMoney(..) + ' / ay'`, currencies joined (e.g. `₺549,99 · $12,99 / ay`). `unified_line` is filled only when the user is premium AND `unifiedMonthlyTotal(subs, target, rates)` is non-null → `'≈ ' + formatMoney(total, target) + ' / ay'`; otherwise empty (FR-002/003, SC-002). Per-currency totals are always shown for premium; reuse is 1:1 with the dashboard.

---

## D6 — Premium gating & states

**Decision**: If `!premium` → `state = locked` (only an upgrade teaser string; no real figures, FR-008/SC-004). Else if `subs` empty → `state = empty` (friendly "Abonelik ekle" string). Else `state = ready`. Downgrade naturally flips to `locked` on the next sync (FR-009).

---

## D7 — Tap-to-open

**Decision**: The native widget's root view opens the app. Android: a `PendingIntent` via the plugin's launch intent (`HomeWidgetLaunchIntent`) targeting `MainActivity`. iOS: `.widgetURL(...)` / the extension's default launch. v1 opens the dashboard (no per-element deep links) (FR-010, SC-006).

---

## D8 — Native scaffolds & device verification

**Decision**: Provide:
- **Android**: `SubsyWidgetProvider` (extends `HomeWidgetProvider`), a compact dark `subsy_widget.xml` (TextViews for title/when/amount/total), `subsy_widget_info.xml` metadata, and a `<receiver>` in the Manifest with the `APPWIDGET_UPDATE` filter.
- **iOS**: a `SubsyWidget` WidgetKit extension (SwiftUI timeline reading the App Group `UserDefaults`), Info.plist, and the App Group entitlement on both Runner and the extension.

**Verification**: These compile/render only with the platform toolchains; they are **verified on a real device/simulator** (quickstart), like the device checks deferred in prior features. The Dart payload pipeline + tests are the part validated now.

**Logo note (v1)**: native widgets can't easily load the app's Flutter SVG logo assets. v1 shows the **service name** (+ optional brand-color accent derived from `next_service_key` via a small native color map or the brand color string passed as a key). Bundling per-brand widget images is a follow-up; not required for the core value.

---

## UI/UX (no Figma)

- **Layout (compact, ~2x2)**: top line — next payment: service name (bold) + "N gün sonra"; right-aligned amount. Divider. Bottom — "Aylık" label + `total_line`; if present, `unified_line` beneath. Dark surface matching the app card (`0xFF17171D`), Turkish.
- **Empty**: centered "Abonelik ekle" hint.
- **Locked (free)**: lock glyph + "Premium ile aboneliklerini ana ekranda gör".
- Tapping anywhere opens the app.

> Recorded as the `UIUX-008` equivalent.

---

## Summary

| ID | Topic | Decision |
|----|-------|----------|
| D1 | Logic | pure `buildWidgetPayload` → display strings + state; native is dumb |
| D2 | Transport | `saveWidgetData` primitive keys + `updateWidget`; iOS App Group |
| D3 | Sync | watch subs/target/rates/premium → publish (best-effort) |
| D4 | Next payment | reuse effective renewal + `relativeDateLabel` (= dashboard top) |
| D5 | Totals | `currencySummary` + premium `unifiedMonthlyTotal` (gated) |
| D6 | States | locked (free) / empty (no subs) / ready |
| D7 | Tap | opens app (dashboard) |
| D8 | Native | Android App Widget + iOS WidgetKit scaffolds; device-verified; logo deferred |
