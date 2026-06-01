# Feature Specification: Home Screen Widget (Premium)

**Feature Branch**: `008-home-widget`

**Created**: 2026-06-01

**Status**: Draft

**Input**: User description: "Ana ekran widget'ı (premium) — sıradaki ödeme + aylık toplam. Mevcut subscription/dashboard/conversion verisini tüketir; abonelik/kur değişince reaktif tazelenir. Android App Widget + iOS WidgetKit; dokununca uygulama açılır; free kullanıcıda kilitli durum. Dark + Türkçe. Offline (cihazdaki cache'i okur). Native render cihazda doğrulanır."

## Overview

Subsy users glance at their home screen far more often than they open an app. This feature puts the **one thing that matters next** — the upcoming subscription renewal — plus the **monthly total** directly on the phone's home screen, so users never get surprised by a charge and always sense their spend without launching the app. The widget is a **read-only mirror** of data the app already computes: the next payment (brand, name, when, amount) and the monthly total (grouped by currency; the premium unified total when available). It refreshes automatically when subscriptions or rates change. It works **fully offline** — the widget only reads data already stored on the device. The widget is a **premium** capability; free users see a locked teaser inviting them to upgrade. Tapping the widget opens the app.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Glance at the next payment (Priority: P1) 🎯 MVP

A premium user adds the Subsy widget to their home screen and sees, without opening the app, their soonest upcoming renewal: the service's brand, its name, when it renews ("3 gün sonra"), and the amount. This is the feature's core promise — never be surprised by a charge.

**Why this priority**: The single most valuable at-a-glance fact is "what am I about to be charged, and when." Without it the widget has no reason to exist.

**Independent Test**: With a set of subscriptions, verify the widget's data payload names the subscription whose effective next renewal is soonest, with its brand, a correct relative-day label, and its amount; verify it matches what the dashboard shows.

**Acceptance Scenarios**:

1. **Given** a premium user with several subscriptions, **When** the widget renders, **Then** it shows the subscription with the soonest effective next renewal — brand, name, relative-day label, and amount — consistent with the dashboard's top upcoming item.
2. **Given** a subscription whose stored renewal date is in the past, **When** the widget computes "next payment", **Then** it uses the effective (rolled-forward) date, not the stale one (same rule as the dashboard).
3. **Given** the widget is showing a payment, **When** the user taps it, **Then** the app opens.

---

### User Story 2 - See the monthly total (Priority: P1)

Below the next payment, the premium user sees their monthly total. Amounts are grouped by currency (consistent with the app); when the premium currency conversion is active and rates exist, a single unified approximate total is also shown.

**Why this priority**: "How much am I spending" is the second half of the at-a-glance value and pairs naturally with the next payment in one compact widget. Both are P1 for a useful first widget.

**Independent Test**: With mixed-currency subscriptions, verify the widget payload's monthly total matches the dashboard summary (per currency), and the unified ≈ total appears only when conversion data is available.

**Acceptance Scenarios**:

1. **Given** subscriptions in one or more currencies, **When** the widget renders, **Then** it shows the monthly total grouped by currency, equal to the dashboard's monthly summary.
2. **Given** premium conversion with available rates, **When** the widget renders, **Then** it also shows a single unified ≈ total in the target currency.
3. **Given** no usable rates, **When** the widget renders, **Then** it shows only the per-currency totals (no wrong/blank unified figure).

---

### User Story 3 - Stay in sync automatically (Priority: P2)

When the user adds, edits, or deletes a subscription — or the exchange rates refresh — the widget updates on its own, with no manual action, so it never shows stale information.

**Why this priority**: A home-screen surface that drifts out of date erodes trust. Important, but US1+US2 already deliver the core value on first render.

**Independent Test**: Change the subscription set (add/edit/delete) and trigger a rate refresh; verify the widget's stored payload is recomputed to match the new state within the same app session.

**Acceptance Scenarios**:

1. **Given** the widget is on the home screen, **When** a subscription is added/edited/deleted, **Then** the widget's content updates to reflect the change.
2. **Given** the widget shows a unified total, **When** rates refresh or the target currency changes, **Then** the widget's figures update accordingly.
3. **Given** the last subscription is deleted, **When** the widget updates, **Then** it shows a friendly empty state (no payment, no total).

---

### User Story 4 - Premium gating (Priority: P2)

The widget's real figures are a premium capability. Free users who add the widget see a clear locked teaser inviting them to upgrade — never real amounts.

**Why this priority**: Monetization gate and honest behavior; mirrors how conversion is gated. Secondary to the core experience but required before release.

**Independent Test**: Toggle premium on/off; verify real data for premium and a locked teaser (no real numbers) for free, in both the payload and the rendered widget.

**Acceptance Scenarios**:

1. **Given** a free user, **When** the widget renders, **Then** it shows a locked teaser with an upgrade prompt and no real payment/total figures.
2. **Given** a user who becomes premium, **When** the widget next updates, **Then** it shows the real next payment and total.
3. **Given** a premium user who downgrades, **When** the widget updates, **Then** it reverts to the locked teaser.

