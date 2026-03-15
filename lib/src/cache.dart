import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'payload.dart';

/// Persists the bootstrap payload locally so the app can:
/// 1. Start instantly without waiting for network
/// 2. Work offline with the last known good configuration
/// 3. Detect changes via payload_version comparison
class HatchwayCache {
  static const _payloadKey = 'koolbase_bootstrap_payload';
  static const _timestampKey = 'koolbase_bootstrap_timestamp';

  /// Saves the bootstrap payload to local storage.
  static Future<void> save(HatchwayPayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_payloadKey, jsonEncode(payload.toJson()));
    await prefs.setInt(
      _timestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Loads the last cached payload. Returns null if no cache exists.
  static Future<HatchwayPayload?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_payloadKey);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return HatchwayPayload.fromJson(json);
    } catch (_) {
      // Cache is corrupted — clear it
      await prefs.remove(_payloadKey);
      return null;
    }
  }

  /// Returns when the cache was last updated. Null if never cached.
  static Future<DateTime?> lastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_timestampKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Clears all cached data.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_payloadKey);
    await prefs.remove(_timestampKey);
  }
}
