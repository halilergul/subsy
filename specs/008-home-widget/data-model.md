# Phase 1 Data Model: Home Screen Widget

No persisted entities — one transient value (the payload) + one pure builder. The payload is written to the plugin's on-device key/value store the native widget reads.

---

## `WidgetState` (enum)

`ready` · `empty` · `locked`. Drives which native layout branch renders.

## `WidgetPayload` (transient value, display-ready)

| Field | Type | Notes |
|-------|------|-------|
| `state` | `WidgetState` | ready / empty / locked |
| `nextTitle` | `String` | service name (empty unless ready) |
| `nextWhen` | `String` | relative-day label, e.g. "3 gün sonra" |
| `nextAmount` | `String` | formatted, e.g. "₺149,99" |
| `nextServiceKey` | `String` | brand key for an optional native accent (may be empty) |
| `totalLine` | `String` | per-currency monthly total, e.g. "₺549,99 / ay" |
| `unifiedLine` | `String` | "≈ ₺1.240,50 / ay" or empty when N/A |

All strings are **pre-formatted Turkish** so the native widget renders text directly. `toMap()` exposes the fixed primitive key set (see contracts) for `HomeWidget.saveWidgetData`.

---

## Pure function: `widget_payload_builder`

```dart
WidgetPayload buildWidgetPayload({
  required List<Subscription> subs,
  required DateTime now,
  required bool isPremium,
  required Currency target,
  ExchangeRates? rates,
});
```

### Rules
1. `!isPremium` → `state = locked`; all figure fields empty (FR-008).
2. `subs` empty → `state = empty`; figure fields empty (FR-004).
3. Otherwise `state = ready`:
   - **Next payment**: pick the subscription with the soonest `effectiveNextRenewal(sub, now)` (tie-break by name, lowercased). `nextTitle = sub.name`; `nextWhen = relativeDateLabel(renewal, now)`; `nextAmount = formatMoney(sub.amount, sub.currency)`; `nextServiceKey = sub.serviceKey ?? ''` (FR-001/002).
   - **Totals**: `totalLine` = `currencySummary(subs)` mapped to `formatMoney(total, currency)` joined by " · ", suffixed " / ay" (FR-002).
   - **Unified**: if `rates != null` and `unifiedMonthlyTotal(subs, target, rates)` non-null → `unifiedLine = '≈ ' + formatMoney(total.amount, target) + ' / ay'`; else `''` (FR-003).

> Pure: no Flutter/plugin/Isar imports. Deterministic given inputs (`now` injected).

---

## Orchestration & state

```
homeWidgetServiceProvider = HomeWidgetService   // overridden in main with the plugin impl
startHomeWidgetSync(ref):                        // once, in SubsyApp
  on (subscriptions | targetCurrency | exchangeRates | premium) emit:
    payload = buildWidgetPayload(subs, now(), isPremium, target, rates)
    service.publish(payload)        // best-effort; errors swallowed
```

### `HomeWidgetService` states it produces
| Payload state | Native render |
|---------------|---------------|
| `ready` | next payment line + monthly total (+ unified if present) |
| `empty` | "Abonelik ekle" hint |
| `locked` | premium upsell (no real figures) |

---

## Reuse map (unchanged dependencies)

| Reused | From | Used for |
|--------|------|----------|
| `Subscription`, `Currency` | subscriptions-core | inputs |
| `effectiveNextRenewal` / `UpcomingPayment` | dashboard | next-payment selection |
| `relativeDateLabel` | dashboard | "N gün sonra" |
| `currencySummary`, `monthlyAmount` | dashboard | per-currency total |
| `unifiedMonthlyTotal`, `targetCurrencyProvider`, `exchangeRatesProvider` | currency | unified ≈ total |
| `premiumStatusProvider` | subscriptions-core | gating |
| `formatMoney` | shared | formatting |
