# Feature Specification: Currency Conversion (Premium)

**Feature Branch**: `006-currency-conversion`

**Created**: 2026-06-01

**Status**: Draft

**Input**: User description: "Döviz çevirisi (premium) — per-currency gruplarını koruyarak birleşik tek toplam. Kur kaynağı frankfurter API + cache (cache-first, offline'da son bilinen kur + güncelleme tarihi). Hedef birim kullanıcı seçer (TRY/USD/EUR, varsayılan TRY), ayarlarda saklanır. Dashboard + istatistik + abonelik formunda gösterilir. Premium feature. KAPSAM DIŞI: kripto, manuel kur, geçmiş kur trendi, periyodik arka plan senkronu."

## Overview

Today the app groups spending strictly by currency (TRY, USD, EUR) and never blends them — honest, but it leaves the user without a single answer to "how much do I spend in total?". This feature adds an **optional, premium** unified total: every subscription's amount is converted to **one currency the user chooses** (default TRY) using up-to-date exchange rates, and shown as a single figure **alongside** the existing per-currency groups (which remain unchanged). Conversion appears on the dashboard, in statistics, and as a live preview while adding/editing a subscription.

Consistent with the product's core promise (**fully offline, zero backend**), exchange rates are the *only* network traffic: rates are fetched from a free public rate source when the device is online, **cached on-device**, and reused when offline. No personal or subscription data ever leaves the device — only an anonymous request for public exchange rates. When offline with cached rates, conversion still works and the screen shows when rates were last updated. Conversion is a **premium** capability; free users keep the per-currency view and see an upsell where the unified total would appear.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See one unified spending total (Priority: P1) 🎯 MVP

A premium user opens the dashboard and, in addition to the per-currency monthly totals, sees a single combined total in their chosen currency (default TRY) — e.g. "Toplam ≈ ₺1.240,50 / ay". This finally answers "what do I spend in total?" across mixed-currency subscriptions.

**Why this priority**: The unified total is the entire reason for this feature. Without converting mixed currencies into one comparable number, nothing else matters.

**Independent Test**: With a premium user, seed subscriptions in multiple currencies and a known set of rates; verify the unified total equals the sum of each subscription's converted, period-normalized amount, rounded for display, and is clearly marked approximate (≈).

**Acceptance Scenarios**:

1. **Given** a premium user with subscriptions in TRY, USD, and EUR and known rates, **When** the dashboard loads, **Then** a single unified total in the target currency is shown, equal to the sum of each subscription's monthly-normalized amount converted at the current rate.
2. **Given** the unified total, **When** displayed, **Then** it is marked as approximate (e.g. "≈") and the per-currency groups remain visible and unchanged.
3. **Given** subscriptions all already in the target currency, **When** converted, **Then** the unified total equals the plain per-currency total (no rate applied, no drift).
4. **Given** rates are available, **When** the unified total renders, **Then** the "rates last updated" time is available to the user.

---

### User Story 2 - Choose the target currency (Priority: P2)

The user opens settings and picks the currency the unified total is expressed in (TRY, USD, or EUR; default TRY). The choice persists across restarts and every converted figure updates to match.

**Why this priority**: A unified total is only meaningful in the currency the user thinks in; a USD-centric user needs USD. Builds directly on US1 but US1 is usable with the TRY default alone.

**Independent Test**: Change the target currency; verify all converted totals re-express in the new currency immediately and the choice survives an app restart.

**Acceptance Scenarios**:

1. **Given** the settings screen, **When** the user selects a target currency, **Then** all unified totals across the app re-express in that currency.
2. **Given** a chosen target currency, **When** the app is restarted, **Then** the same target currency is still in effect (persisted on-device).
3. **Given** no explicit choice has ever been made, **When** conversion is shown, **Then** the default target currency is TRY.

---

### User Story 3 - Unified view in statistics (Priority: P2)

In the statistics screen, the premium user sees — alongside the existing per-currency breakdowns — a unified total in the target currency and a unified category breakdown (categories summed across currencies after conversion), scaled by the selected monthly/yearly period.

**Why this priority**: Statistics is where "where does my money go" is answered; a single converted total + category split makes cross-currency spending finally comparable. Secondary to the dashboard total.

**Independent Test**: Seed mixed-currency subscriptions across categories with known rates; verify the unified category amounts equal converted, period-scaled sums and the unified total equals their sum; per-currency sections still present.

**Acceptance Scenarios**:

1. **Given** a premium user in statistics, **When** the screen loads, **Then** a unified total in the target currency is shown in addition to the per-currency sections.
2. **Given** the unified view, **When** rendered, **Then** each category's unified amount is the sum of its subscriptions converted to the target currency and scaled to the period, and percentages sum to 100%.
3. **Given** the monthly/yearly toggle, **When** switched, **Then** the unified figures scale by exactly 12 just like the per-currency figures; percentages unchanged.

