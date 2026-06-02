# Feature Specification: Automatic Subscription Recognition (OCR Import)

**Feature Branch**: `009-subscription-import`

**Created**: 2026-06-02

**Status**: Draft

**Input**: User description: "Makbuz/ekran görüntüsü/App Store aboneliklerinden otomatik abonelik tanıma. On-device OCR (offline, ücretsiz) ile görüntü/PDF'ten metin çıkarır; saf Dart ayrıştırıcı marka katalogu + tutar/para birimi/tarih/periyot eşleştirir; kullanıcı onay/düzeltme ekranında taslakları doğrulayıp toplu kaydeder. App Store/Play okunamadığı için sistem abonelik ekranının ekran görüntüsü OCR ile okunur. Dark + Türkçe. Sıfır backend, LLM yok."

## Overview

Today, every subscription in Subsy is typed in by hand. This feature lets the user **point at a source — a screenshot, a photo of a receipt, a PDF invoice, or a screenshot of their phone's App Store/Play subscriptions list — and have Subsy recognize the subscription(s) for them**: the service, the amount, the currency, the billing period, and the next payment date. The user then **reviews and corrects** the recognized drafts on a confirmation screen and saves them in one step.

Recognition happens **entirely on the device**: the image/PDF is read with on-device text recognition and the resulting text is parsed by Subsy's own rules against its brand catalog. Nothing is uploaded, no external service is called, no AI/cloud API is used — so the feature is **fully offline, free, and preserves Subsy's "your data never leaves the device" promise**. Because phone platforms do not allow an app to read another app's store subscriptions directly, the App Store/Play case is handled by letting the user screenshot the system subscriptions screen and importing that image like any other.

Recognition is **best-effort and never silent**: the review/correct step is mandatory, so the user always confirms before anything is saved and can fix any field OCR got wrong.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Recognize a subscription from a screenshot or photo (Priority: P1) 🎯 MVP

A user has a screenshot of a payment confirmation (or takes a photo of a paper receipt). They open Subsy's import, pick the image, and Subsy recognizes the subscription — service, amount, currency, period, next date — and shows it as a draft. The user glances at it, fixes anything off, and saves. No typing from scratch.

**Why this priority**: This is the feature's core promise and the single biggest convenience win — turning a picture into a subscription. Every other source rides on the same image→text→parse→review pipeline, so this story alone is a viable, shippable MVP.

**Independent Test**: Provide a legible image containing one subscription's details; verify the system produces a draft with the service/brand, amount, currency, billing period, and a next-payment date pre-filled, and that confirming it creates a subscription identical to one entered manually.

**Acceptance Scenarios**:

1. **Given** a legible image showing a known service, amount, and date, **When** the user imports it, **Then** a draft appears pre-filled with the matched brand, amount, currency, billing period, and next-payment date.
2. **Given** a recognized draft, **When** the user confirms it without edits, **Then** a subscription is created using the same data model and validation as manual entry.
3. **Given** a service name that is not in the brand catalog, **When** the draft is shown, **Then** the recognized name is kept as plain text (no brand) and the user can still save it.
4. **Given** an image where some fields cannot be read, **When** the draft is shown, **Then** the unreadable fields are clearly marked as empty/uncertain for the user to complete.

---

### User Story 2 - Review and correct before saving (Priority: P1)

Before anything is saved, the user sees every recognized draft on a review screen, can edit any field, discard false positives, and confirm. This guarantees that imperfect recognition never results in silently wrong data and keeps the user in control.

**Why this priority**: OCR is never 100% accurate; without an explicit, editable confirmation step the feature would erode trust by saving wrong amounts or dates. The review step is what makes best-effort recognition safe to ship, so it is as critical as recognition itself.

**Independent Test**: From any recognized draft, verify the user can change each field (service, amount, currency, period, date, category), discard the draft, and that nothing is persisted until an explicit confirm action.

**Acceptance Scenarios**:

1. **Given** one or more recognized drafts, **When** the review screen is shown, **Then** nothing has been saved yet and a confirm action is required to persist.
2. **Given** a draft with a wrong amount, **When** the user edits the amount and confirms, **Then** the saved subscription reflects the edited value, not the recognized one.
3. **Given** a draft the user does not want, **When** they discard it, **Then** it is not saved and remaining drafts are unaffected.
4. **Given** a recognized draft that matches an existing subscription, **When** the review screen is shown, **Then** it is flagged as a possible duplicate and the user can skip it or add it anyway.

---

### User Story 3 - Import the App Store / Play subscriptions list (Priority: P2)

A user wants to bring in the subscriptions they pay for through the App Store / Google Play. Subsy guides them to open the system subscriptions screen, take a screenshot, and import it. Subsy recognizes the multiple services listed and presents each as its own draft to review.

**Why this priority**: A large share of subscriptions are billed through the stores, so this is a high-value source — but it depends on US1+US2 (it is an image import with batch handling) and on user guidance, so it follows the core flow.

