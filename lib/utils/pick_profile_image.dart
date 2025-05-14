/// Provides a helper for picking an image from the user's gallery or camera using a modal bottom sheet.
/// Handles permission requests and returns a [File] if an image is selected, or null otherwise.
///
/// # Usage Example
/// ```dart
/// final imageFile = await ImagePickerHelper.pickImage(context);
/// if (imageFile != null) {
///   // Use the selected image
/// }
/// ```
///
/// # See Also
/// - [showModalBottomSheet](https://api.flutter.dev/flutter/material/showModalBottomSheet.html)
/// - [ImagePicker](https://pub.dev/packages/image_picker)
/// - [permission_handler](https://pub.dev/packages/permission_handler)

// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// State Management
// (none in this file)

// App-specific
import 'dart:io';

/// Utility class for picking an image from the gallery or camera.
class ImagePickerHelper {
  /// Shows a modal bottom sheet to let the user pick an image source (gallery or camera),
  /// requests the necessary permissions, and returns a [File] if an image is selected.
  ///
  /// Returns null if the user cancels or denies permissions.
  static Future<File?> pickImage(BuildContext context) async {
    final picker = ImagePicker();

    /// Give users a modal to choose whether to pick from gallery or camera. This is dismissible.
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
    );

    /// If the user dismisses the modal, return null
    if (source == null) return null;

    /// Request permission
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
        return null;
      }
    } else {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gallery access denied')));
        return null;
      }
    }

    /// Pick the image and return it
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    return pickedFile != null ? File(pickedFile.path) : null;
  }
}
