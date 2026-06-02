import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:subsy/features/subscription_import/domain/image_picker_port.dart';

/// `image_picker`-backed [ImagePickerPort]. Routes through the OS gallery/camera
/// pickers (privacy-friendly, minimal permissions — research.md D8). Returns the
/// picked image bytes, or null if the user cancelled.
class ImagePickerAdapter implements ImagePickerPort {
  ImagePickerAdapter([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(ImportImageSource source) async {
    final file = await _picker.pickImage(
      source: source == ImportImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 100,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
