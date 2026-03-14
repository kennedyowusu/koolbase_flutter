/// The full bootstrap payload returned by the Koolbase API.
class HatchwayPayload {
  final String payloadVersion;
  final Map<String, HatchwayFlag> flags;
  final Map<String, dynamic> config;
  final HatchwayVersionPolicy version;

  const HatchwayPayload({
    required this.payloadVersion,
    required this.flags,
    required this.config,
    required this.version,
  });

  factory HatchwayPayload.fromJson(Map<String, dynamic> json) {
    final rawFlags = json['flags'] as Map<String, dynamic>? ?? {};
    final rawConfig = json['config'] as Map<String, dynamic>? ?? {};
    final rawVersion = json['version'] as Map<String, dynamic>? ?? {};

    return HatchwayPayload(
      payloadVersion: json['payload_version'] as String? ?? '',
      flags: rawFlags.map(
        (key, value) => MapEntry(
          key,
          HatchwayFlag.fromJson(value as Map<String, dynamic>),
        ),
      ),
      config: rawConfig,
      version: HatchwayVersionPolicy.fromJson(rawVersion),
    );
  }

  Map<String, dynamic> toJson() => {
        'payload_version': payloadVersion,
        'flags': flags.map((k, v) => MapEntry(k, v.toJson())),
        'config': config,
        'version': version.toJson(),
      };

  static HatchwayPayload empty() => HatchwayPayload(
        payloadVersion: '',
        flags: {},
        config: {},
        version: HatchwayVersionPolicy.empty(),
      );
}

/// A single feature flag rule.
/// SDK evaluates: stableHash(deviceId + ":" + flagKey) % 100 < rolloutPercentage
class HatchwayFlag {
  final bool enabled;
  final int rolloutPercentage;
  final bool killSwitch;

  const HatchwayFlag({
    required this.enabled,
    required this.rolloutPercentage,
    required this.killSwitch,
  });

  factory HatchwayFlag.fromJson(Map<String, dynamic> json) => HatchwayFlag(
        enabled: json['enabled'] as bool? ?? false,
        rolloutPercentage: json['rollout_percentage'] as int? ?? 0,
        killSwitch: json['kill_switch'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'rollout_percentage': rolloutPercentage,
        'kill_switch': killSwitch,
      };
}

/// Version policy for forced/soft update enforcement.
class HatchwayVersionPolicy {
  final String latestVersion; // latest_version from API
  final String minVersion; // min_version from API
  final bool forceUpdate; // force_update from API (boolean)
  final String updateMessage;

  const HatchwayVersionPolicy({
    required this.latestVersion,
    required this.minVersion,
    required this.forceUpdate,
    required this.updateMessage,
  });

  factory HatchwayVersionPolicy.fromJson(Map<String, dynamic> json) =>
      HatchwayVersionPolicy(
        latestVersion: json['latest_version'] as String? ?? '',
        minVersion: json['min_version'] as String? ?? '',
        forceUpdate: json['force_update'] as bool? ?? false,
        updateMessage: json['update_message'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'latest_version': latestVersion,
        'min_version': minVersion,
        'force_update': forceUpdate,
        'update_message': updateMessage,
      };

  static HatchwayVersionPolicy empty() => const HatchwayVersionPolicy(
        latestVersion: '',
        minVersion: '',
        forceUpdate: false,
        updateMessage: '',
      );
}

/// Result of a version check.
enum VersionStatus { upToDate, softUpdate, forceUpdate }

class VersionCheckResult {
  final VersionStatus status;
  final String message;
  final String latestVersion;

  const VersionCheckResult({
    required this.status,
    required this.message,
    required this.latestVersion,
  });
}
