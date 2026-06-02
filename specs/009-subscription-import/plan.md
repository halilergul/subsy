# Implementation Plan: Automatic Subscription Recognition (OCR Import, Premium)

**Branch**: `009-subscription-import` | **Date**: 2026-06-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-subscription-import/spec.md`

## Summary

A **premium** flow that turns a picture into subscriptions. The user picks a source — a screenshot, a photo of a receipt, a PDF invoice, or a screenshot of the system App Store/Play subscriptions screen — and Subsy recognizes one or more subscriptions (service, amount, currency, billing period, next-payment date), shows them as editable **drafts**, and saves the confirmed ones in one step.

All recognition is **on-device**: a thin `OcrService` (behind an interface, backed by Google ML Kit on-device text recognition) turns the image/PDF into plain text, and a **pure Dart `SubscriptionParser`** turns that text into draft subscriptions by matching the existing **brand catalog** and extracting amounts/currencies/dates/periods with locale-aware rules. No network, no cloud OCR, no LLM — the feature is fully offline and free, preserving Subsy's "data never leaves the device" promise. Because phone platforms do not let an app read another app's store subscriptions, the App Store/Play case is served by importing a screenshot of the system subscriptions screen (same pipeline).

Recognition is best-effort and never silent: the **review screen** is mandatory, every field is editable, possible duplicates are flagged, and confirmed drafts are created through the **existing `AddSubscription` use case** (reusing validation, brand enrichment, and the premium-aware funnel). Native pieces (ML Kit plugin, photo/camera permissions) are scaffolded and **device-verified** (not buildable headless here). The heavy logic — the parser — is pure and exhaustively unit-tested with text fixtures.

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (stable)

**Primary Dependencies**:
- **New**: `google_mlkit_text_recognition` (on-device OCR, offline, free), `image_picker` (gallery/camera). **Deferred to US4 (PDF, P3)**: `file_picker` (pick PDF) + a PDF text/raster path (`syncfusion_flutter_pdf` community for text-based PDFs; render-to-image fallback for scanned PDFs — see research.md D7).
- **Reused (no change)**: `flutter_riverpod`, `go_router`, `flutter_svg`, `intl`. Reuses `SubscriptionDraft`, `BrandResolver` + `kBrandCatalog`, `SubscriptionValidator`, `AddSubscription`, `premiumStatusProvider`, `subscriptionsProvider`, the `Result<T>`/`AppError` types, and the brand-avatar UI.

**Storage**: None new. Imported sources are processed **transiently** (FR-016) and never persisted. Confirmed drafts are written through the existing subscription repository.

**Testing**: `flutter_test` — pure unit tests for `SubscriptionParser` and its helpers (`AmountParser`, `DateParser`, `BrandTextMatcher`, `DuplicateDetector`) using text fixtures (single receipt, App Store list, Turkish/EU number formats, partial, garbage, multi-currency). `OcrService` is behind an interface and faked; the `ImportController` orchestration is tested with a `FakeOcrService`. ML Kit native render + permissions + PDF rasterization are **device-verified** (manual, per quickstart) — not unit-testable here.

**Target Platform**: iOS 16+ / Android (minSdk 21), offline, dark, Turkish. **iOS deployment target rises 13 → 16** to satisfy ML Kit (research.md D2; reversible via the `OcrService` seam).

**Project Type**: Mobile app (Flutter), feature-first layered architecture.

**Performance Goals**: One-shot, user-initiated recognition; parser is O(n) over recognized lines at personal scale (a receipt or a subscriptions list). No polling/background work.

**Constraints**: Premium-gated; 100% offline (no network for OCR or parsing); no cloud/LLM; transient sources; mandatory editable review before any save; Turkish + international number/date/currency formats; dark + Turkish UI.

**Scale/Scope**: One `OcrService` interface + ML Kit impl; one pure `SubscriptionParser` (+ amount/date/brand/duplicate helpers); one `ImportController`; two screens (entry + review) with a locked-teaser state; native permission scaffolds; tests. PDF (US4) is an additive, lowest-priority slice.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Offline / zero backend | ✅ | On-device OCR + pure parser; **no network, no cloud OCR, no LLM**. "Data never leaves the device" preserved |
| Business logic separated from UI | ✅ | Pure `SubscriptionParser` (+ helpers); OCR behind `OcrService`; screens only render/collect |
| Data via provider; platform behind a service | ✅ | `ocrServiceProvider` wraps the plugin (overridden in `main`, faked in tests); UI reads providers |
| Reuse over duplication | ✅ | Confirm funnels through existing `AddSubscription`; reuses `SubscriptionDraft`, `BrandResolver`/`kBrandCatalog`, `SubscriptionValidator`, premium + subscriptions providers |
| Every feature tested; critical path mandatory | ✅ | Parser + helpers exhaustively unit-tested with fixtures; controller faked; native/PDF device-verified |
| Typed error handling, Turkish messages | ✅ | `Result<T>`/`AppError`; recognition failures are surfaced as friendly Turkish states, never crashes |
| No magic numbers/strings | ✅ | Regex patterns, period/month keyword maps, route names, permission keys as named consts |
| Premium gating | ✅ | Reuses `premiumStatusProvider`; free → locked teaser, no OCR runs |
| Dark mode / Turkish UI | ✅ | Both screens dark + Turkish |
| English code / Turkish UI | ✅ | Code English; user-facing strings Turkish |
| Input validation | ✅ | Confirm reuses `SubscriptionValidator` via `AddSubscription` |

**⚠️ Anti-goal crossing (declared, user-authorized):** CONSTITUTION lists **"Banka entegrasyonu / otomatik abonelik tespiti"** under v1 anti-goals. This feature delivers *otomatik abonelik tespiti* and therefore **crosses a former anti-goal — by explicit user request** ("bu özellikleri eklemeden olmaz", 2026-06-02). It is implemented **within** the binding principles: fully offline, on-device, zero backend, **no bank integration** (the anti-goal's real concern). The constitution is updated to record this decision (anti-goal annotated + decision-table row). See Complexity Tracking.

**Initial gate: PASS with one declared, justified deviation** (anti-goal crossing, authorized + recorded). New platform plugins (ML Kit, image_picker) sit behind the service seam, consistent with the architecture. The iOS 13→16 bump and app-size increase are trade-offs (research.md D2), not principle violations.

## Project Structure

### Documentation (this feature)

```text
specs/009-subscription-import/
├── plan.md · research.md · data-model.md · quickstart.md
├── contracts/ocr-service.md · contracts/subscription-parser.md · contracts/import-flow.md
├── checklists/requirements.md
└── tasks.md  (later — /speckit-tasks)
```

### Source Code (repository root)

```text
lib/features/subscription_import/
├── domain/
│   ├── recognized_draft.dart        # value: nullable fields + per-field confidence + duplicate flag
│   ├── ocr_text.dart                # value: recognized text (lines/blocks) — OcrService output
│   ├── ocr_service.dart             # interface: recognizeImage(bytes) / recognizePdf(...) → OcrText
│   ├── subscription_parser.dart     # PURE: parse(OcrText) → List<RecognizedDraft>  ← the heart
│   ├── amount_parser.dart           # PURE: money/currency token extraction (TR + intl formats)
│   ├── date_parser.dart             # PURE: date + period extraction (TR/EN month names, dd.MM.yyyy…)
│   ├── brand_text_matcher.dart      # PURE: find catalog brands within free text (reuses kBrandCatalog)
│   └── duplicate_detector.dart      # PURE: flag drafts matching existing subscriptions
├── data/
│   ├── mlkit_ocr_service.dart       # google_mlkit_text_recognition impl (image)
│   └── pdf_ocr_source.dart          # (US4) PDF → text / page-image → OcrService
├── application/
│   ├── subscription_import_providers.dart  # ocrServiceProvider (overridden in main) + controller
│   └── import_controller.dart       # pick → ocr → parse → dedupe → drafts state; confirm → AddSubscription
└── presentation/
    ├── import_entry_screen.dart     # source picker + App Store guide + premium locked teaser
    ├── import_review_screen.dart    # editable draft cards + per-draft confirm/discard + bulk save
    └── widgets/                     # draft card, source-option tile, locked teaser

