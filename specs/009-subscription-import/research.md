# Research: Automatic Subscription Recognition (OCR Import)

Phase 0 decisions. Each: Decision · Rationale · Alternatives considered.

## D1 — OCR engine: Google ML Kit on-device text recognition (behind `OcrService`)

**Decision**: Use `google_mlkit_text_recognition` (on-device, offline, free, no API key) as the v1 `OcrService` implementation, hidden behind a Dart `OcrService` interface.

**Rationale**: It is the de-facto cross-platform Flutter OCR with a single Dart API for iOS + Android; the underlying model is Google's production on-device OCR (first-party model, popular plugin wrapper). It runs entirely on-device — no network, no key, no per-scan cost — which is the only path consistent with Subsy's offline/zero-backend/free constraints. Critically for *this* environment: it gives **one testable Dart code path**, whereas a native solution's iOS half cannot be compiled or verified here (no Xcode/device). The `OcrService` seam means the engine is swappable later without touching the parser or UI.

**Alternatives considered**:
- **Native Apple Vision (iOS) + ML Kit (Android)**: best "first-party, stable, iOS 13, zero app-size" profile, and Vision improves automatically with iOS — but requires a Swift platform channel we **cannot build/verify in this environment**, and doubles the engine surface. Rejected for v1; preserved as a future swap behind `OcrService`.
- **Cloud OCR (Google Vision API / AWS Textract) or an LLM**: highest accuracy, but needs network + API keys + cost and **breaks the offline/zero-backend selling point**. Rejected outright (constitution).
- **Tesseract (`flutter_tesseract_ocr`)**: offline and free but weaker on real-world receipts/screenshots and heavier to bundle language data. Rejected.

## D2 — Minimum iOS version: 13 → 16

**Decision**: Raise the iOS deployment target from 13.0 to 16.0; keep Android minSdk 21.

**Rationale**: `google_mlkit_text_recognition` requires iOS 16. In mid/late-2026 iOS 16+ covers the large majority of active devices (≈90%+), and the share only grows, so the cost shrinks over time. The bump is recorded so it is a conscious product trade-off, not an accident.

**Alternatives considered**: Native Vision keeps iOS 13 (see D1) — rejected for v1 due to unverifiable native code. If dropping iOS 13–15 devices proves unacceptable, the `OcrService` seam lets us add a Vision implementation for iOS without reworking the feature.

## D3 — Recognition logic is pure Dart over text (`SubscriptionParser`)

**Decision**: `OcrService` returns plain recognized text (lines/blocks). A pure `SubscriptionParser` (with pure helpers `AmountParser`, `DateParser`, `BrandTextMatcher`, `DuplicateDetector`) turns that text into `RecognizedDraft`s. No ML/heuristics live in the UI or the service.

**Rationale**: Keeps the entire "intelligence" of the feature unit-testable with text fixtures — no images, no device, no flakiness. Mirrors the project's proven pattern (`buildWidgetPayload`, `currencyConverter`, `reminderPlanner` are all pure). It also makes the rules auditable and locale-tunable.

**Alternatives considered**: Doing extraction inside the OCR impl or the controller — rejected; it would entangle platform code with logic and make the most important part untestable.

## D4 — Brand matching: extend the existing catalog matcher (`BrandTextMatcher`)

**Decision**: Add a pure `BrandTextMatcher` that scans free OCR text for any `kBrandCatalog` entry (display name or alias), using the **same Turkish-tolerant normalization** as `BrandResolver`, returning matches with their position (to anchor multi-subscription segmentation). Longest/alias-aware match wins. `BrandResolver.resolve` (exact, whole-string) stays unchanged for the form path.

**Rationale**: OCR text needs *substring/contains* matching across a blob, which `BrandResolver.resolve` (exact equality) does not do. Reusing the catalog + normalization keeps one source of truth for brand knowledge while giving OCR the scan it needs. Unknown names fall through to raw text (FR-004), never a false brand.

**Alternatives considered**: Fuzzy/Levenshtein matching — deferred; exact alias+normalization matching is predictable and avoids false positives. A second copy of the catalog — rejected (duplication).

## D5 — Amount, currency, date, period extraction (locale-aware, pure)

