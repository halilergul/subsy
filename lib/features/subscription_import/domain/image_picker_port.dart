import 'dart:typed_data';

/// Where an imported image comes from.
enum ImportImageSource { gallery, camera }

/// Abstracts media picking so [ImportController] stays testable (the
/// `image_picker` plugin is faked in tests). Returns the picked image bytes,
/// or null if the user cancelled. Throws on a permission/engine failure, which
/// the controller maps to a typed error.
abstract interface class ImagePickerPort {
  Future<Uint8List?> pick(ImportImageSource source);
}
