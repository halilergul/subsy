import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:subsy/features/subscription_import/domain/pdf_picker_port.dart';

/// `file_picker`-backed [PdfPickerPort]. Picks a single PDF with its bytes
/// (no path I/O, consistent with the transient-source rule, FR-016).
class FilePdfPicker implements PdfPickerPort {
  const FilePdfPicker();

  @override
  Future<Uint8List?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    return result?.files.single.bytes;
  }
}
