# Phase 1 Data Model: Dashboard

No persisted entities. The dashboard introduces only **derived, view-only** types computed from `subscriptions-core`'s `Subscription` list.

---

## `UpcomingPayment` (view model)

A subscription paired with its computed display data.

| Field | Type | Notes |
|-------|------|-------|
| `subscription` | `Subscription` | the source record (from core) |
| `effectiveRenewal` | `DateTime` | next future renewal (D1); ≥ today |
| `daysUntil` | `int` | whole days from today to `effectiveRenewal` (≥ 0) |

- Sort order: by `effectiveRenewal` ascending, tie-break by `subscription.name` (FR-001/FR-005).
- Convenience: `brandKey => subscription.serviceKey`, `amount => subscription.amount`, `currency => subscription.currency`.

## `CurrencyTotal` (view model)

| Field | Type | Notes |
|-------|------|-------|
| `currency` | `Currency` | TRY / USD / EUR |
| `monthlyTotal` | `double` | sum of `monthlyAmount` for that currency (D2) |

- The summary is `List<CurrencyTotal>`, ordered TRY → USD → EUR, omitting currencies with no subscriptions (FR-009).

---

## Pure functions (the testable core)

### `effectiveNextRenewal(Subscription s, DateTime now) → DateTime`
- If `s.nextRenewalDate` (date part) ≥ `now` date → return it.
- Else advance by `s.billingPeriod` until ≥ `now` date:
  - weekly: +7 days; monthly: +1 calendar month (clamp day to month length); yearly: +1 year.
- Compared at day granularity.

### `monthlyAmount(Subscription s) → double`
- weekly → `s.amount * kWeeksPerYear / kMonthsPerYear`
- yearly → `s.amount / kMonthsPerYear`
- monthly → `s.amount`

### `currencySummary(List<Subscription> subs) → List<CurrencyTotal>`
- group by `currency`, sum `monthlyAmount`, order TRY→USD→EUR, drop empties.

### `relativeDateLabel(DateTime renewal, DateTime now) → String`
- `diff = whole days(renewal - now)`:
  - 0 → "Bugün"; 1 → "Yarın"; 2..`kRelativeDayThreshold` → "$diff gün sonra";
  - `> kRelativeDayThreshold` → absolute `d MMM yyyy` (tr_TR via intl).

## Constants (`shared/constants/dashboard_constants.dart`)

| Const | Value |
|-------|-------|
| `kWeeksPerYear` | 52 |
| `kMonthsPerYear` | 12 |
| `kRelativeDayThreshold` | 30 |

## State (screen)

Driven by `AsyncValue` from the derived providers:
- **loading** → spinner/skeleton (FR-013)
- **error** → Turkish `AppError.message` + retry (FR-013)
- **data, empty** → empty state + add CTA (FR-011)
- **data, non-empty** → summary card + payments list + FAB (FR-001/007)
