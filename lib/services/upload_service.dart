import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';

class UploadService {
  static const String _baseUrl = 'http://10.0.2.2:8000'; // Use 10.0.2.2 for Android Emulator

  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndUploadImage() async {
    final email = AuthService().currentUser?.email;
    if (email == null) return null;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final file = File(image.path);
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/uploads/upload-image'));
    request.fields['email'] = email;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['image_url'];
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    }
    return null;
  }
}
