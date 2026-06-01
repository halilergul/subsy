# Feature Specification: Dashboard (Home Screen)

**Feature Branch**: `002-dashboard`

**Created**: 2026-06-01

**Status**: Draft

**Input**: User description: "Dashboard (ana ekran) — aylık toplam özet (para birimine göre gruplu), yaklaşan ödemeler listesi (tarihe göre sıralı, marka renkli kartlar), boş durum + ekleme CTA'sı, geçmiş yenileme tarihleri için sonraki dönem hesabı. Sadece okuma + navigasyon; ekleme/düzenleme ekranı kapsam dışı."

## Overview

The dashboard is Subsy's first visible screen and the app's home. It answers two questions at a glance: **"What am I paying soon?"** (an upcoming-payments list) and **"How much am I spending per month?"** (a monthly total summary). It is read-only: it consumes the subscription data from `subscriptions-core` and offers navigation actions (e.g. an "add subscription" button) but does not itself create or edit subscriptions. Dark mode is mandatory; each subscription is shown with its real brand color and logo.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See upcoming payments at a glance (Priority: P1) 🎯 MVP

A user opens the app and immediately sees a list of their subscriptions ordered by when the next payment is due — soonest first — each as a brand-colored card showing the service logo, name, amount, and how soon it renews ("3 gün sonra", "Bugün", or a date). When a stored renewal date has already passed, the card shows the next upcoming occurrence (rolled forward by the billing period), not the stale past date.

**Why this priority**: The core reason to open the app — knowing what is about to be charged. Delivers value on its own even before the summary exists.

**Independent Test**: Seed subscriptions with various renewal dates (past, today, soon, far) and billing periods; open the dashboard; verify order (soonest effective renewal first), the relative-time label, and that past dates roll forward correctly.

**Acceptance Scenarios**:

1. **Given** several subscriptions with different renewal dates, **When** the dashboard loads, **Then** they appear sorted by effective next renewal date, soonest first.
2. **Given** a subscription whose stored renewal date is in the past, **When** it is shown, **Then** the displayed next renewal is the next future occurrence based on its billing period (weekly/monthly/yearly).
3. **Given** a subscription renewing today, **When** it is shown, **Then** its label reads "Bugün"; renewing tomorrow → "Yarın"; otherwise "N gün sonra" (or a date beyond a threshold).
4. **Given** a subscription for a known brand, **When** its card renders, **Then** it uses that brand's color and logo; for an unknown brand it uses a neutral placeholder (initial + default color).
5. **Given** the user adds, edits, or deletes a subscription elsewhere, **When** that change occurs, **Then** the dashboard list updates automatically without a manual refresh.
6. **Given** a very long service name, **When** the card renders, **Then** the name is truncated gracefully without breaking the layout.

---

### User Story 2 - Understand monthly spend, grouped by currency (Priority: P2)

A user sees a summary of how much they spend per month. Because subscriptions can be in different currencies and there is no conversion yet, the summary shows a **separate monthly total per currency** (e.g. "₺450 / ay" and "$12 / ay"). Weekly and yearly subscriptions are normalized to a monthly figure.

**Why this priority**: The second key question ("how much am I spending?"). Builds on the same data; valuable but secondary to seeing what's due.

**Independent Test**: Seed subscriptions across periods and currencies; verify each currency's monthly-normalized total is correct and shown as its own line; verify no cross-currency summing occurs.

**Acceptance Scenarios**:

1. **Given** subscriptions in a single currency with mixed periods, **When** the summary renders, **Then** it shows one monthly total equal to the sum of each item normalized to monthly.
2. **Given** subscriptions in multiple currencies, **When** the summary renders, **Then** each currency has its own monthly total line and amounts are never summed across currencies.
3. **Given** a weekly subscription, **When** normalized, **Then** its monthly contribution is its amount × (52 ÷ 12); **Given** a yearly one, **Then** its amount ÷ 12; **Given** monthly, **Then** its amount unchanged.
4. **Given** no subscriptions in a currency, **When** the summary renders, **Then** that currency does not appear.

---

### User Story 3 - Empty state guides the first action (Priority: P3)

A user with no subscriptions sees a friendly empty state — a visual placeholder and a clear call-to-action to add their first subscription — instead of a blank screen.

**Why this priority**: Polish for first-run experience; the app is usable without it but feels incomplete.

**Independent Test**: Open the dashboard with zero subscriptions; verify the empty-state visual and the add CTA appear, and the summary/list are not rendered as empty boxes.

**Acceptance Scenarios**:

1. **Given** zero subscriptions, **When** the dashboard loads, **Then** an empty-state illustration/message and an "add subscription" CTA are shown.
2. **Given** the empty state, **When** the user taps the add CTA, **Then** the app navigates toward the add-subscription flow (the destination screen is out of scope for this feature).
3. **Given** at least one subscription, **When** the dashboard loads, **Then** the empty state is not shown.