lib/app/router/app_router.dart       # add Routes.importSubscription ('/subscription/import')
lib/main.dart                        # override ocrServiceProvider with MlkitOcrService

# Native scaffolds (device-verified)
ios/Runner/Info.plist                # NSPhotoLibraryUsageDescription, NSCameraUsageDescription
ios/Podfile + project.pbxproj        # platform/deployment target 13.0 → 16.0 (ML Kit)
android/app/src/main/AndroidManifest.xml   # camera feature/permission as needed by image_picker

test/unit/
├── subscription_parser_test.dart    # fixtures: receipt, App Store list, TR/EU formats, partial, garbage, multi-currency
├── amount_parser_test.dart · date_parser_test.dart
├── brand_text_matcher_test.dart · duplicate_detector_test.dart
└── import_controller_test.dart      # FakeOcrService → drafts; confirm → AddSubscription
test/support/fakes.dart              # add FakeOcrService (returns canned OcrText)
```

**Structure Decision**: New `lib/features/subscription_import/` with the established `domain/data/application/presentation` split. The decisive choice is to keep **all recognition logic pure**: `OcrService` (interface) hides the only impure, platform-bound step (turning pixels/PDF into text), while the **`SubscriptionParser` and its helpers are pure Dart over strings** — so brand matching, amount/date/period extraction, multi-subscription segmentation, and duplicate detection are all unit-tested with text fixtures (no images, no device). Confirmed drafts never get a bespoke save path: they convert to the existing `SubscriptionDraft` and go through `AddSubscription`, inheriting validation, brand enrichment, and the premium-aware funnel. The ML Kit plugin and PDF handling live only in `data/`, behind the service, overridden in `main` and faked in tests — exactly mirroring how `home_widget`, exchange-rate, and notification platform code is isolated.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Crosses v1 anti-goal "otomatik abonelik tespiti" | Explicit user request (2026-06-02): the product now needs picture→subscription import to be competitive (subsday-class). | Not building it was the prior default; rejected because the user reversed that decision. Implemented within all binding principles (offline, on-device, zero backend, **no bank integration**), so the anti-goal's actual risk is not incurred. Recorded in CONSTITUTION (anti-goal annotation + decision row). |
| New platform plugins (ML Kit, image_picker) + iOS 13→16 bump + app-size increase | On-device OCR is the only offline/free way to read text from images; ML Kit is the most stable cross-platform engine (research.md D1). | Native Apple Vision (iOS 13, no size cost) rejected for v1 because its iOS path is **unverifiable in this environment** (no Xcode/device) — a real long-term risk; the `OcrService` seam keeps switching to Vision a localized change if the iOS floor matters later. |
