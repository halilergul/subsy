# Feature Specification: First-Run Onboarding

**Feature Branch**: `010-onboarding`

**Created**: 2026-06-02

**Status**: Draft

**Input**: User description: "First-run onboarding flow: a 4-slide value/privacy/OCR/reminders carousel shown once on first launch, no login wall, an optional cross-platform sign-in for purchase restore, and notification-permission priming."

## Overview

The app currently drops a brand-new user straight onto an empty dashboard with no context about what Subsy is, why it keeps data on-device, or how to add subscriptions quickly. This feature introduces a short, skippable first-run onboarding that communicates the product's value and privacy stance, primes the notification permission at the right moment, and routes the user into adding their first subscription — **without** introducing an account or login wall.

Subsy is a 100% offline, zero-backend app (see CONSTITUTION). Onboarding reinforces that as a selling point rather than apologizing for the absence of accounts. Because there is no backend, premium entitlements are owned by the platform store (App Store / Google Play); onboarding sets honest expectations about how purchases restore, and offers an **optional** store sign-in purely so a user who switches platforms can carry their purchase — never as a gate, and never touching their subscription data.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See the onboarding once and reach the app (Priority: P1)

A first-time user opens Subsy and is shown a sequence of introduction slides explaining what the app does and that their data stays on their device. They can move forward through the slides, skip at any time, and on finishing they land in the app ready to add their first subscription. The next time they open the app, onboarding does not appear again.

**Why this priority**: Without this, there is no onboarding at all. It is the minimum viable slice — a user who only gets this story still receives orientation and a clean hand-off into the app, shown exactly once.

**Independent Test**: Launch the app with no prior history → onboarding appears. Advance or skip to the end → the dashboard appears. Relaunch → onboarding does not appear and the dashboard loads directly.

**Acceptance Scenarios**:

1. **Given** a fresh install with no completed onboarding, **When** the user opens the app, **Then** the first onboarding slide is shown instead of the dashboard.
2. **Given** the user is on any onboarding slide, **When** they tap "Atla" (skip), **Then** onboarding is dismissed and the dashboard is shown.
3. **Given** the user reaches the last slide, **When** they tap the final "Başla" action, **Then** onboarding is dismissed and the dashboard is shown.
4. **Given** the user has previously finished or skipped onboarding, **When** they reopen the app, **Then** the dashboard is shown directly and onboarding does not reappear.
5. **Given** the user is moving through slides, **When** they advance or go back, **Then** a progress indicator reflects the current slide position.

---

### User Story 2 - Be primed for notification permission at the right moment (Priority: P2)

On the slide about renewal reminders, the user is shown — in plain language — why notifications matter (so they are warned before a subscription renews) and is invited to enable them. If they accept, the system permission prompt is presented. If they decline or postpone, onboarding still completes normally and the app remains fully usable.

**Why this priority**: Renewal reminders are a core value of the app, and asking for the OS permission inside a meaningful context (rather than cold, or buried in settings) materially improves opt-in. But it must never block completion, so it is P2, layered on top of P1.

**Independent Test**: Reach the reminders slide → a soft pre-prompt with an "enable notifications" action and a "skip for now" action is shown. Choosing enable triggers the OS permission flow; choosing skip advances without it. Either path completes onboarding.

**Acceptance Scenarios**:

1. **Given** the user is on the reminders slide, **When** it is displayed, **Then** a soft explanation and two choices ("Bildirimleri aç" and "Şimdilik geç") are shown before any system permission dialog.
2. **Given** the user taps "Bildirimleri aç", **When** the action runs, **Then** the system notification-permission request is presented.
3. **Given** the user taps "Şimdilik geç", **When** the action runs, **Then** no system permission dialog is shown and onboarding can still be completed.
4. **Given** the user grants or denies the system prompt, **When** the result returns, **Then** onboarding completes and the app is fully usable regardless of the choice.
5. **Given** the user postponed during onboarding, **When** they later want reminders, **Then** they can still enable notifications from the existing notification settings.

---

### User Story 3 - Understand how purchases work, and optionally link them across platforms (Priority: P3)

The user learns that there is no account: their subscription data lives only on their device, and any premium purchase is tied to their store account and can be restored on another device of the same platform. A user who wants to carry premium to a different platform (e.g. iOS → Android) can optionally start a store sign-in that links only the purchase entitlement — clearly described as not syncing their data — or dismiss it and continue.

**Why this priority**: This sets correct expectations and avoids "I paid but lost it" confusion, and it offers a relief valve for the rare platform-switcher. It is valuable but not required for a usable first run, so it is P3. The actual sign-in mechanism depends on the premium/paywall feature shipping, so the surface is presented but its account linking is allowed to be deferred.

**Independent Test**: On the privacy slide, the no-account / store-bound purchase message is visible. The optional "cross-platform" surface can be opened and dismissed without affecting onboarding completion or local data.

**Acceptance Scenarios**:

1. **Given** the user is on the privacy slide, **When** it is displayed, **Then** it states that there is no account, data stays on the device, and premium is tied to the store account and restorable.
2. **Given** the user opens the optional cross-platform surface, **When** it is shown, **Then** it explains that signing in links only the purchase entitlement and not subscription data, and offers store sign-in choices plus a dismiss option.
3. **Given** the user dismisses the cross-platform surface, **When** they continue, **Then** onboarding proceeds unchanged and no local data is altered.
4. **Given** the premium/paywall capability is not yet available, **When** the user opens the cross-platform surface, **Then** they are shown an honest "available with Premium" state rather than a broken sign-in.