---

### Edge Cases

- **Loading**: while subscription data is being read, the dashboard shows a non-jarring loading state, not a flash of empty state.
- **Read failure**: if the data layer returns an error, the dashboard shows a Turkish, non-technical message rather than crashing or showing wrong totals.
- **All subscriptions in the past**: every card rolls forward to its next occurrence; ordering still correct.
- **Single subscription**: list and summary render correctly with one item.
- **Large list**: many subscriptions scroll smoothly (performance budget below).
- **Same renewal date for multiple items**: deterministic, stable secondary ordering (e.g. by name).
- **Unknown brand**: neutral placeholder; no broken/missing image.

## Requirements *(mandatory)*

### Functional Requirements

**Upcoming payments list**
- **FR-001**: The dashboard MUST display all stored subscriptions in a single list ordered by effective next renewal date, soonest first.
- **FR-002**: For a subscription whose stored renewal date is in the past, the dashboard MUST compute and display the next future occurrence based on its billing period (weekly/monthly/yearly).
- **FR-003**: Each list item MUST show the service name, amount with its currency, and a human-friendly time-to-renewal ("Bugün", "Yarın", "N gün sonra", or a date past a threshold).
- **FR-004**: Each list item MUST use the matched brand's color and logo; for an unmatched service it MUST use a neutral placeholder (initial + default color).
- **FR-005**: Items with the same effective renewal date MUST have a stable, deterministic secondary order (by name).
- **FR-006**: Long service names MUST be truncated without breaking layout.

**Monthly summary**
- **FR-007**: The dashboard MUST show a monthly spend total computed by normalizing every subscription to a monthly amount (weekly × 52/12, yearly ÷ 12, monthly × 1).
- **FR-008**: The summary MUST group totals by currency and MUST NOT sum amounts across different currencies.
- **FR-009**: A currency with no subscriptions MUST NOT appear in the summary.

**Reactivity, states, navigation**
- **FR-010**: The dashboard MUST update automatically when subscriptions change (add/edit/delete), without a manual refresh.
- **FR-011**: When there are no subscriptions, the dashboard MUST show an empty state with an add-subscription call-to-action.
- **FR-012**: The dashboard MUST provide a navigation action toward the add-subscription flow (destination screen out of scope here).
- **FR-013**: The dashboard MUST show a loading indication while data is being read and a Turkish, non-technical error message if reading fails.
- **FR-014**: The dashboard MUST be read-only — it MUST NOT create, edit, or delete subscriptions.
- **FR-015**: The dashboard MUST render in dark mode.

### Key Entities *(include if feature involves data)*

- **Subscription (consumed)**: read from `subscriptions-core`; relevant attributes here are name, amount, currency, billing period, next renewal date, service key (for brand), category.
- **Monthly Currency Total (derived, view-only)**: per-currency sum of monthly-normalized amounts. Not persisted.
- **Upcoming Payment Item (derived, view-only)**: a subscription plus its computed effective next renewal date and relative-time label. Not persisted.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On opening the app, a user can identify their next due payment within 5 seconds (it is at the top of the list).
- **SC-002**: 100% of monthly-normalized per-currency totals match a hand calculation across the test set (weekly/monthly/yearly mix, multiple currencies).
- **SC-003**: 100% of subscriptions with a past stored renewal date display a future effective renewal date.
- **SC-004**: Amounts are never summed across currencies in any scenario (0 cross-currency totals).
- **SC-005**: The dashboard reflects an add/edit/delete change within 1 second, with no manual refresh.
- **SC-006**: With 100+ subscriptions, scrolling stays smooth (no visible jank on a mid-range device).
- **SC-007**: With zero subscriptions, the empty state (not a blank screen) is shown 100% of the time.

## Assumptions

- **Consumes `subscriptions-core`**: relies on its reactive subscription stream and brand catalog; no new persistence is introduced.
- **No currency conversion**: per-currency grouping only; converting foreign amounts to a single TRY total is a later premium feature. The summary intentionally shows separate lines.
- **Monthly normalization factor**: weekly = amount × (52 ÷ 12 ≈ 4.333). Documented so the math is unambiguous.
- **Relative-time threshold**: beyond ~30 days the item shows an absolute date instead of "N gün sonra" (exact threshold is a presentation detail finalized in design).
- **Logo fallback**: a real logo/color for catalog-matched services; a neutral initial-based placeholder for unmatched ones (the online-fetch fallback is a separate later feature).
- **Add/edit screens out of scope**: the add CTA only navigates; the destination is built in a later feature.
- **Single user / offline**: same constraints as the rest of the app.

## Out of Scope (this feature)

- Creating, editing, or deleting subscriptions (add/edit screens).
- Currency conversion / exchange rates / a unified TRY total.
- Notifications and reminder scheduling.
- Statistics / charts (category breakdowns) — a separate feature.
- Online logo fetching; CSV export; widget; calendar sync; paywall.