---

### User Story 4 - Live converted preview in the form (Priority: P3)

While adding or editing a subscription in a currency other than the target, the premium user sees an inline, live preview of the converted amount (e.g. entering "$9.99" shows "≈ ₺338,40"), so they grasp the real cost in their own currency as they type.

**Why this priority**: A helpful at-the-moment cue, but the totals (US1/US3) carry the core value; the form preview is a convenience.

**Independent Test**: In the form, enter an amount in a non-target currency with known rates; verify the live preview shows the converted, approximate value and updates as amount/currency change; hidden when the chosen currency equals the target.

**Acceptance Scenarios**:

1. **Given** a premium user entering an amount in a non-target currency, **When** the amount or currency changes, **Then** an approximate converted preview in the target currency updates live.
2. **Given** the chosen currency equals the target currency, **When** entering an amount, **Then** no conversion preview is shown (nothing to convert).
3. **Given** no rates are available at all (never fetched, offline), **When** entering a non-target amount, **Then** the preview is omitted rather than showing a wrong or zero value.

---

### User Story 5 - Premium gating and offline honesty (Priority: P2)

Free users keep the full per-currency experience but see the unified-total area as a locked teaser with a clear premium upsell. For premium users, conversion works offline from cached rates, clearly indicating how fresh those rates are; if rates have never been fetched, the app is honest about it rather than showing wrong numbers.

**Why this priority**: Monetization gate plus trustworthy behavior. The feature must not silently show stale/wrong figures or pretend to work without rates.

**Independent Test**: Toggle premium on/off and rate availability (fresh / cached-only / none); verify the locked teaser for free users, the working converted totals with a freshness indicator for premium, and an honest "rates unavailable" state when no rates exist.

**Acceptance Scenarios**:

1. **Given** a free user, **When** any conversion surface is shown, **Then** the per-currency view remains fully functional and the unified total is replaced by a locked teaser with a premium call-to-action — never the real converted number.
2. **Given** a premium user who is offline with previously cached rates, **When** conversion is shown, **Then** it uses the cached rates and indicates when they were last updated.
3. **Given** a premium user with no cached rates and no connectivity, **When** conversion would be shown, **Then** a clear, non-technical Turkish message explains the unified total is unavailable until rates can be fetched (the per-currency view is unaffected).
4. **Given** a premium user who comes back online, **When** rates are refreshed, **Then** converted figures and the freshness indicator update to the newer rates.

---

### Edge Cases

- **Target currency == subscription currency**: that subscription contributes its amount with no rate applied (factor 1.0); no rounding drift.
- **All subscriptions already in target currency**: unified total equals the single per-currency total exactly.
- **Rates unavailable (never fetched + offline)**: unified surfaces show an honest "unavailable" state; per-currency view unaffected; form preview omitted.
- **Stale rates**: conversion still shown from cache, with a "last updated" indication; never blocks the per-currency view.
- **Rate fetch fails while a cache exists**: silently keep using the cache (with its timestamp); no error blocking the screen.
- **A currency missing from the fetched rate set**: subscriptions in that currency are excluded from the unified total, and the user is informed the total is partial (no silent wrong number).
- **Premium lost (downgrade)**: conversion surfaces revert to the locked teaser; no converted numbers shown.
- **Rounding**: the unified total is displayed rounded and marked approximate (≈); summation is done before rounding to avoid per-item rounding drift.
- **Period scaling (statistics)**: unified figures scale ×12 for yearly exactly like per-currency figures; percentages unchanged.

## Requirements *(mandatory)*

### Functional Requirements

**Conversion & rates**
- **FR-001**: The system MUST convert each subscription's period-normalized amount from its own currency to a single target currency and present the sum as one unified total, in addition to (never replacing) the existing per-currency totals.
- **FR-002**: The system MUST obtain exchange rates from a free public exchange-rate source over the network, requesting only public rate data (no personal or subscription data transmitted).
- **FR-003**: The system MUST cache the most recently fetched rates on-device and use them to convert when offline (cache-first; the app keeps working offline).
- **FR-004**: When a subscription's currency equals the target currency, the system MUST apply a factor of 1.0 (no conversion, no drift).
- **FR-005**: The system MUST display the unified total as an approximate value (clearly marked, e.g. "≈") and round only for display, summing before rounding to avoid per-item drift.
- **FR-006**: The system MUST make the "rates last updated" time available wherever a unified total is shown.
- **FR-007**: If a currency present in the user's subscriptions is missing from the available rates, the system MUST exclude it from the unified total and inform the user the total is partial (never a silent wrong figure).