---

### Edge Cases

- **Resuming mid-onboarding**: If the app is closed on slide 2 and reopened before completion, onboarding restarts from the beginning (it has not been marked complete). It must not be considered "done" until the user explicitly skips or finishes.
- **Skip on the first slide**: Skipping on slide 1 still marks onboarding complete and goes to the app; it never traps the user.
- **Notification permission already granted/denied at OS level**: The soft pre-prompt still appears for context, but the priming respects the OS state — it does not crash or loop if the OS dialog cannot be shown again.
- **Re-showing onboarding intentionally**: A user can re-trigger the onboarding later from settings; doing so does not duplicate or corrupt the "completed" state once finished again.
- **Empty vs. existing data**: A returning user who already has subscriptions (e.g. restored from a device backup) but no completion flag should still be able to skip quickly into their populated dashboard.
- **Back navigation on the first slide**: Going back from slide 1 does nothing (no underflow) rather than exiting the app unexpectedly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST show the onboarding flow on first launch when onboarding has not been completed, before the dashboard is reachable.
- **FR-002**: The app MUST present the onboarding as an ordered sequence of four content slides covering, in order: (1) core value, (2) privacy / on-device data, (3) fast adding via document scan, (4) reminders and spending overview.
- **FR-003**: Users MUST be able to advance through slides and move back to a previous slide, with a visible progress indicator of their position.
- **FR-004**: Users MUST be able to skip the entire onboarding from any slide, which completes onboarding and opens the app.
- **FR-005**: The final slide MUST present a primary action that completes onboarding and opens the app.
- **FR-006**: The app MUST persist that onboarding has been completed so it is not shown again on subsequent launches.
- **FR-007**: Onboarding completion state MUST be stored on-device only, with no network dependency (consistent with the offline-first constitution).
- **FR-008**: The reminders slide MUST present a soft, in-context explanation of notifications with an explicit "enable" choice and a "skip for now" choice before any system permission dialog is shown.
- **FR-009**: Choosing "enable" on the reminders slide MUST trigger the platform notification-permission request; choosing "skip for now" MUST NOT show a system dialog.
- **FR-010**: Onboarding MUST complete and the app MUST be fully usable regardless of whether notification permission is granted, denied, or postponed.
- **FR-011**: The privacy slide MUST communicate that there is no account, that subscription data stays on the device, and that premium purchases are tied to the store account and restorable on another device of the same platform.
- **FR-012**: The app MUST offer an optional cross-platform purchase-linking surface that clearly states it links only the premium entitlement (not subscription data) and can be dismissed without consequence.
- **FR-013**: The app MUST NOT require any account creation, login, email, or sign-in to use any non-purchase functionality.
- **FR-014**: Users MUST be able to re-open the onboarding later from the app's settings.
- **FR-015**: All onboarding content MUST be presented in Turkish, consistent with the rest of the app.
- **FR-016**: When the premium capability is unavailable, the optional cross-platform surface MUST present an honest "available with Premium" state instead of a non-functional sign-in.

### Key Entities *(include if feature involves data)*

- **Onboarding Completion State**: A single on-device flag representing whether the user has finished (or skipped) the first-run onboarding. Attributes: completed (yes/no). No personal data, no identifiers, no timestamps required for v1.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time user can go from app launch to the dashboard via onboarding in under 30 seconds when reading at a normal pace, and in under 5 seconds when skipping.
- **SC-002**: Onboarding is shown exactly once — 100% of returning users who completed or skipped it reach the dashboard directly on subsequent launches.
- **SC-003**: Every onboarding slide can be skipped, and skipping always lands the user in a usable app (0 dead-ends across all slides).
- **SC-004**: The notification permission is requested only after the in-context pre-prompt, and the app remains fully functional in 100% of cases where permission is denied or postponed.
- **SC-005**: No onboarding path requires an account; a user can reach and use every non-purchase feature with zero sign-in steps.
- **SC-006**: A returning user can re-open onboarding from settings and complete it again without corrupting the completed state.

## Assumptions

- **Offline-first**: Onboarding has no network dependency; completion state and all content are local (CONSTITUTION: 100% offline, zero backend).
- **Single user per device**: There is no multi-profile concept; the completion flag is per-installation.
- **Premium/paywall lands separately**: The functional purchase and store sign-in mechanisms are owned by the premium/paywall feature (which ships last). This feature designs and presents the surfaces and wires the honest "available with Premium" fallback; full account-linking is deferred to when premium is available.
- **Notifications feature exists**: The notification-permission request and the settings entry to enable reminders later are provided by the existing notifications feature and are reused here.
- **Language**: Turkish UI only for v1; a light-mode visual variant is in scope for design parity even though dark mode is primary.
- **Design source**: Hi-fi visuals are produced via the existing design process (Claude Design) and skinned to match the established design system (gold accent, gradient panels, modal sheet system).
- **No content gating**: Onboarding never blocks access behind a purchase; the only purchase-related element is the optional, dismissible cross-platform surface.
