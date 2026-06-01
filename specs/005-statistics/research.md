# Phase 0 Research: Statistics

Framework fixed by CONSTITUTION.md. Resolves statistics-specific design + UI/UX (no Figma). No `NEEDS CLARIFICATION` remain.

---

## D1 — Aggregation model (pure)

**Decision**: `statistics_calculator` exposes pure functions over `List<Subscription>`:
- `categoryBreakdowns(subs, period)` → `List<CategoryBreakdown>` — one per currency (ordered TRY→USD→EUR), each with the currency total and a list of `CategorySlice(category, amount, percentage)` sorted by amount desc.
- `topSubscriptions(subs, period, {limit})` → per-currency ranked `RankedSubscription`s by period amount desc.
Period amount = `monthlyAmount(sub) × period.factor` (monthly=1, yearly=12).

**Rationale**: Reuses the dashboard's `monthlyAmount`; all spec numbers (totals, %, scaling, ranking) are deterministic and unit-testable without any widget. Percentages computed from the per-currency total.

**Alternatives**: compute inside widgets — untestable, recomputed each rebuild; rejected.

---

## D2 — Percentages summing to 100%

**Decision**: Each slice's percentage = `amount / currencyTotal × 100`. For display, round to whole numbers but compute the last slice as `100 − sum(others)` so the visible total is exactly 100% (avoids 99/101 artifacts). The chart uses raw ratios (not rounded).

**Rationale**: FR-004/SC-002. Largest-remainder-style fix on the final slice is simple and good enough at this scale.

---

## D3 — Period scaling

**Decision**: `StatPeriod { monthly, yearly }` with `factor` (1, 12). Yearly multiplies every amount by 12; percentages are scale-invariant (unchanged), satisfying FR-007/SC-003. Period is UI state (a provider), default monthly.

---

## D4 — Per-currency, never blended

**Decision**: Group strictly by `Currency`; produce a separate `CategoryBreakdown` and ranking per currency, ordered TRY→USD→EUR. No cross-currency sum or ranking (FR-005/SC-004). The screen renders one section per currency.

---

## D5 — Reactive derivation

**Decision**: `statisticsProvider` watches `subscriptionsProvider` (AsyncValue) + `statPeriodProvider` (state) → `AsyncValue<StatisticsView>` (the breakdowns + rankings). Screen renders `when(loading/error/data)`; empty data → empty state.

**Rationale**: Auto-updates on add/edit/delete (FR-010/SC-005); pure recompute on period change.

---

## D6 — Charts: fl_chart

**Decision**: Add `fl_chart`. Category donut = `PieChart` with a center hole (`centerSpaceRadius`), one section per `CategorySlice` colored by the category color, sized by raw amount. A compact bar representation (optional) can reuse the same slices; for v1 the donut + legend list is the primary visual, with the legend doubling as the "bar" (color dot + amount + %). Charts are fed entirely by the tested aggregator.

**Rationale**: `fl_chart` is the de-facto Flutter charting lib; donut matches the "görsel olarak güçlü" goal. Keeping charts as dumb renderers of tested data keeps logic testable.

**Alternatives**: hand-rolled CustomPainter donut — more effort, less polish; rejected given the explicit decision for fl_chart.

---

## D7 — Category colors & labels

**Decision**: A shared `category_style.dart`: `SubscriptionCategory → (Color, Turkish label)`. Stable, distinct colors (e.g. streaming red, music green, cloud blue, ai teal, productivity purple, shopping orange, other grey). Reused by donut, legend, and future screens.

| Category | Label | Color (example) |
|----------|-------|-----------------|
| streaming | Yayın | 0xFFE5484D |
| music | Müzik | 0xFF30A46C |
| cloud | Bulut | 0xFF3E63DD |
| ai | Yapay zeka | 0xFF12A594 |
| productivity | Üretkenlik | 0xFF8E4EC6 |
| shopping | Alışveriş | 0xFFF76808 |
| other | Diğer | 0xFF7E808A |

---

## UI/UX Decisions (no Figma)

- **Entry point**: a chart/insights icon in the dashboard `AppBar` → `/statistics` (alongside the notifications icon).
- **Layout**: dark, Turkish. Top: a `SegmentedButton` Aylık/Yıllık. Then, per currency: a section with the currency total (large), a centered donut, and a legend list (color dot + label + amount + %). Below: "En pahalı" top-subscriptions list (BrandAvatar + name + amount).
- **Multiple currencies**: stacked sections, each self-contained (own donut + total).
- **Empty**: centered icon + "Görüntülenecek veri yok" + hint to add subscriptions.
- **Loading/error**: spinner; Turkish error text.

> Recorded as the `UIUX-005` equivalent.

---

## Summary

| ID | Topic | Decision |
|----|-------|----------|
| D1 | Aggregation | pure `statistics_calculator` (breakdowns + ranking) |
| D2 | Percentages | rounded, last slice = 100 − others |
| D3 | Period | StatPeriod factor (1/12); % scale-invariant |
| D4 | Currency | strictly per-currency, TRY→USD→EUR, no blend |
| D5 | Reactivity | derived AsyncValue off core stream + period state |
| D6 | Charts | fl_chart donut + legend, fed by tested data |
| D7 | Category style | shared color+label map |
| UI | Look | dashboard AppBar entry; toggle + per-currency donut+legend+top list |
