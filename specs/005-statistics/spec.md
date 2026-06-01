# Feature Specification: Spending Statistics

**Feature Branch**: `005-statistics`

**Created**: 2026-06-01

**Status**: Draft

**Input**: User description: "İstatistik ekranı — mevcut aboneliklerin harcama dağılımı. fl_chart donut + bar, aylık/yıllık toggle, para birimine gruplu (çeviri yok). Kategori dağılımı (donut + yüzde + tutar), en pahalı abonelikler. subscriptions-core stream + monthlyAmount tüketilir. Boş durum. ÖDEME GEÇMİŞİ YOK → trend kapsam dışı. Dark mode + Türkçe."

## Overview

A statistics screen that turns the user's current subscriptions into an at-a-glance picture of **where their money goes**: a total per period, a category breakdown (visual chart + figures), and the heaviest subscriptions. It is a snapshot of the **current** set of subscriptions (the app stores no payment history), normalized to a chosen period (monthly or yearly). Like the dashboard, amounts are grouped by currency — there is no conversion. Read-only; it consumes the existing subscription data and the monthly-normalization logic.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See spending broken down by category (Priority: P1) 🎯 MVP

The user opens statistics and sees, for the selected period, how their spending splits across categories (streaming, music, cloud, AI, …) — as a chart plus a list with each category's amount and percentage share. This reveals what dominates their spending.

**Why this priority**: The core value of the screen — understanding the shape of one's spending. Without the category breakdown there is no statistics feature.

**Independent Test**: Seed subscriptions across categories/periods; verify each category's normalized total and its percentage of the (per-currency) total are correct, and the chart segments match.

**Acceptance Scenarios**:

1. **Given** subscriptions in several categories, **When** statistics loads, **Then** each category shows its period-normalized total and percentage of the currency's total, summing to 100% per currency.
2. **Given** the breakdown, **When** rendered, **Then** the chart's category segments are proportional to those amounts, each with a stable category color matching its list row.
3. **Given** subscriptions in multiple currencies, **When** rendered, **Then** the breakdown does not mix currencies (per-currency totals/percentages; never a blended number).
4. **Given** a category with no subscriptions, **When** rendered, **Then** it does not appear in the breakdown.

---

### User Story 2 - Switch between monthly and yearly (Priority: P2)

The user toggles between a monthly and a yearly view; all totals and breakdowns recompute accordingly (yearly = monthly × 12).

**Why this priority**: People budget in both horizons; the yearly view reframes small monthly amounts into their real annual cost. Builds directly on US1.

**Independent Test**: With a fixed set, toggle monthly↔yearly and verify every figure scales by exactly 12 and labels update.

**Acceptance Scenarios**:

1. **Given** the monthly view, **When** the user switches to yearly, **Then** every total and category amount is exactly 12× the monthly figure.
2. **Given** either view, **When** displayed, **Then** the period is clearly labeled (aylık / yıllık) and the currency total reflects it.
3. **Given** a toggle change, **When** applied, **Then** percentages remain unchanged (period scaling does not change shares).

---

### User Story 3 - See the heaviest subscriptions (Priority: P3)

The user sees their most expensive subscriptions for the period (a ranked list, brand-colored), so they can spot the biggest line items quickly.

**Why this priority**: A useful "where to cut" cue, but secondary to the category overview.

**Independent Test**: Seed subscriptions with different amounts; verify the ranked list orders them by period-normalized amount (descending), within their currency.

**Acceptance Scenarios**:

1. **Given** several subscriptions, **When** the "top" list renders, **Then** they are ordered by period-normalized amount, highest first, showing brand + amount.
2. **Given** mixed currencies, **When** ranked, **Then** ranking does not compare across currencies (no cross-currency ordering implied as equivalent value).

---

### User Story 4 - Empty state (Priority: P3)

With no subscriptions, the screen shows a friendly empty state instead of blank charts.

**Independent Test**: Open statistics with zero subscriptions → empty state shown, no chart.

**Acceptance Scenarios**:

1. **Given** zero subscriptions, **When** statistics loads, **Then** an empty-state message is shown and no chart/percentages are rendered.
2. **Given** at least one subscription, **When** loaded, **Then** the empty state is not shown.

---

### Edge Cases

