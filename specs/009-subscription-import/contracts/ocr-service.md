# Contract: OcrService

The only impure, platform-bound seam. Hides ML Kit (and PDF rasterization) behind a Dart interface so the parser/UI stay pure and the engine is swappable (research.md D1, D7).

## Interface

```dart
abstract interface class OcrService {
  /// Recognize text from an image (screenshot/photo) already loaded as bytes.
  /// On-device, offline. Returns recognized text; never throws for "no text"
  /// (returns empty OcrText). Throws only on a genuine engine failure, which
  /// the controller maps to a typed AppError.
  Future<OcrText> recognizeImage(Uint8List bytes);

  /// (US4) Recognize text from a PDF: direct text for text-based PDFs,
  /// page-image OCR fallback for scanned PDFs.
  Future<OcrText> recognizePdf(Uint8List bytes);
}
```

## Implementations

- **MlkitOcrService** (`data/mlkit_ocr_service.dart`): wraps `google_mlkit_text_recognition` (Latin script). Writes bytes to a temp `InputImage`, runs on-device recognition, flattens blocks/lines into `OcrText`, disposes the recognizer. Overridden into `ocrServiceProvider` in `main`.
- **FakeOcrService** (`test/support/fakes.dart`): returns a canned `OcrText` (or empty / throws) per test. Lets the controller + parser be tested with no device.

## Guarantees

- **Offline**: no network call; works in airplane mode (SC-004).
- **Transient**: operates on in-memory bytes; persists nothing (FR-016).
- **No-text is not an error**: empty recognition → empty `OcrText` → controller yields `noResult` (FR-011), not a crash.
- **Engine failure → typed error**: a real failure surfaces as `AppError` with a Turkish message (FR-011); never an uncaught exception.

## Provider

```dart
// subscription_import_providers.dart — stub throws if not overridden (forces main wiring)
final ocrServiceProvider = Provider<OcrService>((ref) =>
    throw UnimplementedError('Override ocrServiceProvider in main with MlkitOcrService'));
```

`main.dart` overrides it with `MlkitOcrService()` (same pattern as `exchangeRateServiceProvider`, `homeWidgetServiceProvider`, `notificationSchedulerProvider`).