**Decision**:
- **Amount/currency** (`AmountParser`): regex for a currency marker (`₺`, `TL`, `TRY`, `$`, `USD`, `€`, `EUR`) adjacent to a number; normalize both Turkish/EU (`1.234,56`) and US (`1,234.56`) groupings to a `double`. Currency marker → `Currency` enum; default/ambiguous handling documented.
- **Date** (`DateParser`): regex for `dd.MM.yyyy`, `dd/MM/yyyy`, ISO `yyyy-MM-dd`, and textual `12 Şubat 2026` / `Feb 12` with Turkish + English month-name maps. A day-of-month-only or past date is rolled forward to the next occurrence using the **same effective-renewal rule as the rest of the app**, and flagged as low-confidence for user confirmation.
- **Period** (`DateParser`): keyword scan — `aylık/ay/monthly/mo` → monthly, `yıllık/yıl/yearly/yr/annual` → yearly, `haftalık/hafta/weekly/wk` → weekly. Default monthly when absent, flagged low-confidence.

**Rationale**: Receipts/screenshots in TR/EN use predictable currency, number, and date conventions; deterministic regex + keyword maps are testable and good enough for a "fast + correctable" flow. Turkish formats (comma decimal, Turkish month names) are first-class per the constitution's i18n rule.

**Alternatives considered**: A statistical/date-parsing library — heavier and less predictable for the Turkish cases; the bespoke pure parser stays under our control and fully tested.

## D6 — Multi-subscription segmentation (App Store list)

**Decision**: Treat each `BrandTextMatcher` hit (and, when no brand, each strong amount+date line group) as the anchor of a separate `RecognizedDraft`; associate the nearest amount/date/period within the same text region. Produce N independent drafts (FR-008).

**Rationale**: A store subscriptions screenshot lists several services as repeating brand + price rows; anchoring on brand positions cleanly splits them. Each draft is reviewed/confirmed/discarded independently (US3).

**Alternatives considered**: One-draft-per-source — rejected; it would merge a multi-line list into garbage. Layout/bounding-box analysis from OCR blocks — a possible future precision boost; line-region heuristics are enough for v1 and stay testable.

## D7 — PDF handling (US4, P3 — deferred slice)

**Decision**: For US4, add `file_picker` to select a PDF. For **text-based** PDFs, extract text directly (`syncfusion_flutter_pdf`, free community license, pure-Dart text extraction) and feed it to the parser — no OCR needed. For **scanned/image-only** PDFs, render the page to an image and run it through `OcrService`. PDF is the lowest-priority story, so these deps land only with US4.

**Rationale**: Text PDFs need no OCR at all (faster, exact); only scanned PDFs need rasterization. Staging PDF behind P3 keeps the MVP dependency set minimal (just ML Kit + image_picker) and defers the messier PDF/raster choice.

**Alternatives considered**: Always rasterize then OCR — simpler but loses exact text and adds error for text PDFs. `read_pdf_text` (platform-channel text extraction) — viable alternative to Syncfusion; final pick deferred to US4 implementation. Render libraries (`pdfx`/`printing`) evaluated for the scanned fallback.

## D8 — Permissions & source picking

**Decision**: Use `image_picker` for gallery + camera. iOS: declare `NSPhotoLibraryUsageDescription` + `NSCameraUsageDescription` (Turkish strings). Android: the system photo picker needs no runtime permission; camera capture declares the camera feature/permission. Denials surface a clear Turkish message with a path to retry / open settings (FR-012).

**Rationale**: `image_picker` is the standard, well-maintained Flutter media picker and routes through the OS pickers (privacy-friendly, minimal permissions). Matches the offline posture (no library indexing, just a one-shot pick).

**Alternatives considered**: `file_picker` for images too — heavier; reserved for PDF (D7). Direct camera plugins — unnecessary for one-shot capture.

## D9 — Premium gating & entry point

**Decision**: Add a route `'/subscription/import'` and an entry affordance from the add/dashboard flow. The entry screen reads `premiumStatusProvider`; if not premium, it shows a **locked teaser** (reusing the paywall entry) and runs no OCR. Confirmed drafts go through `AddSubscription`, which already skips the free limit for premium users.

**Rationale**: Mirrors how currency conversion and the home widget gate (FR-017/FR-018), reusing the existing premium seam. Because only premium users reach recognition, the free-tier subscription cap is never hit by import. The purchase flow itself remains the separate, deferred paywall feature.

**Alternatives considered**: Gating only the save step (let free users see recognition) — rejected; FR-017 requires no recognition for free users (honest teaser, no compute spent).

## D10 — Transient handling & privacy

**Decision**: Imported images/PDFs are read into memory for recognition and **not persisted** (no copy into app storage, no cache) — FR-016. Only confirmed subscriptions are stored, via the normal repository.

**Rationale**: Upholds the privacy/offline promise literally; nothing about the source lingers. Reduces storage and avoids any accidental data trail.

**Alternatives considered**: Caching the last source for re-review — rejected; conflicts with the transient/privacy guarantee and adds state for little value.
