# Feature Specification: Subscription Form (Add / Edit / Delete)

**Feature Branch**: `003-subscription-form`

**Created**: 2026-06-01

**Status**: Draft

**Input**: User description: "Abonelik ekleme/düzenleme ekranı — dashboard'un 'Abonelik ekle' CTA'sının hedefi. Form: isim, tutar, para birimi, dönem, yenileme tarihi (+ opsiyonel kategori/başlangıç/not), canlı marka önizleme, validation, free-tier limit mesajı. Düzenleme modu (var olan aboneliği önceden doldurur) ve silme (onaylı). subscriptions-core'daki Add/Update/Delete use case'lerini kullanır."

## Overview

This feature is the create/edit surface for subscriptions — the destination of the dashboard's "add" call-to-action and of tapping a subscription card to edit it. A single form screen handles both **add** and **edit** modes; the edit mode also offers **delete** (with confirmation). The form validates input, shows a **live brand preview** (logo + color) as the user types a known service name, and surfaces the free-tier limit clearly when a free user tries to exceed it. It builds entirely on `subscriptions-core`'s existing `AddSubscription` / `UpdateSubscription` / `DeleteSubscription` use cases and brand resolver; it adds no new persistence.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add a new subscription (Priority: P1) 🎯 MVP

From the dashboard's add CTA, the user opens a form, enters a service name, amount, currency, billing period, and next renewal date, and saves. The subscription is stored and the user returns to the dashboard, where it now appears. As they type a known service name (e.g. "Netflix"), the form previews that brand's logo and color.

**Why this priority**: Without the ability to add subscriptions, the rest of the app has no data. This is the primary write path and completes the core loop (add → see on dashboard).

**Independent Test**: Open the add form, fill valid values, save; confirm a subscription is persisted with the right fields and the form closes back to the dashboard.

**Acceptance Scenarios**:

1. **Given** the add form, **When** the user enters a valid name, amount, currency, period, and date and taps save, **Then** the subscription is stored and the form closes.
2. **Given** the user is typing a known service name, **When** the name matches the brand catalog, **Then** the form shows that brand's logo and color preview; for an unknown name it shows a neutral preview.
3. **Given** an invalid field (empty name, non-positive amount, etc.), **When** the user tries to save, **Then** a clear Turkish message is shown next to/about the offending field and nothing is saved.
4. **Given** a free (non-premium) user who already has 5 subscriptions, **When** they try to save a 6th, **Then** a clear "limit reached" message is shown (pointing toward premium) and nothing is saved.
5. **Given** a successful save, **When** the user returns to the dashboard, **Then** the new subscription appears in the list/summary without a manual refresh.
6. **Given** the form, **When** the user cancels/dismisses it, **Then** nothing is saved and they return without changes.

---

### User Story 2 - Edit an existing subscription (Priority: P2)

The user opens an existing subscription (e.g. by tapping its card) in the form, which is pre-filled with current values. They change fields and save; the subscription is updated in place.

**Why this priority**: Subscriptions change (price hikes, plan changes). Editing keeps data accurate. Reuses the same form.

**Independent Test**: Open a stored subscription in edit mode, change the amount and date, save; confirm the same record is updated (same identity) with new values and the dashboard reflects them.

**Acceptance Scenarios**:

1. **Given** an existing subscription, **When** it is opened in edit mode, **Then** every field is pre-filled with its current values and the brand preview reflects the current service.
2. **Given** edited valid values, **When** the user saves, **Then** the same subscription (same identity) is updated and the dashboard reflects the change.
3. **Given** an edit, **When** the user changes the name to another known brand, **Then** the brand preview and stored brand association update accordingly.
4. **Given** the edit form, **When** the user makes a field invalid and saves, **Then** a Turkish validation message is shown and no change is persisted.
5. **Given** editing (not adding), **When** the user saves, **Then** the free-tier limit does NOT block the save (editing is always allowed).

---

### User Story 3 - Delete a subscription (Priority: P2)

From the edit form, the user deletes a subscription. They are asked to confirm; on confirmation the subscription is removed and they return to the dashboard, where it no longer appears.

**Why this priority**: Users cancel services; removing them keeps totals honest and frees a free-tier slot.

**Independent Test**: Open a subscription in edit mode, delete, confirm; verify it is removed and the dashboard no longer shows it.

**Acceptance Scenarios**:

1. **Given** the edit form, **When** the user taps delete, **Then** a confirmation prompt is shown before anything is removed.
2. **Given** the confirmation, **When** the user confirms, **Then** the subscription is removed and the form closes to the dashboard.
3. **Given** the confirmation, **When** the user cancels it, **Then** nothing is removed.
4. **Given** a deletion that frees a free-tier slot, **When** the user next adds a subscription, **Then** the add succeeds.

---

### Edge Cases

