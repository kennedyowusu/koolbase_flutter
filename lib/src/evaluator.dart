import 'dart:convert';
import 'package:crypto/crypto.dart';

class RolloutEvaluator {
  /// Returns true if the flag is enabled for the given device.
  static bool isEnabled({
    required String deviceId,
    required String flagKey,
    required bool flagEnabled,
    required int rolloutPercentage,
    required bool killSwitch,
  }) {
    // Kill switch overrides everything
    if (killSwitch) return false;

    // Flag must be enabled at the top level
    if (!flagEnabled) return false;

    // 100% rollout — skip hashing
    if (rolloutPercentage >= 100) return true;

    // 0% rollout — skip hashing
    if (rolloutPercentage <= 0) return false;

    // Compute deterministic bucket for this device + flag combination
    final bucket = _stableHash('$deviceId:$flagKey') % 100;
    return bucket < rolloutPercentage;
  }

  /// Computes a stable integer hash from a string.
  /// Uses SHA-256 for strong distribution — same input always produces same output.
  static int _stableHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);

    // Take first 4 bytes as an unsigned integer
    final b = digest.bytes;
    return ((b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]).abs();
  }
}
