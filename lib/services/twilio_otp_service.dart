import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class TwilioOtpResult {
  final bool success;
  final String? error;

  const TwilioOtpResult({required this.success, this.error});
}

/// Calls the Twilio Functions backend (free serverless) to send and verify OTPs
/// using the Twilio Verify API. Account SID, Auth Token and Verify Service SID
/// stay on the Twilio side as environment variables — the app only needs the
/// public base URL of the deployed Functions service.
class TwilioOtpService {
  static const String _baseUrlDefine = String.fromEnvironment(
    'TWILIO_FUNCTIONS_BASE_URL',
  );

  static Map<String, String>? _envCache;

  static Future<String> _baseUrl() async {
    if (_baseUrlDefine.isNotEmpty) {
      return _stripTrailingSlash(_baseUrlDefine);
    }
    _envCache ??= await _loadEnv();
    final fromFile = _envCache!['TWILIO_FUNCTIONS_BASE_URL'] ?? '';
    if (fromFile.isEmpty) {
      throw StateError(
        'TWILIO_FUNCTIONS_BASE_URL is not configured. Add it to the .env asset '
        'or pass --dart-define=TWILIO_FUNCTIONS_BASE_URL=https://your-service.twil.io',
      );
    }
    return _stripTrailingSlash(fromFile);
  }

  static String _stripTrailingSlash(String input) {
    var s = input.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static Future<Map<String, String>> _loadEnv() async {
    try {
      final raw = await rootBundle.loadString('.env');
      final values = <String, String>{};
      for (final line in raw.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final eq = trimmed.indexOf('=');
        if (eq <= 0) continue;
        final k = trimmed.substring(0, eq).trim();
        var v = trimmed.substring(eq + 1).trim();
        if ((v.startsWith('"') && v.endsWith('"')) ||
            (v.startsWith("'") && v.endsWith("'"))) {
          v = v.substring(1, v.length - 1);
        }
        values[k] = v;
      }
      return values;
    } catch (_) {
      return const <String, String>{};
    }
  }

  /// Sends an OTP SMS to [phone] (E.164 format, e.g. +919876543210).
  static Future<TwilioOtpResult> sendOtp(String phone) async {
    final Uri uri;
    try {
      final base = await _baseUrl();
      uri = Uri.parse('$base/start-verify');
    } catch (e) {
      return TwilioOtpResult(success: false, error: e.toString());
    }

    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(const Duration(seconds: 20));
      final body = _safeDecode(res.body);
      final ok = res.statusCode == 200 && body['success'] == true;
      if (ok) return const TwilioOtpResult(success: true);
      return TwilioOtpResult(
        success: false,
        error: (body['error']?.toString().isNotEmpty ?? false)
            ? body['error'].toString()
            : 'Failed to send OTP (HTTP ${res.statusCode}).',
      );
    } catch (e) {
      return TwilioOtpResult(success: false, error: e.toString());
    }
  }

  /// Verifies [code] against [phone]. Returns success only when Twilio
  /// approves the verification.
  static Future<TwilioOtpResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final Uri uri;
    try {
      final base = await _baseUrl();
      uri = Uri.parse('$base/check-verify');
    } catch (e) {
      return TwilioOtpResult(success: false, error: e.toString());
    }

    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone, 'code': code}),
          )
          .timeout(const Duration(seconds: 20));
      final body = _safeDecode(res.body);
      final ok = res.statusCode == 200 && body['success'] == true;
      if (ok) return const TwilioOtpResult(success: true);
      return TwilioOtpResult(
        success: false,
        error: (body['error']?.toString().isNotEmpty ?? false)
            ? body['error'].toString()
            : 'Invalid or expired code.',
      );
    } catch (e) {
      return TwilioOtpResult(success: false, error: e.toString());
    }
  }

  static Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const <String, dynamic>{};
  }
}
