# Feature Specification: Renewal Reminder Notifications

**Feature Branch**: `004-notifications`

**Created**: 2026-06-01

**Status**: Draft

**Input**: User description: "Bildirimler — abonelik yenileme hatırlatmaları. Yerel bildirim, offline. X gün önce hatırlatma. Global tek ön-süre ayarı (varsayılan 3 gün). Küçük ayarlar ekranı (aç/kapa + ön-süre + saat, varsayılan 10:00). Efektif yenileme tarihinden X gün önce tetiklenir; ekle/düzenle/sil ve ayar değişiminde yeniden zamanlanır; izin istenir."

## Overview

Subsy reminds the user before each subscription renews, so they are never surprised by a charge. Reminders are **local, on-device notifications** — no server, no push, fully offline (consistent with the product's core promise). The user controls reminders from a small settings screen: turn them on/off, choose how many days before renewal to be reminded (one global value, default 3), and the time of day (default 10:00). When subscriptions change or settings change, reminders are rescheduled automatically. Basic reminders are available to all users (free tier).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Be reminded before a renewal (Priority: P1) 🎯 MVP

With reminders on, the user receives a local notification a set number of days before each subscription's next renewal, at the chosen time. The notification names the service and when/what is due, so they can act (keep, cancel, budget) before being charged.

**Why this priority**: This is the feature's entire purpose — timely, offline reminders. Without scheduling against renewals, nothing else matters.

**Independent Test**: With reminders on (lead = N days, time = T), schedule for a set of subscriptions and verify each has a pending reminder at (effective next renewal − N days) at time T, naming the service; verify none in the past.

**Acceptance Scenarios**:

1. **Given** reminders are on with lead N days and time T, **When** scheduling runs for a subscription, **Then** a reminder is set for (its effective next renewal − N days) at T, titled/bodied with the service name and amount.
2. **Given** a subscription whose stored renewal date is in the past, **When** scheduling runs, **Then** the reminder is based on the effective (rolled-forward) next renewal, not the stale date.
3. **Given** a computed reminder time that is already in the past (e.g. renewal is sooner than N days away), **When** scheduling runs, **Then** no past-dated reminder is created (it is skipped, not fired immediately).
4. **Given** multiple subscriptions, **When** scheduling runs, **Then** each has its own independent reminder and they do not overwrite each other.

---

### User Story 2 - Control reminders from settings (Priority: P1)

The user opens a settings screen and turns reminders on/off, sets the lead time (days before), and the time of day. Changes take effect immediately (reminders reschedule).

**Why this priority**: "User configures it" is an explicit product requirement; reminders are only useful if the user can tune or silence them. Tightly coupled with US1 (both P1 for a usable feature).

**Independent Test**: Change each setting and verify it persists across app restart and that reminders are rescheduled to match (or all cleared when turned off).

**Acceptance Scenarios**:

1. **Given** the settings screen, **When** the user toggles reminders off, **Then** all scheduled reminders are cancelled and none fire.
2. **Given** reminders off, **When** the user toggles them on, **Then** reminders are scheduled for all current subscriptions per the current lead/time.
3. **Given** the user changes the lead days or time, **When** saved, **Then** existing reminders are rescheduled to the new values.
4. **Given** any settings change, **When** the app is restarted, **Then** the chosen settings are still in effect (persisted on-device).
5. **Given** the settings screen, **When** opened, **Then** it shows the current on/off state, lead days, and time.

---

### User Story 3 - Reminders stay in sync with changes (Priority: P2)

When the user adds, edits, or deletes a subscription, its reminder is created, updated, or removed accordingly — without the user doing anything extra.

**Why this priority**: Keeps reminders correct over time. Important, but US1+US2 already deliver value; this guarantees they stay accurate.

**Independent Test**: Add a subscription → a reminder appears; edit its renewal date/amount → the reminder updates; delete it → its reminder is removed.

**Acceptance Scenarios**:

1. **Given** reminders on, **When** a subscription is added, **Then** a reminder is scheduled for it.
2. **Given** an existing reminder, **When** the subscription's renewal date or amount changes, **Then** the reminder is rescheduled to match.
3. **Given** an existing reminder, **When** the subscription is deleted, **Then** its reminder is cancelled.

---

### User Story 4 - Permission handling (Priority: P2)

The app asks for notification permission when reminders are first enabled. If permission is denied or unavailable, the user is clearly informed (reminders won't fire) and pointed to system settings; the app does not crash or pretend reminders are active.

**Why this priority**: Without permission, reminders silently fail; the user must understand why. Secondary to the core scheduling but needed for a trustworthy experience.

**Independent Test**: Simulate granted vs denied permission; verify reminders schedule when granted, and a clear message + no false "on" state when denied.

**Acceptance Scenarios**:

1. **Given** reminders are being enabled for the first time, **When** the user is prompted, **Then** the OS permission request is shown.
2. **Given** permission is denied, **When** the user enables reminders, **Then** a clear Turkish message explains reminders can't fire and offers a path to system settings; the UI does not claim reminders are working.
3. **Given** permission is granted, **When** reminders are on, **Then** scheduling proceeds normally.

---

### Edge Cases

- **Renewal sooner than lead time**: the computed reminder is in the past → skip (never fire immediately / never schedule past).
- **Reminders off**: no reminders exist; toggling on (re)creates them; toggling off clears all.
- **Many subscriptions**: each gets an independent, correctly-timed reminder; no collisions or overwrites.
- **Lead = 0**: reminder on the renewal day itself at the chosen time.
- **Permission revoked later (in OS settings)**: app reflects that reminders won't fire and does not show a false "on" state when it can detect this.
- **Device time / timezone**: reminders fire at the chosen local time of day; daylight-saving changes do not misfire by a day.
- **Duplicate scheduling**: re-running scheduling does not create duplicate reminders for the same subscription.
- **App reinstall / data cleared**: settings reset to defaults; no orphan reminders persist.

## Requirements *(mandatory)*

### Functional Requirements

**Scheduling**
- **FR-001**: The system MUST schedule a local, on-device reminder for each subscription at (its effective next renewal date − lead days) at the configured time of day, with no network/server.
- **FR-002**: The effective next renewal MUST be the rolled-forward future date for past stored dates (same logic as the dashboard), not the stale stored date.
- **FR-003**: If a computed reminder time is in the past, the system MUST skip it (no immediate/past notification).
- **FR-004**: Each subscription MUST have its own reminder; scheduling MUST NOT overwrite or collide reminders across subscriptions.
- **FR-005**: Re-running scheduling MUST NOT create duplicate reminders for the same subscription.
- **FR-006**: Each reminder MUST identify the service (name) and the upcoming charge (amount/date) in its content, in Turkish.

**Settings**
- **FR-007**: The system MUST provide a settings screen to: enable/disable reminders, set lead days (one global value, default 3), and set the time of day (default 10:00).
- **FR-008**: Settings MUST persist on-device across app restarts.
- **FR-009**: Turning reminders off MUST cancel all scheduled reminders; turning on MUST schedule them for all current subscriptions.
- **FR-010**: Changing lead days or time MUST reschedule existing reminders to the new values.

**Sync with subscriptions**
- **FR-011**: Adding a subscription MUST schedule its reminder (when reminders are on).
- **FR-012**: Editing a subscription's renewal date or amount MUST reschedule its reminder.
- **FR-013**: Deleting a subscription MUST cancel its reminder.

**Permission**
- **FR-014**: The system MUST request notification permission when reminders are first enabled.
- **FR-015**: If permission is denied/unavailable, the system MUST inform the user (Turkish, with a path to system settings) and MUST NOT present reminders as active.

**Constraints**
- **FR-016**: Reminders MUST work fully offline (no server/push).
- **FR-017**: Basic reminders MUST be available in the free tier (not premium-gated).
- **FR-018**: Settings UI MUST render in dark mode with Turkish labels.

### Key Entities *(include if feature involves data)*

- **Notification Settings (persisted)**: enabled (bool), leadDays (int, default 3), timeOfDay (hour/minute, default 10:00). Single global record, on-device.
- **Scheduled Reminder (derived/transient)**: per subscription — a stable identity tied to the subscription, a fire time = effective renewal − leadDays at timeOfDay, and content (service name + amount/date). Managed by the OS scheduler; not separately persisted by the app beyond what the scheduler holds.
- **Subscription (consumed)**: read from `subscriptions-core`; relevant: id (reminder identity), name, amount, currency, billing period, next renewal date.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of subscriptions with a future (renewal − lead) get exactly one correctly-timed pending reminder; 0 duplicates after repeated scheduling.
- **SC-002**: 100% of reminders are based on the effective (rolled-forward) renewal date; 0 reminders scheduled in the past.
- **SC-003**: Toggling reminders off cancels 100% of pending reminders; toggling on restores them for all current subscriptions.
- **SC-004**: Settings (on/off, lead, time) persist across restart in 100% of cases.
- **SC-005**: A subscription add/edit/delete reflects in its reminder within the same app session, with no manual action.
- **SC-006**: When permission is denied, the app never shows a false "reminders on and working" state; the user is informed in 100% of such cases.
- **SC-007**: Reminders fire at the chosen local time of day (±a few minutes, OS-dependent), not off by a day across daylight-saving boundaries.

## Assumptions

- **Built on `subscriptions-core` + dashboard renewal logic**: reuses the subscription stream and the effective-next-renewal computation; no new subscription rules.
- **Global lead time** (one value for all subscriptions), default **3 days**; per-subscription lead time is explicitly out of scope (a possible later enhancement).
- **Default time of day 10:00** local; user-adjustable.
- **Settings persisted on-device** (same offline philosophy); exact storage mechanism is a plan decision.
- **One reminder per subscription** for the next renewal (not a full recurring series pre-scheduled); rescheduling on app open / changes keeps the next one accurate.
- **Free tier**: basic reminders included; richer premium reminder options (if any) are out of scope here.
- **Single user / single device.**

## Out of Scope (this feature)

- Per-subscription custom lead times; multiple reminders per subscription.
- Push / server-driven notifications; calendar sync.
- Rich notification actions (snooze, mark-paid, deep buttons) beyond opening the app.
- Premium gating of reminders; statistics; currency conversion.