**Target currency**
- **FR-008**: The system MUST let the user choose the target currency among the supported currencies (TRY, USD, EUR), defaulting to TRY.
- **FR-009**: The target currency choice MUST persist on-device across app restarts.
- **FR-010**: Changing the target currency MUST update every converted figure across the app.

**Display surfaces**
- **FR-011**: The dashboard MUST show the unified total (for premium users) alongside the per-currency monthly summary.
- **FR-012**: The statistics screen MUST show a unified total and a unified category breakdown (categories summed across currencies after conversion) alongside the per-currency sections, scaled by the selected monthly/yearly period; percentages MUST sum to 100% and be period-invariant.
- **FR-013**: The subscription add/edit form MUST show a live converted preview when the chosen currency differs from the target currency, updating as amount/currency change, and hide it when they are equal or no rates exist.

**Premium gating**
- **FR-014**: Currency conversion MUST be a premium capability; free users MUST retain the full per-currency experience and see a locked teaser with a premium call-to-action instead of the unified total — never the real converted number.
- **FR-015**: If the user is not premium (including downgrade), no converted figures MUST be shown on any surface.

**States & constraints**
- **FR-016**: When premium but no rates are available (never fetched and offline), the system MUST show an honest, non-technical Turkish "unavailable" state for unified surfaces, leaving the per-currency view unaffected; the form preview MUST be omitted.
- **FR-017**: All conversion UI MUST render in dark mode with Turkish labels and update reactively when subscriptions, rates, target currency, or premium status change.
- **FR-018**: Conversion MUST never alter, sum, or blend the existing per-currency figures; those remain exactly as today.

### Key Entities *(include if feature involves data)*

- **Exchange Rates (cached)**: a base currency, a set of rate factors to the supported currencies, and the timestamp the rates were fetched. Stored on-device; the only network-sourced data. Not personal.
- **Target Currency (persisted setting)**: the single currency the unified total is expressed in (TRY/USD/EUR; default TRY). Single global value, on-device.
- **Unified Total (derived/transient)**: the sum of all subscriptions' period-normalized amounts converted to the target currency; approximate; not persisted.
- **Unified Category Breakdown (derived/transient)**: per-category sums after conversion to the target currency, with percentages; not persisted.
- **Subscription (consumed)**: read from `subscriptions-core`; relevant: amount, currency, billing period, category.
- **Premium Status (consumed)**: whether conversion is unlocked.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For any seeded set of subscriptions and known rates, the unified total equals the hand-calculated sum of converted, period-normalized amounts (rounded for display) in 100% of cases.
- **SC-002**: Subscriptions already in the target currency contribute with no rate applied; an all-target-currency set yields a unified total exactly equal to its per-currency total (0 drift).
- **SC-003**: Converted figures work offline from cached rates in 100% of cases where a cache exists; the per-currency view never breaks regardless of rate availability.
- **SC-004**: The target currency choice persists across restart in 100% of cases and re-expresses all unified figures within the same session when changed.
- **SC-005**: Free users never see a real converted number; a premium upsell appears in its place in 100% of free-user sessions.
- **SC-006**: When no rates are available, the app shows an honest "unavailable" state and never a wrong/zero unified total (0 misleading figures).
- **SC-007**: Switching monthly↔yearly scales the unified total and unified category amounts by exactly 12 and leaves percentages unchanged.
- **SC-008**: No personal or subscription data is transmitted; the only outbound request is for public exchange rates.

## Assumptions

- **Built on existing logic**: reuses the subscription stream, monthly normalization, and the statistics aggregator; conversion is an added layer, not a change to per-currency rules.
- **Supported currencies** remain TRY, USD, EUR (the app's existing set); conversion is among these only.
- **Free public rate source** (keyless, no registration) providing rates relative to a base, refreshed roughly daily by the source; the app fetches on launch/when online and caches — no periodic background sync.
- **Rates refresh opportunistically** (on app open / when online); the app does not run scheduled background jobs for rates (out of scope).
- **Conversion is approximate** and clearly marked; it is a guideline figure, not an accounting/settlement value.
- **Premium gate** reuses the existing premium-status seam (the same mechanism used elsewhere); the actual purchase flow is the separate paywall feature.
- **Offline-first preserved**: the only network traffic is the anonymous public rate fetch; all user data stays on-device (consistent with CONSTITUTION.md).
- **Single user / single device.**

## Out of Scope (this feature)

- Cryptocurrencies or any currency beyond TRY/USD/EUR.
- User-defined / manual exchange rates.
- Historical rate trends or charts; showing how totals changed over time.
- Scheduled/periodic background rate synchronization (refresh is opportunistic only).
- The premium purchase/paywall flow itself (separate feature); this feature only consumes premium status.
- Editing subscriptions from conversion surfaces beyond the existing form preview.
