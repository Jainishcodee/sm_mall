import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const String _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );
  static const String _folder = String.fromEnvironment('CLOUDINARY_FOLDER');

  Future<String?> uploadProductImage({
    required File imageFile,
    String? publicId,
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset;

    if (_folder.isNotEmpty) {
      request.fields['folder'] = _folder;
    }

    if (publicId != null && publicId.isNotEmpty) {
      request.fields['public_id'] = publicId;
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final payload = jsonDecode(body) as Map<String, dynamic>;
    return payload['secure_url'] as String?;
  }
}

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});