- **Add mode has no delete**: the delete action appears only in edit mode.
- **Unsaved changes on dismiss**: leaving the form discards changes (no silent save); a confirm-discard prompt is a nice-to-have, not required.
- **Amount input**: rejects empty, zero, negative, and non-numeric; accepts decimals (e.g. 149,99 / 149.99).
- **Long name / notes**: enforced to the same limits as the data layer; over-limit input is rejected with a message.
- **Date in the past**: allowed (the renewal computation handles it); not blocked.
- **Storage error on save/delete**: a Turkish, non-technical error message is shown; the user is not dropped into an inconsistent state.
- **Optional fields left empty**: category defaults from the brand (else "other"); start date and notes may be empty.

## Requirements *(mandatory)*

### Functional Requirements

**Form & fields**
- **FR-001**: The form MUST collect: service name, amount, currency (TRY/USD/EUR), billing period (weekly/monthly/yearly), and next renewal date as required fields; and optionally category, start date, and notes.
- **FR-002**: Currency and billing period MUST be chosen from constrained pickers (only valid values selectable).
- **FR-003**: The next renewal date MUST be chosen via a date picker.
- **FR-004**: As the user types the service name, the form MUST show a live brand preview (logo + color) when it matches a known brand, and a neutral preview otherwise.
- **FR-005**: Category MAY be auto-filled from the matched brand and overridable by the user; when no brand/category is chosen it defaults to "other".

**Save / validation / limit**
- **FR-006**: On save in add mode, the form MUST create the subscription via the existing add path (which enforces validation, brand enrichment, and the free-tier limit).
- **FR-007**: Validation failures MUST be shown as clear Turkish, field-relevant messages, and MUST prevent saving; no partial data is stored.
- **FR-008**: When a free user is at the limit, saving a new subscription MUST show a clear "limit reached" message that points toward premium, and MUST NOT store anything.
- **FR-009**: A storage failure during save MUST show a Turkish, non-technical error and leave data consistent.

**Edit / delete**
- **FR-010**: The form MUST support an edit mode pre-filled with an existing subscription's values, updating the same record (preserving its identity) on save.
- **FR-011**: Editing MUST NOT be blocked by the free-tier limit.
- **FR-012**: The form MUST offer delete only in edit mode, and MUST require explicit confirmation before removing.
- **FR-013**: After a successful add/edit/delete, the user MUST return to the previous screen and the dashboard MUST reflect the change without manual refresh.

**Navigation & states**
- **FR-014**: The dashboard's add CTA (button and empty-state CTA) MUST navigate to the form in add mode; tapping a subscription on the dashboard MUST open it in edit mode.
- **FR-015**: Cancelling/dismissing the form MUST discard changes and store nothing.
- **FR-016**: The form MUST render in dark mode and use Turkish labels throughout.

### Key Entities *(include if feature involves data)*

- **Subscription (created/updated/deleted)**: the record this feature writes, via `subscriptions-core`. Fields per the core data model.
- **Form draft (transient)**: the in-progress field values bound to inputs; validated and converted into the subscription on save. Not persisted until save.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can add a typical subscription (name, amount, currency, period, date) in under 30 seconds.
- **SC-002**: 100% of invalid inputs are rejected at save time with a field-relevant Turkish message and zero partial writes.
- **SC-003**: 100% of saves/edits/deletes are reflected on the dashboard within 1 second, with no manual refresh.
- **SC-004**: A free user at 5 subscriptions is blocked from adding a 6th in 100% of attempts, with a clear message; editing existing ones is never blocked.
- **SC-005**: For known services, the correct brand preview (logo + color) appears as the name is typed in at least the 12 catalog brands.
- **SC-006**: Deletion requires confirmation in 100% of cases (no single-tap destructive delete).

## Assumptions

- **Built on `subscriptions-core`**: uses the existing `AddSubscription` (validation + brand enrichment + limit), `UpdateSubscription`, `DeleteSubscription`, and brand resolver; no new persistence or rules are introduced here.
- **Single form for add + edit**: one screen with two modes, opened as a pushed route from the dashboard.
- **Premium prompt is light**: the limit message points toward premium, but the actual purchase flow is the separate `paywall` feature; here it is informational.
- **Category UI**: a simple optional picker defaulting from the brand; full category management is out of scope.
- **Amount entry**: accepts decimal input; locale-friendly decimal separator handling is a presentation detail finalized in design.
- **Discard confirmation**: dismissing discards changes; an "unsaved changes" guard is optional polish, not required for v1.
- **Offline / single user**: same constraints as the rest of the app.

## Out of Scope (this feature)

- The RevenueCat purchase flow / unlocking premium (separate `paywall` feature).
- Currency conversion, notifications, statistics, CSV export, widget, calendar sync.
- Bulk add/import; duplicate detection/merging.
- Online logo fetching for unknown brands (separate later feature).