**Independent Test**: Provide a screenshot resembling a store subscriptions list with several entries; verify each entry becomes a separate reviewable draft and the user can confirm or discard each independently.

**Acceptance Scenarios**:

1. **Given** the import flow, **When** the user chooses the App Store/Play option, **Then** Subsy explains it cannot read store subscriptions directly and guides them to screenshot the system subscriptions screen.
2. **Given** a screenshot listing several subscriptions, **When** it is imported, **Then** each recognized subscription appears as its own draft.
3. **Given** multiple drafts from one source, **When** the user confirms, **Then** only the confirmed (non-discarded) drafts are saved.

---

### User Story 5 - Premium gating (Priority: P2)

Auto-import is a premium capability. Free users who open the import flow see a clear locked teaser inviting them to upgrade — never a running scan — while manual entry stays free for everyone.

**Why this priority**: Monetization gate and honest behavior, mirroring how currency conversion and the home widget are gated. Required before release but secondary to the core recognition experience.

**Independent Test**: Toggle premium on/off; verify premium users can run the full import flow and free users get a locked teaser with no recognition and no saved import.

**Acceptance Scenarios**:

1. **Given** a free user, **When** they open auto-import, **Then** they see a locked teaser with an upgrade prompt and cannot run recognition or save an imported subscription.
2. **Given** a user who becomes premium, **When** they next open auto-import, **Then** the full import flow is available.
3. **Given** a premium user who downgrades, **When** they next open auto-import, **Then** it reverts to the locked teaser.

---

### User Story 4 - Import from a PDF receipt/invoice (Priority: P3)

A user has a PDF invoice (e.g., emailed receipt saved to files). They pick the PDF in the import flow and Subsy recognizes the subscription the same way it does for images.

**Why this priority**: Adds another common source to the same pipeline, but images/screenshots already cover the most frequent cases; PDF is an incremental convenience.

**Independent Test**: Provide a PDF containing a subscription's details; verify it produces a reviewable draft equivalent to importing the same content as an image.

**Acceptance Scenarios**:

1. **Given** a text-based PDF invoice, **When** the user imports it, **Then** Subsy recognizes the subscription details into a draft.
2. **Given** a scanned (image-only) PDF, **When** the user imports it, **Then** Subsy still attempts recognition from the page image and shows a draft or a clear "not recognized" result.

---

### Edge Cases

- **Unreadable / blurry / no text**: Subsy tells the user nothing could be read and offers manual entry; never saves a blank.
- **Text found but no subscription**: a non-subscription receipt or random screenshot yields a clear "no subscription recognized" result.
- **Partial recognition**: amount found but no date (or vice-versa) → draft is shown with the missing field flagged for completion.
- **Locale formats**: Turkish/European number format (comma decimal, e.g. `149,99`) vs. US format (`149.99`); currency as `₺`, `TL`, `TRY`, `$`, `USD`, `€`, `EUR`.
- **Multiple currencies in one source**: each draft keeps its own currency.
- **Duplicate**: a recognized draft matching an existing subscription is flagged; user chooses skip or add.
- **Brand not in catalog**: recognized name kept as plain text; no false brand attached.
- **Very long subscriptions list**: all recognized entries are shown as drafts (scrollable); none silently dropped.
- **Permission denied** (photos/camera): clear message with a way to retry or open settings.
- **Past/ambiguous date**: if the recognized date is in the past or only a day-of-month is found, the next-payment date is rolled forward consistent with the rest of the app, and flagged for the user to confirm.
- **Offline**: the entire flow works with no connectivity.
- **Free user**: opening auto-import shows a locked teaser only — no recognition runs and nothing is saved.

## Requirements *(mandatory)*

### Functional Requirements

**Sources & capture**
- **FR-001**: Users MUST be able to start an import by selecting an image from the photo library, taking a photo, or selecting a PDF.
- **FR-013**: System MUST provide an "App Store / Play subscriptions" path that explains store subscriptions cannot be read directly and guides the user to screenshot the system subscriptions screen, then processes that screenshot like any image.

**On-device recognition (offline)**
- **FR-002**: System MUST extract text from the selected image/PDF **entirely on-device**, with no network request and no third-party/cloud service, and MUST function fully offline.
- **FR-003**: System MUST parse the extracted text into one or more **draft subscriptions**, attempting to identify service/brand, amount, currency, billing period, and next-payment date.
- **FR-004**: System MUST match recognized service names against the existing **brand catalog** and attach the corresponding brand when confident; otherwise it MUST keep the raw recognized name with no brand.
- **FR-008**: System MUST support recognizing **multiple subscriptions from a single source** and present each as an independently reviewable draft.
- **FR-010**: System MUST handle Turkish and common international **number, date, and currency formats** (comma vs. dot decimal; `₺`/`TL`/`TRY`/`$`/`USD`/`€`/`EUR`).

