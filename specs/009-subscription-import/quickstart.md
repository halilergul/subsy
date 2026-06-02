# Quickstart: Automatic Subscription Recognition (OCR Import)

## Prerequisites

- `subscriptions-core` (draft/validator/AddSubscription/brand catalog) + `paywall`/premium seam on `master`.
- New deps (US1–US3): `google_mlkit_text_recognition`, `image_picker`. **iOS deployment target 13 → 16** (ML Kit). US4 (PDF) adds `file_picker` + a PDF text/raster path (Syncfusion community / render fallback).

## Build & checks

```bash
flutter pub get
flutter analyze
flutter test test/unit/subscription_parser_test.dart \
             test/unit/amount_parser_test.dart \
             test/unit/date_parser_test.dart \
             test/unit/brand_text_matcher_test.dart \
             test/unit/duplicate_detector_test.dart \
             test/unit/import_controller_test.dart
# Device/simulator (OCR + permissions + PDF — cannot run headless):
flutter run   # import a screenshot → review → save
```

## Verifying behavior (maps to Success Criteria)

| Check | How | Spec |
|-------|-----|------|
| Recognize single sub | screenshot of one service → review draft pre-filled (service/amount/currency/period/date) | SC-001, SC-002 |
| Nothing saved without confirm | reach `review`; assert no new subscription until "Hepsini kaydet" | SC-003 |
| Offline | airplane mode → recognition + parse still work | SC-004 |
| Multi-sub list | App Store subscriptions screenshot → one draft per entry | SC-005 |
| Editable | change any field before saving; saved value reflects the edit | SC-006 |
| Fewer fields than manual | recognized draft pre-fills ≥ service + amount | SC-007 |
| Premium gate | free user → locked teaser, no OCR; premium → full flow | SC-008 |

## Test patterns

**Parser (pure — no device):**
```dart
final drafts = const SubscriptionParser().parse(
  OcrText(lines: ['Spotify Premium', '₺59,99 / ay', 'Sonraki ödeme: 12.06.2026']),
);
expect(drafts, hasLength(1));
final d = drafts.single;
expect(d.serviceKey, 'spotify');
expect(d.amount, 59.99);
expect(d.currency, Currency.tryl);
expect(d.billingPeriod, BillingPeriod.monthly);
expect(d.nextRenewalDate, DateTime(2026, 6, 12));
expect(d.confidence.amountRecognized, isTrue);

// no subscription → empty
expect(const SubscriptionParser().parse(OcrText(lines: ['random note'])), isEmpty);
```

**Controller (fake OCR — no device):**
```dart
final fake = FakeOcrService(canned: OcrText(lines: ['Netflix \$15.99 monthly 2026-07-01']));
// override ocrServiceProvider with fake; premium = true
await controller.importFromGallery();
expect(controller.state.status, ImportStatus.review);
expect(controller.state.drafts.single.serviceKey, 'netflix');

// free user → locked, no OCR
// (premium = false) open → status == locked, fake.recognizeImageCallCount == 0

await controller.confirmAll();      // → AddSubscription per kept draft
expect(controller.state.status, ImportStatus.done);
expect(controller.state.savedCount, 1);
```

## Native verification (device only)

- **iOS**: confirm deployment target is 16+, photo/camera permission prompts show the Turkish usage strings; pick a screenshot → text recognized → drafts shown; save → appears on dashboard.
- **Android**: system photo picker opens without extra permission; camera capture prompts for camera permission; recognition runs on-device offline.
- **PDF (US4)**: pick a text PDF (direct text) and a scanned PDF (page-image OCR); both yield drafts.
- These are **manual** — ML Kit native render, OS permissions, and PDF rasterization are not buildable in this environment; defer + note (as with prior features' device checks).

## Integration points

- `main.dart`: override `ocrServiceProvider` with `MlkitOcrService()` (next to the other service overrides).
- `app_router.dart`: add `Routes.importSubscription = '/subscription/import'`; entry affordance from the add/dashboard flow.
- Confirm path reuses `AddSubscription` (validation + brand enrichment + premium funnel) — no bespoke save.
- iOS `Info.plist`: `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription` (Turkish). iOS `Podfile`/project: deployment target 16.0.
