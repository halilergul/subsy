# Feature Specification: Subscriptions Core (Data Foundation)

**Feature Branch**: `001-subscriptions-core`

**Created**: 2026-06-01

**Status**: Draft

**Input**: User description: "Subscription veri modeli, local storage katmanı, repository, marka kataloğu (12 TR servisi + renk/logo), 5-abonelik free-tier kuralı. UI yok — sadece veri + repository + testler."

## Overview

This feature delivers the **data foundation** of Subsy: a persistent, on-device model of a user's subscriptions, the brand catalog that gives each subscription its real logo and brand color, and the free-tier business rule (max 5 subscriptions without premium). It is the base every later feature (dashboard, notifications, statistics, paywall) builds on.

**No user-facing screens are delivered in this feature.** Behavior is verified through the data/repository layer (automated tests). UI features consume this layer separately.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record and reliably keep a subscription (Priority: P1)

A user adds a subscription (e.g. "Netflix", ₺149.99, monthly, renews on the 15th). The record is stored entirely on the device and is still there — unchanged — after closing and reopening the app, with no account, login, or network required.

**Why this priority**: Without durable on-device storage, nothing else in the app can exist. This is the irreducible core and the product's central promise ("verileriniz cihazınızdan çıkmıyor").

**Independent Test**: Create a subscription through the repository, restart the storage layer (simulating an app restart), and confirm the record is retrieved identically. Fully testable without any UI.

**Acceptance Scenarios**:

1. **Given** an empty store, **When** a valid subscription is saved, **Then** it can be read back with every field identical and a stable unique identifier.
2. **Given** a stored subscription, **When** the storage layer is re-initialized (app restart), **Then** the subscription is still present and unchanged.
3. **Given** a stored subscription, **When** its amount and renewal date are updated, **Then** the changes persist and the identifier stays the same.
4. **Given** a stored subscription, **When** it is deleted, **Then** it can no longer be read back.
5. **Given** the device is fully offline, **When** any create/read/update/delete is performed, **Then** it succeeds (no network dependency).

---

### User Story 2 - Automatic brand recognition (Priority: P2)

When a user records a known service (e.g. "Spotify", "Exxen", "Claude Pro"), the subscription is automatically associated with that brand's real logo, official brand color, and a sensible default category — without the user picking anything. Recognition works for the curated catalog and tolerates common name variations and Turkish characters.

**Why this priority**: Real brand logos are the core of the premium feel (per the product brief). They must be guaranteed and offline for known services.

**Independent Test**: Look up catalog entries by service name (including alias and mixed-case / Turkish-character variants) and confirm the correct brand color, logo reference, and default category are returned. Confirm an unknown name returns a graceful "no match" result.

**Acceptance Scenarios**:

1. **Given** the brand catalog, **When** a known service name is resolved (e.g. "Netflix"), **Then** the matching brand color, logo reference, and default category are returned.
2. **Given** a name with different casing or Turkish characters (e.g. "exxen", "BLUTV", "İcloud"), **When** it is resolved, **Then** it still matches the correct catalog entry.
3. **Given** a common alias (e.g. "YouTube Premium" vs "YT Premium"), **When** it is resolved, **Then** it matches the intended entry.
4. **Given** an unknown service name, **When** it is resolved, **Then** a clear "no catalog match" result is returned (so a fallback can be applied later) without error.
5. **Given** the at-launch catalog, **When** its contents are inspected, **Then** all 12 mandatory Turkey-focused services are present with a brand color and logo reference.

---

### User Story 3 - Free-tier limit enforcement (Priority: P2)

A free (non-premium) user can store at most 5 subscriptions. Attempting to add a 6th is rejected with a clear, typed "limit reached" outcome. A premium user has no limit. Deleting a subscription frees a slot.

**Why this priority**: The freemium boundary is the monetization mechanism and must be enforced at the data layer so no UI path can bypass it.

**Independent Test**: With premium disabled, add 5 subscriptions (all succeed), attempt a 6th (rejected with a limit outcome), delete one, add again (succeeds). With premium enabled, add more than 5 (all succeed).

**Acceptance Scenarios**:

1. **Given** a free user with 4 subscriptions, **When** a 5th is added, **Then** it succeeds.
2. **Given** a free user with 5 subscriptions, **When** a 6th is added, **Then** it is rejected with a typed "limit reached" result and the store is unchanged.
3. **Given** a free user at the limit, **When** one subscription is deleted, **Then** a new one can be added successfully.
4. **Given** a premium user with 5 subscriptions, **When** more are added, **Then** they all succeed.
5. **Given** any user, **When** an existing subscription is edited (not added), **Then** the limit check does not block the edit.

---

### Edge Cases

- **Invalid amount**: zero, negative, or non-numeric amounts are rejected before storage with a validation error.
- **Missing required fields**: a subscription without name, amount, currency, billing period, or renewal date is rejected.
- **Renewal date in the past**: accepted and stored (the next-renewal computation is a separate concern); no rejection.
- **Unsupported currency**: a currency outside the supported set (TRY, USD, EUR) is rejected with a validation error.
- **Duplicate service**: a user may store two subscriptions for the same service (e.g. two Netflix plans); this is allowed and not deduplicated.
- **Catalog name collision**: if two catalog entries could match a name, resolution returns a single deterministic best match.
- **Very long name / notes**: input longer than the allowed limit is rejected with a validation error rather than truncated silently.
- **Storage unavailable**: if the local store cannot be opened or written, operations return a typed storage error with a Turkish user-facing message, never an uncaught crash.