**Review, correct, save**
- **FR-005**: System MUST present recognized drafts on a **review screen before anything is saved**; no subscription is persisted without an explicit user confirm action.
- **FR-006**: Users MUST be able to **edit every field** of each draft (service/brand, name, amount, currency, billing period, next-payment date, category) and **discard** any draft.
- **FR-007**: System MUST clearly **flag fields it could not confidently recognize** so the user can complete them.
- **FR-014**: System MUST detect when a recognized draft likely **duplicates an existing subscription** and let the user skip it or add it anyway.
- **FR-009**: On confirmation, System MUST create subscriptions using the **same data model and validation as manual entry**.

**Robustness & presentation**
- **FR-011**: System MUST behave gracefully when no text or no recognizable subscription is found — inform the user and offer manual entry — and MUST NOT save blank/garbage data.
- **FR-012**: System MUST request the OS permissions needed to pick images/take photos and handle denial with a clear message and a path to retry.
- **FR-015**: System MUST render all import/review screens in **dark mode with Turkish text**, consistent with the app.
- **FR-016**: Source images/PDFs MUST be processed **transiently** and MUST NOT be retained after the import completes.

**Access (premium-gated)**
- **FR-017**: The auto-import capability MUST be **premium-only**. Free users MUST see a clear locked teaser inviting them to upgrade and MUST NOT be able to run recognition or save imported subscriptions; premium users get full access. (Manual entry remains free for everyone.)
- **FR-018**: A change in premium status MUST be reflected the next time the user opens the import flow (premium → full access; downgrade → locked teaser).

### Key Entities *(include if feature involves data)*

- **Import Source**: the picked image, photo, or PDF the user selects. Transient input only; not stored after the import (FR-016).
- **Recognized Draft Subscription**: a derived candidate produced from the recognized text — a service/brand guess, recognized name, amount, currency, billing period, next-payment date, a per-field confidence/uncertain indicator, and a possible-duplicate flag. Exists only in the review screen until the user confirms or discards it; not user data leaving the device.
- **Subscription (created)**: on confirmation, reuses the `subscriptions-core` entity, model, and validation unchanged.
- **Brand catalog (consumed)**: the existing catalog used to match recognized names to known services.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a clearly legible single-subscription source, the user reaches a saved subscription in **under 30 seconds**, with only minor edits.
- **SC-002**: For a clearly legible source naming a service in the catalog, the system **correctly pre-fills service, amount, and currency in the majority of cases** (target ≥ 80%), reducing manual typing versus entering from scratch.
- **SC-003**: **No subscription is ever saved without an explicit user confirmation** (100% of imports).
- **SC-004**: The entire import flow **works with no network connectivity** (airplane mode) in 100% of cases; no data leaves the device.
- **SC-005**: From a subscriptions-list screenshot with multiple entries, **each entry appears as its own reviewable draft** (none silently merged or dropped).
- **SC-006**: The user can **correct any mis-recognized field** before saving (100% of fields editable).
- **SC-007**: Importing a recognized subscription requires the user to **enter fewer fields manually** than creating it from scratch (i.e., recognition pre-fills at least the service and amount in the common case).
- **SC-008**: Free users **never run a recognition or save an imported subscription**; a locked teaser appears in 100% of free-user import attempts.

## Assumptions

- **On-device only**: recognition uses on-device text recognition and Subsy's own parsing rules; **no cloud OCR and no LLM/AI API** — consistent with the zero-backend, offline CONSTITUTION (this preserves the "data never leaves the device" selling point and incurs no running cost).
- **Best-effort + mandatory review**: recognition is imperfect by nature, so the editable confirmation step is required; the feature optimizes for "fast, correctable" over "perfectly automatic".
- **Store subscriptions are not directly readable**: phone platforms do not expose other apps' store subscriptions to Subsy; the App Store/Play case is served by importing a screenshot of the system subscriptions screen.
- **Reuse**: created subscriptions reuse the `subscriptions-core` model/validation and the existing brand catalog; the next-payment roll-forward rule matches the rest of the app.
- **Transient sources**: imported images/PDFs are not persisted after the import.
- **Premium gate**: reuses the existing premium-status mechanism (as with currency conversion and the home widget); the purchase/paywall flow itself is the separate, deferred feature.
- **Single user / single device.**
- The on-device recognition capability may **raise the app's minimum OS version** and add some app size; this is an implementation trade-off addressed in planning, not a scope change.

## Out of Scope (this feature)

- Scanning the user's email inbox or any server-side parsing of receipts.
- Bank-statement aggregation / Open Banking / card-transaction reading.
- Reading other apps' store subscriptions via any private/undocumented API.
- Continuous or background automatic scanning (import is an explicit, user-initiated action).
- Training or shipping a custom machine-learning model; cloud OCR or AI/LLM-based extraction.
- The premium purchase/paywall flow itself (separate feature); this feature only consumes premium status if gated.
