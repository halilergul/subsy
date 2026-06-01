# Phase 1 Data Model: Statistics

No persisted entities — only derived, view-only values and pure functions.

---

## `StatPeriod` (enum)

`monthly` (factor 1) · `yearly` (factor 12). `factor` getter returns the multiplier applied to monthly-normalized amounts.

## `CategorySlice` (view value)

| Field | Type | Notes |
|-------|------|-------|
| `category` | `SubscriptionCategory` | |
| `amount` | `double` | period-normalized total for this category (within a currency) |
| `percentage` | `double` | share of the currency total (0–100), display-rounded so slices sum to 100 |

## `CategoryBreakdown` (view value)

| Field | Type | Notes |
|-------|------|-------|
| `currency` | `Currency` | |
| `total` | `double` | period-normalized total for this currency |
| `slices` | `List<CategorySlice>` | sorted by amount desc; empty categories omitted |

## `RankedSubscription` (view value)

| Field | Type | Notes |
|-------|------|-------|
| `subscription` | `Subscription` | source |
| `amount` | `double` | period-normalized amount |

## `StatisticsView` (aggregate, view-only)

| Field | Type | Notes |
|-------|------|-------|
| `period` | `StatPeriod` | the period these figures reflect |
| `breakdowns` | `List<CategoryBreakdown>` | one per currency (TRY→USD→EUR) |
| `topByCurrency` | `Map<Currency, List<RankedSubscription>>` | ranked desc per currency |
| `isEmpty` | `bool` | true when there are no subscriptions |

---

## Pure functions (`statistics_calculator`)

```dart
double periodAmount(Subscription s, StatPeriod p);          // monthlyAmount(s) * p.factor
List<CategoryBreakdown> categoryBreakdowns(List<Subscription> subs, StatPeriod p);
Map<Currency, List<RankedSubscription>> topSubscriptions(
    List<Subscription> subs, StatPeriod p, {int? limit});
StatisticsView buildStatistics(List<Subscription> subs, StatPeriod p);
```

### `categoryBreakdowns` rules
1. Group `subs` by `currency`.
2. Within a currency, sum `periodAmount` per `category`; drop zero categories.
3. `total` = sum of category amounts.
4. `percentage` = `amount / total * 100`, rounded for display with the **largest slice absorbing the rounding remainder** so the displayed set sums to 100.
5. Slices sorted by amount desc. Currencies ordered TRY→USD→EUR.

### `topSubscriptions` rules
- Per currency, subscriptions sorted by `periodAmount` desc; optional `limit` (e.g. top 5). Never compares across currencies.

---

## States (screen)

| State | UI |
|-------|----|
| loading | spinner |
| error | Turkish message |
| data + empty | empty state (no chart) |
| data | period toggle + per-currency (total + donut + legend) + top list |

> All figures come from `buildStatistics`; the period toggle re-invokes it with the new `StatPeriod` (pure recompute). Percentages are unaffected by period.
