import 'dart:typed_data';

/// Abstracts PDF file picking so [ImportController] stays testable (US4).
/// Returns the picked PDF bytes, or null if the user cancelled.
abstract interface class PdfPickerPort {
  Future<Uint8List?> pickPdf();
}
