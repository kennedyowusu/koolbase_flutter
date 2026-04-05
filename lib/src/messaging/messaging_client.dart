import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ─── Models ──────────────────────────────────────────────────────────────────

class KoolbaseMessage {
  final String title;
  final String body;
  final Map<String, dynamic> data;

  const KoolbaseMessage({
    required this.title,
    required this.body,
    this.data = const {},
  });
}

// ─── KoolbaseMessaging ────────────────────────────────────────────────────────

class KoolbaseMessaging {
  static const _tag = '[KoolbaseMessaging]';

  final String baseUrl;
  final String apiKey;
  String? _deviceId;

  KoolbaseMessaging({
    required this.baseUrl,
    required this.apiKey,
  });

  void setDeviceId(String deviceId) {
    _deviceId = deviceId;
  }

  // ─── Register token ───────────────────────────────────────────────────────

  /// Register an FCM device token with Koolbase.
  /// Call this after obtaining the token from firebase_messaging.
  ///
  /// ```dart
  /// final fcmToken = await FirebaseMessaging.instance.getToken();
  /// await Koolbase.messaging.registerToken(
  ///   token: fcmToken!,
  ///   platform: 'android',
  /// );
  /// ```
  Future<bool> registerToken({
    required String token,
    required String platform,
    String? userId,
  }) async {
    if (_deviceId == null) {
      debugPrint('$_tag registerToken called before deviceId is set');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/messaging/register'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'device_id': _deviceId,
          'token': token,
          'platform': platform,
          if (userId != null) 'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('$_tag token registered successfully');
        return true;
      }

      debugPrint('$_tag failed to register token: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('$_tag registerToken error: $e');
      return false;
    }
  }

  // ─── Send notification ────────────────────────────────────────────────────

  /// Send a push notification to a specific device token.
  /// Requires FCM_SERVER_KEY to be set in project secrets.
  Future<bool> send({
    required String to,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/messaging/send'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'token': to,
          'title': title,
          'body': body,
          'data': data,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('$_tag notification sent successfully');
        return true;
      }

      debugPrint('$_tag failed to send notification: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('$_tag send error: $e');
      return false;
    }
  }
}
