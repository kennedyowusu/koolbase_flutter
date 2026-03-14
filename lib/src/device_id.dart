import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the anonymous device identifier.
///
/// Generates a UUID v4 on first launch and persists it in secure storage.
/// This ID is stable across app restarts and is used for deterministic
/// rollout bucketing: stableHash(deviceId + ":" + flagKey) % 100
class DeviceIdManager {
  static const _storageKey = 'hatchway_device_id';
  static const _storage = FlutterSecureStorage();
  static String? _cached;

  /// Returns the stable device ID, generating one if it doesn't exist yet.
  static Future<String> getOrCreate() async {
    if (_cached != null) return _cached!;
    final existing = await _storage.read(key: _storageKey);
    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }
    final newId = _generateUUID();
    await _storage.write(key: _storageKey, value: newId);
    _cached = newId;
    return newId;
  }

  /// Generates a cryptographically random UUID v4.
  static String _generateUUID() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));

    // Set version 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant bits
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
