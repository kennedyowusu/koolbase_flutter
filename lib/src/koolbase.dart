import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'cache.dart';
import 'device_id.dart';
import 'evaluator.dart';
import 'payload.dart';
export 'payload.dart';

/// Configuration for the Koolbase SDK.
class KoolbaseConfig {
  /// Your environment public key (e.g. pk_live_xxxx or pk_test_xxxx)
  final String publicKey;

  /// Base URL of your Koolbase API instance
  final String baseUrl;

  /// How often the SDK refreshes the bootstrap payload in the background.
  /// Defaults to 60 seconds.
  final Duration refreshInterval;

  const KoolbaseConfig({
    required this.publicKey,
    required this.baseUrl,
    this.refreshInterval = const Duration(seconds: 60),
  });
}

/// The main Koolbase SDK client.
///
/// Usage:
/// ```dart
/// await Koolbase.initialize(KoolbaseConfig(
///   publicKey: 'pk_live_xxxx',
///   baseUrl: 'https://api.koolbase.com',
/// ));
///
/// // Check a flag
/// if (Koolbase.isEnabled('new_swap_flow')) {
///   // show new flow
/// }
///
/// // Read config
/// final timeout = Koolbase.configInt('swap_timeout_seconds', fallback: 30);
/// ```
class Koolbase {
  static Koolbase? _instance;

  final KoolbaseConfig _config;
  KoolbasePayload _payload;
  String _deviceId = '';
  String _appVersion = '';
  String _platform = '';

  Koolbase._(this._config, this._payload);

  /// Initializes the SDK. Call this in main() before runApp().
  ///
  /// 1. Loads cached payload immediately (instant startup)
  /// 2. Fetches fresh payload from API in background
  /// 3. Starts background refresh polling
  static Future<void> initialize(KoolbaseConfig config) async {
    final deviceId = await DeviceIdManager.getOrCreate();
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;
    final platform = _getPlatform();

    // Load cached payload immediately — app doesn't wait for network
    final cached = await KoolbaseCache.load();
    final payload = cached ?? KoolbasePayload.empty();

    final instance = Koolbase._(config, payload);
    instance._deviceId = deviceId;
    instance._appVersion = appVersion;
    instance._platform = platform;
    _instance = instance;

    // Fetch fresh payload in background — non-blocking
    instance._fetchAndUpdate();

    // Start background polling
    instance._startPolling();
  }

  static Koolbase get _client {
    assert(
      _instance != null,
      'Koolbase not initialized. Call Koolbase.initialize() first.',
    );
    return _instance!;
  }

  // ─── Flag Evaluation ───────────────────────────────────────────────────────

  /// Returns true if the feature flag is enabled for the current device.
  static bool isEnabled(String flagKey) {
    final client = _client;
    final flag = client._payload.flags[flagKey];
    if (flag == null) return false;
    return RolloutEvaluator.isEnabled(
      deviceId: client._deviceId,
      flagKey: flagKey,
      flagEnabled: flag.enabled,
      rolloutPercentage: flag.rolloutPercentage,
      killSwitch: flag.killSwitch,
    );
  }

  // ─── Config Access ─────────────────────────────────────────────────────────

  /// Returns a config value as a String.
  static String configString(String key, {String fallback = ''}) {
    final value = _client._payload.config[key];
    if (value == null) return fallback;
    return value.toString();
  }

  /// Returns a config value as an int.
  static int configInt(String key, {int fallback = 0}) {
    final value = _client._payload.config[key];
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  /// Returns a config value as a double.
  static double configDouble(String key, {double fallback = 0.0}) {
    final value = _client._payload.config[key];
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  /// Returns a config value as a bool.
  static bool configBool(String key, {bool fallback = false}) {
    final value = _client._payload.config[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    return value.toString() == 'true';
  }

  /// Returns a config value as a Map (for JSON objects).
  static Map<String, dynamic> configMap(String key,
      {Map<String, dynamic> fallback = const {}}) {
    final value = _client._payload.config[key];
    if (value == null) return fallback;
    if (value is Map<String, dynamic>) return value;
    return fallback;
  }

  // ─── Version Policy ────────────────────────────────────────────────────────

  /// Checks the current app version against the version policy.
  static VersionCheckResult checkVersion() {
    final client = _client;
    final policy = client._payload.version;

    if (policy.minVersion.isEmpty) {
      return const VersionCheckResult(
        status: VersionStatus.upToDate,
        message: '',
        latestVersion: '',
      );
    }

    final current = _parseVersion(client._appVersion);
    final minVersion = _parseVersion(policy.minVersion);
    final latestVersion = _parseVersion(policy.latestVersion);

    // Below minimum — always force update
    if (current < minVersion) {
      return VersionCheckResult(
        status: VersionStatus.forceUpdate,
        message: policy.updateMessage,
        latestVersion: policy.latestVersion,
      );
    }

    // Below latest — soft or force depending on policy
    if (policy.latestVersion.isNotEmpty && current < latestVersion) {
      return VersionCheckResult(
        status: policy.forceUpdate
            ? VersionStatus.forceUpdate
            : VersionStatus.softUpdate,
        message: policy.updateMessage,
        latestVersion: policy.latestVersion,
      );
    }

    return VersionCheckResult(
      status: VersionStatus.upToDate,
      message: '',
      latestVersion: policy.latestVersion,
    );
  }

  // ─── Payload Info ──────────────────────────────────────────────────────────

  /// Returns the current payload version hash. Useful for debugging.
  static String get payloadVersion => _client._payload.payloadVersion;

  /// Returns the stable device ID for this installation.
  static String get deviceId => _client._deviceId;

  // ─── Internal ──────────────────────────────────────────────────────────────

  Future<void> _fetchAndUpdate() async {
    try {
      final uri = Uri.parse('${_config.baseUrl}/v1/bootstrap').replace(
        queryParameters: {
          'public_key': _config.publicKey,
          'device_id': _deviceId,
          'platform': _platform,
          'app_version': _appVersion,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final freshPayload = KoolbasePayload.fromJson(json);

        // Only update if payload actually changed
        if (freshPayload.payloadVersion != _payload.payloadVersion) {
          _payload = freshPayload;
          await KoolbaseCache.save(freshPayload);
          debugPrint(
              '[Koolbase] Payload updated: ${freshPayload.payloadVersion}');
        } else {
          debugPrint(
              '[Koolbase] Payload unchanged: ${freshPayload.payloadVersion}');
        }
      }
    } on SocketException {
      debugPrint('[Koolbase] Offline — using cached payload');
    } catch (e) {
      debugPrint('[Koolbase] Bootstrap fetch failed: $e');
    }
  }

  void _startPolling() {
    Future.doWhile(() async {
      await Future.delayed(_config.refreshInterval);
      if (_instance == null) return false;
      await _fetchAndUpdate();
      return true;
    });
  }

  static String _getPlatform() {
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'flutter'; // web or unknown
  }

  static int _parseVersion(String version) {
    if (version.isEmpty) return 0;
    final parts = version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final major = parts.isNotEmpty ? parts[0] : 0;
    final minor = parts.length > 1 ? parts[1] : 0;
    final patch = parts.length > 2 ? parts[2] : 0;
    return major * 10000 + minor * 100 + patch;
  }
}