---

### Edge Cases

- **No subscriptions**: widget shows a friendly empty state (e.g. "Abonelik ekle"), no payment/total.
- **Renewal in the past**: effective (rolled-forward) date is used, never a stale/negative day count.
- **Multiple currencies**: monthly total shown per currency; unified ≈ total only when conversion is available and the user is premium.
- **Premium but no rates**: per-currency total shown; no unified figure.
- **Free user**: locked teaser only; never real figures.
- **Offline**: widget renders entirely from on-device data; no network needed.
- **App not recently opened**: widget shows the last computed data; it refreshes when the app next runs or its data changes (no background server).
- **Tap target**: tapping anywhere on the widget opens the app.
- **Long service names / large amounts**: text is truncated/sized so the compact widget stays readable.

## Requirements *(mandatory)*

### Functional Requirements

**Content**
- **FR-001**: The widget MUST show the subscription with the soonest effective next renewal — brand, name, a relative-day label, and amount — consistent with the dashboard's upcoming list (FR reuses the effective-renewal rule).
- **FR-002**: The widget MUST show the monthly total grouped by currency, consistent with the dashboard's monthly summary.
- **FR-003**: When premium conversion is active and rates are available, the widget MUST also show a single unified approximate total in the target currency; otherwise it MUST omit it (never a wrong/blank unified figure).
- **FR-004**: With no subscriptions, the widget MUST show a friendly empty state and no payment/total.

**Sync & freshness**
- **FR-005**: The widget content MUST update automatically when subscriptions are added, edited, or deleted, with no manual action.
- **FR-006**: The widget content MUST update when exchange rates refresh or the target currency changes.
- **FR-007**: The widget MUST read only from on-device data and MUST function fully offline (no network/server for the widget itself).

**Premium gating**
- **FR-008**: The widget's real figures MUST be premium-only; free users MUST see a locked teaser with an upgrade prompt and MUST NOT see real payment/total figures.
- **FR-009**: A change in premium status MUST be reflected on the next widget update (premium → real data; downgrade → locked teaser).

**Interaction & presentation**
- **FR-010**: Tapping the widget MUST open the app.
- **FR-011**: The widget MUST render in a dark style with Turkish text, visually consistent with the app.
- **FR-012**: The widget MUST be available on both major mobile platforms (Android and iOS).

### Key Entities *(include if feature involves data)*

- **Widget Payload (derived, shared to the widget)**: a small, on-device snapshot the widget renders — next payment (brand key, name, relative-day label, amount, currency), monthly totals (per currency), optional unified total (amount + target currency), premium flag, and an empty/locked indicator. Not user data leaving the device; written to a shared on-device store the widget reads.
- **Subscription (consumed)**: read from `subscriptions-core`; relevant: brand/serviceKey, name, amount, currency, billing period, next renewal date.
- **Monthly total / unified total (consumed)**: reuses the dashboard monthly summary and the currency-conversion unified total.
- **Premium status (consumed)**: gates the real content.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The widget's "next payment" matches the dashboard's soonest upcoming item (same subscription, relative-day label, and amount) in 100% of cases.
- **SC-002**: The widget's monthly total equals the dashboard's monthly summary (per currency) in 100% of cases; the unified ≈ total appears only when conversion data is available.
- **SC-003**: After a subscription add/edit/delete (or rate refresh), the widget reflects the change within the same app session, with no manual action.
- **SC-004**: Free users never see a real figure on the widget; a locked teaser appears in 100% of free-user cases.
- **SC-005**: The widget renders its last-known content with no network connectivity in 100% of cases.
- **SC-006**: Tapping the widget opens the app in 100% of cases.
- **SC-007**: A user can identify their next charge (service + when) from the widget within 3 seconds, without opening the app.

## Assumptions

- **Mirrors existing logic**: reuses the subscription stream, the dashboard's effective-next-renewal + monthly-summary logic, and the currency-conversion unified total; the widget introduces no new spending rules.
- **One compact widget size** for v1 (next payment + monthly total); additional sizes/layouts are out of scope.
- **Refresh is opportunistic**: the widget's data is recomputed and pushed whenever the app runs or its underlying data changes; there is no background server or scheduled server push (consistent with the offline, zero-backend philosophy).
- **Premium gate** reuses the existing premium-status mechanism; the purchase flow itself is the separate paywall feature.
- **Native rendering** of the widget (platform widget UI) is verified on a real device/simulator; the data pipeline that feeds it is the part validated automatically.
- **Single user / single device.**

## Out of Scope (this feature)

- Interactive widget actions beyond tap-to-open (e.g. mark-paid, cancel, quick-add).
- Multiple widget sizes/layouts and per-widget configuration.
- Lock-screen / complications / live-activity surfaces.
- A background server or push mechanism to update the widget while the app is closed (beyond what the OS does with the last-stored data).
- The premium purchase/paywall flow itself (separate feature); this feature only consumes premium status.
