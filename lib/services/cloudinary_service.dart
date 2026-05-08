import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudNameDefine = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const String _uploadPresetDefine = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );
  static const String _folderDefine = String.fromEnvironment('CLOUDINARY_FOLDER');

  Map<String, String>? _envCache;

  String _stripQuotes(String value) {
    final trimmed = value.trim();
    if (trimmed.length >= 2) {
      final first = trimmed[0];
      final last = trimmed[trimmed.length - 1];
      final isQuoted =
          (first == '"' && last == '"') || (first == "'" && last == "'");
      if (isQuoted) {
        return trimmed.substring(1, trimmed.length - 1).trim();
      }
    }
    return trimmed;
  }

  Map<String, String> _parseDotEnv(String raw) {
    final values = <String, String>{};
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      final equalsIndex = trimmed.indexOf('=');
      if (equalsIndex <= 0) {
        continue;
      }
      final key = trimmed.substring(0, equalsIndex).trim();
      final value = trimmed.substring(equalsIndex + 1);
      if (key.isEmpty) {
        continue;
      }
      values[key] = _stripQuotes(value);
    }
    return values;
  }

  Future<Map<String, String>> _loadEnv() async {
    if (_envCache != null) {
      return _envCache!;
    }
    try {
      final raw = await rootBundle.loadString('.env');
      _envCache = _parseDotEnv(raw);
    } catch (_) {
      _envCache = const <String, String>{};
    }
    return _envCache!;
  }

  Future<String?> uploadProductImage({
    required XFile imageFile,
    String? publicId,
  }) async {
    final env = await _loadEnv();
    final cloudName = _cloudNameDefine.isNotEmpty
        ? _cloudNameDefine
        : (env['CLOUDINARY_CLOUD_NAME'] ?? '');
    final uploadPreset = _uploadPresetDefine.isNotEmpty
        ? _uploadPresetDefine
        : (env['CLOUDINARY_UPLOAD_PRESET'] ?? '');
    final folder = _folderDefine.isNotEmpty
        ? _folderDefine
        : (env['CLOUDINARY_FOLDER'] ?? '');

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw StateError(
        'Cloudinary is not configured. Provide --dart-define=CLOUDINARY_CLOUD_NAME=... '
        'and --dart-define=CLOUDINARY_UPLOAD_PRESET=... in your build/run command, '
        'or add a .env file to your Flutter assets with these keys.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final bytes = await imageFile.readAsBytes();

    String extractDetails(String body) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic> &&
            decoded['error'] is Map<String, dynamic>) {
          final error = decoded['error'] as Map<String, dynamic>;
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message;
          }
        }
      } catch (_) {
        // Keep raw body
      }
      return body;
    }

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset;

    if (folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    // NOTE: We deliberately do NOT send `public_id`. Cloudinary unsigned
    // upload presets disallow custom public IDs by default, which made
    // every save fail unless the preset was specifically configured.
    // Letting Cloudinary auto-generate the ID is reliable and the
    // returned `secure_url` is what we persist anyway. The `publicId`
    // parameter on this method is kept as a hint for future use but
    // intentionally ignored. // ignore: unused_local_variable
    final _ = publicId;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name.isNotEmpty ? imageFile.name : 'upload.jpg',
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 300) {
      final details = extractDetails(body);
      throw Exception(
        'Cloudinary upload failed (HTTP $statusCode): $details',
      );
    }

    final payload = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = payload['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception(
        'Cloudinary upload succeeded but returned no secure_url.',
      );
    }
    return secureUrl;
  }
}

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});
