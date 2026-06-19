import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class FeedbackService {
  // TODO: Replace with your deployed Cloud Function URL
  // Example: https://us-central1-YOUR_PROJECT.cloudfunctions.net/submitFeatureRequest
  static String functionUrl = '';

  static Future<bool> submitFeatureRequest({
    required String description,
    String? email,
    required String platform,
  }) async {
    if (functionUrl.isEmpty) {
      if (kDebugMode) {
        print('FeedbackService: functionUrl is not set');
      }
      return false;
    }

    try {
      final pkg = await PackageInfo.fromPlatform();
      final payload = {
        'description': description,
        'email': (email ?? '').trim().isEmpty ? null : email!.trim(),
        'appVersion': pkg.version,
        'buildNumber': pkg.buildNumber,
        'platform': platform,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final resp = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return true;
      }

      if (kDebugMode) {
        print('FeedbackService: Failed ${resp.statusCode} ${resp.body}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('FeedbackService: Error $e');
      }
      return false;
    }
  }
}


