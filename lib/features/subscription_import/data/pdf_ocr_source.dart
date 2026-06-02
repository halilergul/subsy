import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:subsy/features/subscription_import/domain/ocr_text.dart';

/// Pure-Dart PDF text extraction (research.md D7). For text-based PDFs this
/// pulls the exact text (no OCR needed, offline, free). Scanned/image-only PDFs
/// yield empty text — the page-image OCR fallback is device-only and deferred.
class PdfOcrSource {
  const PdfOcrSource();

  OcrText extractText(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      final raw = PdfTextExtractor(document).extractText();
      return OcrText.fromRaw(raw);
    } finally {
      document.dispose();
    }
  }
}
