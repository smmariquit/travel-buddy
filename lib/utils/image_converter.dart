import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

Future<String?> convertImageToBase64(ImageSource source) async {
  final pickedFile = await ImagePicker().pickImage(source: source);
  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    return base64Encode(bytes);
  }
  return null;
}
