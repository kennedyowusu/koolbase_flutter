import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'auth/auth_api.dart';
import 'ota/ota_client.dart';
import 'functions/functions_client.dart';
export 'ota/ota_models.dart';
import 'storage/storage_client.dart';
import 'database/database_client.dart';
import 'database/offline/local_database.dart';
import 'database/offline/cache_store.dart';
import 'database/offline/write_queue.dart';
import 'database/sync_engine.dart';
import 'realtime/realtime_client.dart';
export 'realtime/realtime_models.dart';
export 'database/database_models.dart';
export 'database/database_query.dart' show KoolbaseQuery;
export 'storage/storage_models.dart';
import 'auth/auth_client.dart';
import 'auth/auth_storage.dart';
import 'cache.dart';
import 'device_id.dart';
import 'evaluator.dart';
import 'payload.dart';
export 'payload.dart';
export 'auth/auth_models.dart';
export 'auth/auth_exceptions.dart';

/// Configuration for the Koolbase SDK.
class KoolbaseConfig {
  /// Your environment public key (e.g. pk_live_xxxx or pk_test_xxxx)
  final String publicKey;

  /// Base URL of your Koolbase API instance
  final String baseUrl;

  /// How often the SDK refreshes the bootstrap payload in the background.
  final Duration refreshInterval;

  const KoolbaseConfig({
    required this.publicKey,
    required this.baseUrl,
    this.refreshInterval = const Duration(seconds: 60),
  });
}

/// The main Koolbase SDK client.
class Koolbase {
  static Koolbase? _instance;
  static KoolbaseAuthClient? _auth;
  static KoolbaseStorageClient? _storage;
  static KoolbaseDatabaseClient? _database;
  static KoolbaseRealtimeClient? _realtime;
  static KoolbaseOtaClient? _ota;
  static KoolbaseFunctionsClient? _functions;
  static KoolbaseLocalDatabase? _localDb;
  static SyncEngine? _syncEngine;
  static bool _initialized = false;

  final KoolbaseConfig _config;
  KoolbasePayload _payload;
  String _deviceId = '';
  String _appVersion = '';
  String _platform = '';

  Koolbase._(this._config, this._payload);

  /// Initializes the SDK. Call this in main() before runApp().
  static Future<void> initialize(KoolbaseConfig config) async {
    if (_initialized) return;

    final deviceId = await DeviceIdManager.getOrCreate();
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;
    final platform = _getPlatform();

    // Load cached payload immediately
    final cached = await KoolbaseCache.load();
    final payload = cached ?? KoolbasePayload.empty();

    final instance = Koolbase._(config, payload);
    instance._deviceId = deviceId;
    instance._appVersion = appVersion;
    instance._platform = platform;
    _instance = instance;

    // Initialize auth client
    final authApi = AuthApi(
      baseUrl: config.baseUrl,
      publicKey: config.publicKey,
    );
    _auth = KoolbaseAuthClient(
      api: authApi,
      storage: AuthStorage(),
    );

    // Restore auth session from secure storage
    await _auth!.restoreSession();

    // Initialize realtime client
    _realtime = KoolbaseRealtimeClient(
      baseUrl: config.baseUrl,
      publicKey: config.publicKey,
    );

    // Initialize offline database (Drift)
    _localDb = KoolbaseLocalDatabase();
    final cacheStore = CacheStore(_localDb!);
    final writeQueue = WriteQueue(_localDb!);

    // Initialize database client with offline support
    _database = KoolbaseDatabaseClient(
      baseUrl: config.baseUrl,
      publicKey: config.publicKey,
      cacheStore: cacheStore,
      writeQueue: writeQueue,
    );

    // Initialize sync engine — auto-syncs on reconnect
    _syncEngine = SyncEngine(
      baseUrl: config.baseUrl,
      publicKey: config.publicKey,
      cacheStore: cacheStore,
      writeQueue: writeQueue,
    );
    _syncEngine!.start();

    // Initialize storage client
    _storage = KoolbaseStorageClient(
      baseUrl: config.baseUrl,
      publicKey: config.publicKey,
    );

    // Initialize functions client
    _functions = KoolbaseFunctionsClient(
      baseUrl: config.baseUrl,
      publicKey: config.publicKey,
    );

    // Initialize OTA client
    _ota = KoolbaseOtaClient(
      baseUrl: config.baseUrl,
      publicKey: config.publicKey,
    );

    // Fetch fresh flags in background
    instance._fetchAndUpdate();
    instance._startPolling();

    _initialized = true;
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'Koolbase has not been initialized. '
        'Call Koolbase.initialize() first.',
      );
    }
  }

  static Koolbase get _client {
    _ensureInitialized();
    return _instance!;
  }

  /// Access the realtime client
  static KoolbaseRealtimeClient get realtime {
    _ensureInitialized();
    return _realtime!;
  }

  /// Access the database client
  static KoolbaseDatabaseClient get db {
    _ensureInitialized();
    return _database!;
  }

  /// Access the storage client
  static KoolbaseStorageClient get storage {
    _ensureInitialized();
    return _storage!;
  }

  /// Access the OTA updates client
  static KoolbaseOtaClient get ota {
    _ensureInitialized();
    return _ota!;
  }

  /// Access the functions client
  static KoolbaseFunctionsClient get functions {
    _ensureInitialized();
    return _functions!;
  }

  /// Access the auth client
  static KoolbaseAuthClient get auth {
    _ensureInitialized();
    return _auth!;
  }

  // ─── Flag Evaluation ───────────────────────────────────────────────────────

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

  static String configString(String key, {String fallback = ''}) {
    final value = _client._payload.config[key];
    if (value == null) return fallback;
    return value.toString();
  }

  static int configInt(String key, {int fallback = 0}) {
    final value = _client._payload.config[key];
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double configDouble(String key, {double fallback = 0.0}) {
    final value = _client._payload.config[key];
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static bool configBool(String key, {bool fallback = false}) {
    final value = _client._payload.config[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    return value.toString() == 'true';
  }

  static Map<String, dynamic> configMap(String key,
      {Map<String, dynamic> fallback = const {}}) {
    final value = _client._payload.config[key];
    if (value == null) return fallback;
    if (value is Map<String, dynamic>) return value;
    return fallback;
  }

  // ─── Version Policy ────────────────────────────────────────────────────────

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

    if (current < minVersion) {
      return VersionCheckResult(
        status: VersionStatus.forceUpdate,
        message: policy.updateMessage,
        latestVersion: policy.latestVersion,
      );
    }

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

  static String get payloadVersion => _client._payload.payloadVersion;
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
    return 'flutter';
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
