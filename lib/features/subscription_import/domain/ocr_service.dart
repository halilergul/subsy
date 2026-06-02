import 'dart:typed_data';

import 'package:subsy/features/subscription_import/domain/ocr_text.dart';

/// The only impure, platform-bound seam of the import feature. Hides ML Kit
/// (and PDF rasterization) behind an interface so the parser/UI stay pure and
/// the engine is swappable (research.md D1, D7).
///
/// On-device and offline. "No text" is NOT an error — implementations return an
/// empty [OcrText]. They throw only on a genuine engine failure, which the
/// controller maps to a typed `AppError` (FR-011).
abstract interface class OcrService {
  /// Recognize text from an image (screenshot/photo) loaded as bytes.
  Future<OcrText> recognizeImage(Uint8List bytes);

  /// (US4) Recognize text from a PDF: direct text for text-based PDFs,
  /// page-image OCR fallback for scanned PDFs.
  Future<OcrText> recognizePdf(Uint8List bytes);
}