- **Single currency vs multiple**: one set of figures per currency; multiple currencies render as separate breakdowns/sections (no blending).
- **All in one category**: that category is 100%; chart is a full ring.
- **Loading / error**: a loading indication while data is read; a Turkish, non-technical message on failure (no wrong numbers).
- **Rounding**: displayed percentages are rounded but must visibly sum to ~100% (no misleading total from naive rounding where avoidable).
- **Past renewal dates**: irrelevant here — statistics use amount + period, not renewal dates (no rollover needed).
- **Large number of subscriptions**: chart + lists stay readable and performant.

## Requirements *(mandatory)*

### Functional Requirements

**Category breakdown**
- **FR-001**: The screen MUST compute, per currency, each category's total normalized to the selected period and its percentage share of that currency's total.
- **FR-002**: The screen MUST present the breakdown both as a chart (proportional category segments) and as a list of categories with amount + percentage.
- **FR-003**: Each category MUST have a stable, distinct color shared between its chart segment and its list row.
- **FR-004**: Categories with no subscriptions MUST be omitted; percentages within a currency MUST sum to 100% (within rounding).
- **FR-005**: Amounts MUST NOT be summed or compared across currencies (per-currency breakdowns).

**Period**
- **FR-006**: The screen MUST offer a monthly/yearly toggle; yearly figures MUST equal monthly × 12.
- **FR-007**: The selected period MUST be clearly labeled, and all totals/amounts MUST reflect it; percentages MUST be unaffected by the period.

**Totals & top list**
- **FR-008**: The screen MUST show the total spend for the selected period, grouped by currency (consistent with the dashboard summary).
- **FR-009**: The screen MUST show a ranked list of the most expensive subscriptions for the period (descending by normalized amount), with brand visuals, not mixing currencies in a single ranking.

**States & navigation**
- **FR-010**: The screen MUST update automatically when subscriptions change (reactive), with no manual refresh.
- **FR-011**: With no subscriptions, the screen MUST show an empty state (no chart/percentages).
- **FR-012**: The screen MUST show a loading indication while data loads and a Turkish, non-technical error message on failure.
- **FR-013**: The screen MUST be reachable from the dashboard (navigation entry) and render in dark mode with Turkish labels.
- **FR-014**: The screen MUST be read-only (no create/edit/delete).

### Key Entities *(include if feature involves data)*

- **Subscription (consumed)**: read from `subscriptions-core`; relevant: amount, currency, billing period, category, name, serviceKey.
- **Category Breakdown (derived, view-only)**: per currency, a list of (category, periodTotal, percentage) plus the currency total. Not persisted.
- **Ranked Subscription (derived, view-only)**: a subscription with its period-normalized amount, ordered descending within a currency.
- **Period**: monthly or yearly (display/normalization choice).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of category totals and percentages match a hand calculation across the test set (mixed categories/periods/currencies).
- **SC-002**: Percentages within each currency sum to 100% (±1% rounding) in 100% of cases.
- **SC-003**: Switching monthly↔yearly scales every amount by exactly 12 and leaves percentages unchanged.
- **SC-004**: No figure ever blends two currencies (0 cross-currency totals/rankings).
- **SC-005**: The screen reflects a subscription add/edit/delete within 1 second, no manual refresh.
- **SC-006**: With zero subscriptions, the empty state is shown 100% of the time (no chart).
- **SC-007**: A user can identify their largest spending category within 5 seconds of opening the screen.

## Assumptions

- **Snapshot, not history**: statistics reflect the current subscription set only; the app stores no payment history, so time-series/trend views are out of scope.
- **Reuses normalization**: the monthly-normalization rule (weekly×52/12, yearly÷12, monthly×1) is reused from the dashboard; yearly view = monthly × 12.
- **Per-currency grouping**: no conversion (consistent with dashboard); a unified-TRY view depends on the later currency-conversion feature.
- **Category set**: the existing categories (streaming, music, cloud, AI, productivity, shopping, other); each gets a fixed display color + Turkish label.
- **Navigation**: reachable from the dashboard (AppBar action or tab) — exact placement is a design detail.
- **Read-only / offline / single user.**

## Out of Scope (this feature)

- Spending trends / time-series / historical charts (no payment history stored).
- Currency conversion / unified-currency totals.
- CSV export, forecasting/projections, budgets/alerts.
- Editing subscriptions from this screen.
