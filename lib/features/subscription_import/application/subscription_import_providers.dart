import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/subscription_import/data/file_pdf_picker.dart';
import 'package:subsy/features/subscription_import/data/image_picker_adapter.dart';
import 'package:subsy/features/subscription_import/domain/image_picker_port.dart';
import 'package:subsy/features/subscription_import/domain/ocr_service.dart';
import 'package:subsy/features/subscription_import/domain/pdf_picker_port.dart';

/// On-device OCR engine. Stub THROWS so a missing `main` override fails loudly
/// rather than silently doing nothing — same pattern as
/// `exchangeRateServiceProvider` / `homeWidgetServiceProvider`. `main.dart`
/// overrides this with `MlkitOcrService()`.
final ocrServiceProvider = Provider<OcrService>((ref) {
  throw UnimplementedError(
    'Override ocrServiceProvider in main with MlkitOcrService.',
  );
});

/// OS gallery/camera picker (research.md D8). Overridable in tests.
final imagePickerPortProvider = Provider<ImagePickerPort>(
  (ref) => ImagePickerAdapter(),
);

/// OS file picker for PDF receipts (US4). Overridable in tests.
final pdfPickerPortProvider = Provider<PdfPickerPort>(
  (ref) => const FilePdfPicker(),
);