## Requirements *(mandatory)*

### Functional Requirements

**Subscription record & persistence**
- **FR-001**: System MUST persist subscriptions entirely on the device, with no backend, account, or network dependency.
- **FR-002**: System MUST retain stored subscriptions across app restarts without data loss.
- **FR-003**: System MUST allow creating, reading, updating, and deleting a subscription, with each subscription having a stable unique identifier that does not change on update.
- **FR-004**: System MUST store, per subscription: service name, amount, currency, billing period (weekly / monthly / yearly), next renewal date, category, and an optional brand/service key linking to the catalog. Optional fields: start date and free-text notes.
- **FR-005**: System MUST record creation and last-update timestamps for each subscription.

**Validation**
- **FR-006**: System MUST reject subscriptions with a missing required field (name, amount, currency, billing period, renewal date) before storage.
- **FR-007**: System MUST reject a non-positive or non-numeric amount.
- **FR-008**: System MUST accept only currencies in the supported set: TRY, USD, EUR.
- **FR-009**: System MUST surface all validation and storage failures as typed, recoverable results carrying a Turkish, non-technical user message — never an uncaught exception.

**Brand catalog**
- **FR-010**: System MUST ship a built-in brand catalog, available fully offline, mapping known services to a display name, brand color, logo reference, and a default category.
- **FR-011**: The catalog MUST include at least these 12 services at launch: Spotify, Netflix, YouTube Premium, Apple TV+, iCloud+, ChatGPT Plus, Claude Pro, Exxen, Gain, BluTV, Trendyol Premium, Amazon Prime.
- **FR-012**: System MUST resolve a service name to a catalog entry case-insensitively and tolerant of Turkish characters (ı/İ/ş/ç/ğ/ö/ü) and common aliases.
- **FR-013**: System MUST return a clear "no match" result for unknown service names (enabling a later fallback) without raising an error.
- **FR-014**: When a known service is recorded, System MUST associate its catalog brand color, logo reference, and default category automatically.

**Free-tier limit**
- **FR-015**: System MUST limit a non-premium user to a maximum of 5 stored subscriptions.
- **FR-016**: System MUST reject creation beyond the free limit with a typed "limit reached" result, leaving the store unchanged.
- **FR-017**: System MUST impose no subscription count limit for premium users.
- **FR-018**: The limit MUST apply to net current count (deleting frees a slot) and MUST NOT block edits to existing subscriptions.

> Note: this feature consumes premium status as an injected/abstracted flag; the actual purchase flow (RevenueCat) is delivered by the separate `paywall` feature.

### Key Entities *(include if feature involves data)*

- **Subscription**: a service the user pays for. Attributes: unique id, service name, optional service key (catalog link), amount, currency (TRY/USD/EUR), billing period (weekly/monthly/yearly), next renewal date, category, optional start date, optional notes, created-at, updated-at.
- **Brand Catalog Entry**: a known service's branding. Attributes: service key, display name, brand color, logo reference (bundled asset), default category, name aliases. Read-only, bundled with the app.
- **Billing Period**: enumerated cadence — weekly, monthly, yearly.
- **Category**: classification of a subscription (e.g. streaming, music, cloud, AI, productivity, shopping, other) used later by statistics. Defaulted from the catalog when available; otherwise "other".

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of created subscriptions are retrievable identically after an app restart (zero data loss across the persistence test suite).
- **SC-002**: All create/read/update/delete operations succeed with the device fully offline (0 network calls in this layer).
- **SC-003**: All 12 mandatory services resolve to the correct brand color, logo, and default category, including at least 3 Turkish-character / casing / alias variants per the test set.
- **SC-004**: A non-premium user is blocked at exactly the 6th subscription in 100% of attempts; a premium user is never blocked.
- **SC-005**: 100% of invalid inputs (missing field, non-positive amount, unsupported currency) are rejected before storage with a typed error and no partial writes.
- **SC-006**: Any storage failure results in a typed error surfaced to the caller in 100% of cases — never an app crash.

## Assumptions

- **No UI in this feature**: dashboards, forms, and lists are out of scope here and delivered by separate features (`dashboard`, `subscriptions` presentation, `statistics`). This feature's acceptance is verified at the data/repository layer.
- **Category included now**: a `category` field is part of the data model from the start (defaulted from the catalog, falling back to "other"), so the later statistics feature needs no migration. Category management UI is out of scope here.
- **Supported currencies**: TRY, USD, EUR for v1 (USD/EUR exist to support the later TRY-conversion feature). Other currencies are rejected.
- **Premium status is injected**: this feature treats "is premium" as an abstracted boolean provided by another layer; it does not implement purchasing. Default in absence of the paywall feature is non-premium (free tier).
- **Logo fallback is later**: for services not in the catalog, the online-fetch + cache + initial-letter fallback is handled by a later logo feature; here, an unknown service simply returns "no catalog match".
- **Amounts**: stored as the user-entered value in the subscription's own currency; conversion to TRY is a separate feature.
- **Single user / single device**: no multi-user, sharing, or cross-device sync (per constitution anti-goals).

## Out of Scope (this feature)

- Any screen, form, or visual component.
- Renewal-date scheduling / "upcoming payments" computation and notifications.
- Currency conversion and exchange-rate fetching.
- The RevenueCat purchase flow and premium unlocking.
- Online logo fetching and caching; CSV export; widget; calendar sync.
