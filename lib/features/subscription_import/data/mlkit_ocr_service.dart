import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:subsy/features/subscription_import/data/pdf_ocr_source.dart';
import 'package:subsy/features/subscription_import/domain/ocr_service.dart';
import 'package:subsy/features/subscription_import/domain/ocr_text.dart';

/// On-device OCR via Google ML Kit (offline, free — research.md D1). Writes the
/// image bytes to a temp file (ML Kit reads a file path), recognizes Latin-script
/// text, flattens blocks→lines into [OcrText], and disposes the recognizer.
/// Nothing is persisted (FR-016). "No text" returns empty, not an error.
class MlkitOcrService implements OcrService {
  const MlkitOcrService();

  @override
  Future<OcrText> recognizeImage(Uint8List bytes) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final file = await File('${Directory.systemTemp.path}/subsy_ocr_$stamp.png')
        .writeAsBytes(bytes, flush: true);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(file.path));
      final lines = <String>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isNotEmpty) lines.add(text);
        }
      }
      return OcrText(lines: lines);
    } finally {
      await recognizer.close();
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<OcrText> recognizePdf(Uint8List bytes) async {
    // Text-based PDFs: exact text extraction (pure Dart, offline). Scanned PDFs
    // yield empty text → the controller shows a "not recognized" result; the
    // page-image rasterization fallback is device-only and deferred.
    return const PdfOcrSource().extractText(bytes);
  }
}
