---
description: "Task list for Automatic Subscription Recognition (OCR Import)"
---

# Tasks: Automatic Subscription Recognition (OCR Import, Premium)

**Input**: Design documents from `/specs/009-subscription-import/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Included — the plan mandates pure unit tests for the parser and helpers (the feature's "intelligence"), consistent with the project's TDD pattern. UI/native/PDF are device-verified.

**Organization**: Grouped by user story (spec.md priorities). MVP = US1 + US2 (recognize → review/save).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1..US5 per spec.md
- Exact file paths included

## Path Conventions

- Flutter app, feature-first: `lib/features/subscription_import/{domain,data,application,presentation}`, tests in `test/unit/` and `test/support/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependencies, scaffolding, and native config for OCR import (MVP needs only ML Kit + image_picker).

- [X] T001 Add `google_mlkit_text_recognition` and `image_picker` to `pubspec.yaml` dependencies and run `flutter pub get`
- [X] T002 [P] Create the feature directory scaffold `lib/features/subscription_import/{domain,data,application,presentation,presentation/widgets}` (empty placeholder dirs/files as needed)
- [X] T003 [P] Raise iOS deployment target 13.0 → 16.0 in `ios/Podfile` (uncomment/set `platform :ios, '16.0'`) and `ios/Runner.xcodeproj/project.pbxproj` (all three `IPHONEOS_DEPLOYMENT_TARGET` entries)
- [X] T004 [P] Add Turkish permission usage strings `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` to `ios/Runner/Info.plist`
- [X] T005 [P] Declare the camera feature (`<uses-feature android:name="android.hardware.camera" android:required="false"/>`) for image_picker capture in `android/app/src/main/AndroidManifest.xml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared transient value types + the OCR service seam that every story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T006 [P] Create `OcrText` value (`lines`, `raw`) in `lib/features/subscription_import/domain/ocr_text.dart`
- [X] T007 [P] Create `RecognitionConfidence` + `RecognizedDraft` (nullable fields, `serviceKey`, `duplicateOf`) in `lib/features/subscription_import/domain/recognized_draft.dart`
- [X] T008 [P] Define the `OcrService` interface (`recognizeImage(Uint8List)`, `recognizePdf(Uint8List)`) in `lib/features/subscription_import/domain/ocr_service.dart`
- [X] T009 Create `ocrServiceProvider` (throwing stub, forces main override) in `lib/features/subscription_import/application/subscription_import_providers.dart`
- [X] T010 [P] Add `FakeOcrService` (canned / empty / throwing, records call count) to `test/support/fakes.dart`

**Checkpoint**: Value types + service seam ready — user stories can begin.

---

## Phase 3: User Story 1 - Recognize a subscription from a screenshot/photo (Priority: P1) 🎯 MVP

**Goal**: Pick an image → on-device OCR → pure parser produces draft(s) → user can save. A thin, complete vertical slice.

**Independent Test**: Feed a legible single-subscription image (via `FakeOcrService` text in tests; real image on device) → a draft pre-filled with brand/amount/currency/period/date appears; confirming creates a subscription identical to manual entry.

### Tests for User Story 1 (write first, ensure they FAIL)

- [X] T011 [P] [US1] `AmountParser` tests (₺/TL/TRY/$/€, `1.234,56` vs `1,234.56`, null cases) in `test/unit/amount_parser_test.dart`
- [X] T012 [P] [US1] `DateParser` tests (`dd.MM.yyyy`, `dd/MM/yyyy`, ISO, Turkish month names, period keywords, past/day-only roll-forward with injected `now`) in `test/unit/date_parser_test.dart`
- [X] T013 [P] [US1] `BrandTextMatcher` tests (catalog scan, alias, Turkish-char normalization e.g. `İCLOUD+`→icloud_plus, no-match → empty) in `test/unit/brand_text_matcher_test.dart`
- [X] T014 [P] [US1] `SubscriptionParser` tests (single receipt fixture, partial/no-date, unknown brand → raw name, garbage → empty) in `test/unit/subscription_parser_test.dart`
- [X] T015 [P] [US1] `ImportController` tests with `FakeOcrService` (canned text → `review` with expected draft; empty → `noResult`; throw → `error`; `confirmAll` → `AddSubscription`, `savedCount`) in `test/unit/import_controller_test.dart`

### Implementation for User Story 1

- [X] T016 [P] [US1] Implement `AmountParser` (money + currency extraction, both decimal conventions) in `lib/features/subscription_import/domain/amount_parser.dart`
- [X] T017 [P] [US1] Implement `DateParser` (`parseDate({now})` + `parsePeriod`, TR/EN months, roll-forward) in `lib/features/subscription_import/domain/date_parser.dart`
- [X] T018 [US1] Implement `BrandTextMatcher` (`findIn(text) → List<BrandMatch>`, reuses `kBrandCatalog` + `BrandResolver` normalization) in `lib/features/subscription_import/domain/brand_text_matcher.dart`
- [X] T019 [US1] Implement `SubscriptionParser.parse(OcrText)` (single-draft path: brand anchor + nearest amount/date/period + confidence flags) in `lib/features/subscription_import/domain/subscription_parser.dart` (depends on T016–T018)
- [X] T020 [US1] Implement `MlkitOcrService.recognizeImage` (bytes → `InputImage` → on-device recognition → `OcrText`, dispose recognizer) in `lib/features/subscription_import/data/mlkit_ocr_service.dart`
- [X] T021 [US1] Implement `ImportController` (`importFromGallery`/`importFromCamera` via image_picker → `ocrServiceProvider` → `SubscriptionParser` → drafts state; `confirmAll` → `SubscriptionDraft` → `AddSubscription`) + its provider in `lib/features/subscription_import/application/import_controller.dart` and `subscription_import_providers.dart`
- [X] T022 [US1] Build the import entry screen (source options: Galeriden seç / Fotoğraf çek) in `lib/features/subscription_import/presentation/import_entry_screen.dart`
- [X] T023 [US1] Build a basic review list (render drafts, "Hepsini kaydet") in `lib/features/subscription_import/presentation/import_review_screen.dart`
- [X] T024 [US1] Add `Routes.importSubscription = '/subscription/import'` + `GoRoute` in `lib/app/router/app_router.dart` and an entry affordance (button) from the add/dashboard flow
- [X] T025 [US1] Override `ocrServiceProvider` with `MlkitOcrService()` in `lib/main.dart`

**Checkpoint**: Pick an image → see recognized draft → save. MVP recognition path works end-to-end (logic unit-tested; render device-verified).

---

## Phase 4: User Story 2 - Review and correct before saving (Priority: P1)

**Goal**: Make the review robust and trustworthy — full editing, discard, low-confidence markers, duplicate flagging, and confirm-gating so nothing invalid is saved.

**Independent Test**: From any draft, edit each field, discard one without affecting others, see "kontrol et" on uncertain fields and a duplicate badge; confirming saves only valid kept drafts (edited values persist).

### Tests for User Story 2 (write first, ensure they FAIL)

- [X] T026 [P] [US2] `DuplicateDetector` tests (normalized brand/name + close amount → existing id; otherwise null) in `test/unit/duplicate_detector_test.dart`
- [X] T027 [P] [US2] Extend `test/unit/import_controller_test.dart`: `editDraft`/`discardDraft`, invalid draft blocked at confirm (Turkish validator message), per-draft save results, duplicate flagged from `subscriptionsProvider`

### Implementation for User Story 2

- [X] T028 [P] [US2] Implement `DuplicateDetector.findDuplicate(draft, existing)` in `lib/features/subscription_import/domain/duplicate_detector.dart`
- [X] T029 [US2] Extend `ImportController`: `editDraft`/`discardDraft`, dedupe against `subscriptionsProvider`, confirm-gate via `SubscriptionValidator`, collect per-draft `Result` + `savedCount` in `lib/features/subscription_import/application/import_controller.dart`
- [X] T030 [US2] Upgrade the review screen: per-field editors (name/amount/currency/period/date/category), low-confidence "kontrol et" markers, duplicate badge with skip/add, per-card discard, success summary in `lib/features/subscription_import/presentation/import_review_screen.dart` (+ draft card widget in `presentation/widgets/`)

**Checkpoint**: Recognize + safely review/correct/save. **MVP (US1+US2) complete and demoable.**

---

## Phase 5: User Story 3 - Import the App Store / Play subscriptions list (Priority: P2)

**Goal**: Recognize multiple subscriptions from one screenshot and guide users to capture the system subscriptions screen.

**Independent Test**: A multi-entry subscriptions-list screenshot → one independent draft per entry (each confirmable/discardable); multi-currency drafts keep their own currency.

### Tests for User Story 3 (write first, ensure they FAIL)

- [X] T031 [P] [US3] Extend `test/unit/subscription_parser_test.dart`: App Store list fixture (≥3 services, repeating brand+price rows) → N drafts; multi-currency fixture → per-draft currency

### Implementation for User Story 3

- [X] T032 [US3] Extend `SubscriptionParser` with multi-anchor segmentation (one draft per brand/amount region) in `lib/features/subscription_import/domain/subscription_parser.dart`
- [X] T033 [US3] Add "App Store & Play aboneliklerim" option + guidance sheet (explain can't read directly → screenshot system screen → gallery pick) in `lib/features/subscription_import/presentation/import_entry_screen.dart`

**Checkpoint**: Store subscriptions list imports as separate reviewable drafts.

---

## Phase 6: User Story 5 - Premium gating (Priority: P2)

**Goal**: Auto-import is premium-only; free users get a locked teaser and no OCR runs.

**Independent Test**: Toggle premium — free user opening import sees a locked teaser with zero OCR calls; premium user gets the full flow; downgrade reverts to teaser on next open.

### Tests for User Story 5 (write first, ensure they FAIL)

- [X] T034 [P] [US5] Extend `test/unit/import_controller_test.dart`: free user → `locked` status and `FakeOcrService` call count == 0; premium → proceeds

### Implementation for User Story 5

- [X] T035 [US5] Gate `ImportController` on `premiumStatusProvider` (set `locked`, run no OCR; re-read status each open) in `lib/features/subscription_import/application/import_controller.dart`
- [X] T036 [US5] Add the locked-teaser state (reuse paywall entry/upgrade prompt) for free users in `lib/features/subscription_import/presentation/import_entry_screen.dart`

**Checkpoint**: Feature is honestly premium-gated, consistent with conversion + widget.

---

## Phase 7: User Story 4 - Import from a PDF receipt/invoice (Priority: P3)

**Goal**: Recognize subscriptions from a PDF (text-based → direct text; scanned → page-image OCR).

**Independent Test**: A text PDF and a scanned PDF each produce a reviewable draft equivalent to importing the same content as an image.

### Tests for User Story 4 (write first, ensure they FAIL)

- [X] T037 [P] [US4] Extend `test/unit/subscription_parser_test.dart` with an extracted-PDF-text fixture → expected draft (parser is source-agnostic)

### Implementation for User Story 4

- [X] T038 [US4] Add `file_picker` and a PDF text path (`syncfusion_flutter_pdf` community) to `pubspec.yaml`; `flutter pub get`
- [X] T039 [US4] Implement `PdfOcrSource` (text-based PDF → text; scanned PDF → page image → `OcrService`) in `lib/features/subscription_import/data/pdf_ocr_source.dart` and wire `OcrService.recognizePdf` in `MlkitOcrService`
- [X] T040 [US4] Add `importFromPdf` to `ImportController` and a "PDF içe aktar" option to the entry screen (`import_controller.dart`, `import_entry_screen.dart`)

**Checkpoint**: All four sources (screenshot, photo, store list, PDF) feed the same review→save flow.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T041 [P] Run `flutter analyze` and resolve all lints/unused imports across `lib/features/subscription_import/`
- [X] T042 [P] Record gotchas (ML Kit iOS 16 floor + app size, image_picker permission handling, parser `now`-injection for determinism, `OcrService` swap path to native Vision) in `.docs/dev-gotchas.md`
- [X] T043 Run the quickstart unit-test suite (`flutter test test/unit/...`) and confirm all pass
- [X] T044 Document device-verification deferral (OCR native render, OS permissions, PDF rasterization) in `specs/009-subscription-import/quickstart.md` (consistent with prior features' device checks)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories.
- **US1 (Phase 3)**: Depends on Foundational. The recognition core other stories build on.
- **US2 (Phase 4)**: Depends on US1 (reviews the drafts US1 produces).
- **US3 (Phase 5)**: Depends on US1 (extends the parser + entry); independently testable.
- **US5 (Phase 6)**: Depends on US1 controller/entry; otherwise independent (could be done any time after US1).
- **US4 (Phase 7)**: Depends on US1 (reuses controller/parser/review); additive PDF source.
- **Polish (Phase 8)**: After desired stories complete.

### Within Each User Story

- Tests written first and FAIL before implementation.
- Pure helpers (amount/date/brand) before the parser that composes them.
- Parser + OCR impl before the controller; controller before screens.

### Parallel Opportunities

- Setup: T002–T005 in parallel (T001 first).
- Foundational: T006, T007, T008, T010 in parallel; T009 after T008.
- US1 tests T011–T015 in parallel; impl helpers T016–T017 in parallel, then T018, then T019.
- Cross-story: US3, US5, US4 can be staffed in parallel once US1 lands (mind shared files: parser for US3, controller/entry for US5/US4 — sequence edits to the same file).

---

## Parallel Example: User Story 1

```bash
# Tests first (all parallel — different files):
Task: "AmountParser tests in test/unit/amount_parser_test.dart"
Task: "DateParser tests in test/unit/date_parser_test.dart"
Task: "BrandTextMatcher tests in test/unit/brand_text_matcher_test.dart"
Task: "SubscriptionParser tests in test/unit/subscription_parser_test.dart"
Task: "ImportController tests in test/unit/import_controller_test.dart"

# Then pure helpers in parallel:
Task: "Implement AmountParser in lib/features/subscription_import/domain/amount_parser.dart"
Task: "Implement DateParser in lib/features/subscription_import/domain/date_parser.dart"
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Phase 1 Setup → Phase 2 Foundational.
2. Phase 3 (US1): recognition → drafts → basic save.
3. Phase 4 (US2): robust review/correct/duplicate/gate.
4. **STOP and VALIDATE**: pick a screenshot → review → save; run the unit suite.

### Incremental Delivery

- + US3 (store list batch) → + US5 (premium gate) → + US4 (PDF) → Polish.
- Each story adds a source or guarantee without breaking the previous.

### Notes

- [P] = different files, no dependencies.
- Parser/helpers are pure → fully unit-tested with text fixtures (no device).
- ML Kit native render, OS permissions, and PDF rasterization are device-verified — defer + note (no device/Xcode here), as with prior features.
- Confirm path always funnels through `AddSubscription` — no bespoke save.
- Commit after each logical group; stop at any checkpoint to validate.
