import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ota_models.dart';

/// Manages OTA bundle downloads and applies them to the app's local storage.
///
/// Usage:
/// ```dart
/// // Auto-initializes on Koolbase.initialize()
/// final result = await Koolbase.ota.check();
/// if (result.hasUpdate) {
///   await Koolbase.ota.download();
/// }
///
/// // Read a file from the active bundle
/// final config = await Koolbase.ota.readJson('config.json');
/// final path = await Koolbase.ota.getFilePath('banner.png');
/// ```
class KoolbaseOtaClient {
  final String _baseUrl;
  final String _publicKey;

  static const _prefVersionKey = 'koolbase_ota_version';
  static const _prefChecksumKey = 'koolbase_ota_checksum';
  static const _bundleDirName = 'koolbase_ota_bundle';

  KoolbaseOtaClient({
    required String baseUrl,
    required String publicKey,
  })  : _baseUrl = baseUrl,
        _publicKey = publicKey;

  /// Returns the currently cached bundle version. 0 if none cached.
  Future<int> get currentVersion async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefVersionKey) ?? 0;
  }

  /// Returns the checksum of the currently cached bundle. Empty string if none.
  Future<String> get currentChecksum async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefChecksumKey) ?? '';
  }

  /// Checks the server for a newer bundle on the given channel.
  ///
  /// Returns [OtaCheckResult.noUpdate] if no newer bundle exists or on error.
  Future<OtaCheckResult> check({String channel = 'production'}) async {
    try {
      final version = await currentVersion;
      final uri = Uri.parse('$_baseUrl/v1/sdk/ota/check').replace(
        queryParameters: {
          'channel': channel,
          'version': version.toString(),
        },
      );

      final response = await http.get(uri, headers: {
        'x-api-key': _publicKey,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return OtaCheckResult.fromJson(json);
      }
    } catch (e) {
      debugPrint('[Koolbase OTA] Check failed: $e');
    }
    return OtaCheckResult.noUpdate();
  }

  /// Downloads and extracts a bundle from [result].
  ///
  /// Emits [OtaProgress] events via [onProgress].
  /// Returns true if successful.
  Future<bool> download(
    OtaCheckResult result, {
    void Function(OtaProgress)? onProgress,
  }) async {
    if (!result.hasUpdate || result.downloadUrl == null) return false;

    onProgress?.call(const OtaProgress(state: OtaDownloadState.downloading));

    try {
      // Download the bundle zip
      final response = await http.get(Uri.parse(result.downloadUrl!));

      if (response.statusCode != 200) {
        onProgress?.call(const OtaProgress(
          state: OtaDownloadState.failed,
          error: 'Download failed',
        ));
        return false;
      }

      final bytes = response.bodyBytes;

      // Verify checksum
      onProgress?.call(const OtaProgress(state: OtaDownloadState.verifying));

      if (result.checksum != null && result.checksum!.isNotEmpty) {
        final verified = await _verifyChecksum(bytes, result.checksum!);
        if (!verified) {
          onProgress?.call(const OtaProgress(
            state: OtaDownloadState.failed,
            error: 'Checksum verification failed',
          ));
          return false;
        }
      }

      // Extract to app documents directory
      onProgress?.call(const OtaProgress(state: OtaDownloadState.extracting));

      final bundleDir = await _getBundleDir();

      // Clear old bundle
      if (await bundleDir.exists()) {
        await bundleDir.delete(recursive: true);
      }
      await bundleDir.create(recursive: true);

      // Extract zip
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final outFile = File('${bundleDir.path}/$filename');
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      // Save version and checksum
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefVersionKey, result.version!);
      await prefs.setString(_prefChecksumKey, result.checksum ?? '');

      onProgress?.call(const OtaProgress(
        state: OtaDownloadState.ready,
        progress: 1.0,
      ));

      debugPrint('[Koolbase OTA] Bundle v${result.version} applied successfully');
      return true;
    } catch (e) {
      debugPrint('[Koolbase OTA] Download/extract failed: $e');
      onProgress?.call(OtaProgress(
        state: OtaDownloadState.failed,
        error: e.toString(),
      ));
      return false;
    }
  }

  /// Auto-checks and downloads a new bundle on app launch.
  ///
  /// If [mandatory] is true and an update is available, it will block
  /// until the download completes. Otherwise it downloads in the background.
  ///
  /// Call this in [Koolbase.initialize].
  Future<OtaCheckResult> initialize({
    String channel = 'production',
    void Function(OtaProgress)? onProgress,
  }) async {
    final result = await check(channel: channel);

    if (!result.hasUpdate) return result;

    if (result.mandatory) {
      // Mandatory — download synchronously before app proceeds
      await download(result, onProgress: onProgress);
    } else {
      // Optional — download in background
      download(result, onProgress: onProgress);
    }

    return result;
  }

  /// Reads a JSON file from the active OTA bundle.
  ///
  /// Returns null if the file doesn't exist in the bundle.
  /// Falls back gracefully — if no bundle is cached, returns null
  /// and the app should use its bundled assets.
  Future<Map<String, dynamic>?> readJson(String filename) async {
    final file = await _getBundleFile(filename);
    if (file == null) return null;

    try {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Koolbase OTA] Failed to read $filename: $e');
      return null;
    }
  }

  /// Returns the absolute file path of a file in the active OTA bundle.
  ///
  /// Returns null if the file doesn't exist in the bundle.
  Future<String?> getFilePath(String filename) async {
    final file = await _getBundleFile(filename);
    return file?.path;
  }

  /// Returns true if an OTA bundle is currently cached on this device.
  Future<bool> get hasCachedBundle async {
    final version = await currentVersion;
    if (version == 0) return false;
    final dir = await _getBundleDir();
    return dir.exists();
  }

  /// Clears the cached bundle and resets the version to 0.
  Future<void> clearBundle() async {
    final bundleDir = await _getBundleDir();
    if (await bundleDir.exists()) {
      await bundleDir.delete(recursive: true);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefVersionKey);
    await prefs.remove(_prefChecksumKey);
    debugPrint('[Koolbase OTA] Bundle cache cleared');
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

  Future<Directory> _getBundleDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    return Directory('${docDir.path}/$_bundleDirName');
  }

  Future<File?> _getBundleFile(String filename) async {
    final bundleDir = await _getBundleDir();
    if (!await bundleDir.exists()) return null;

    // Search flat and in subdirectories (zip may have a root folder)
    final direct = File('${bundleDir.path}/$filename');
    if (await direct.exists()) return direct;

    // Check one level deep (common zip pattern: bundle_name/file.json)
    final entries = await bundleDir.list().toList();
    for (final entry in entries) {
      if (entry is Directory) {
        final nested = File('${entry.path}/$filename');
        if (await nested.exists()) return nested;
      }
    }

    return null;
  }

  Future<bool> _verifyChecksum(Uint8List bytes, String expectedChecksum) async {
    try {
      // expectedChecksum format: "sha256:abc123..."
      final hash = expectedChecksum.replaceFirst('sha256:', '');
      final computed = await compute(_computeSha256, bytes);
      return computed == hash;
    } catch (e) {
      debugPrint('[Koolbase OTA] Checksum verification error: $e');
      return false;
    }
  }
}

/// Runs SHA-256 in an isolate to avoid blocking the UI thread.
String _computeSha256(Uint8List bytes) {
  final digest = sha256.convert(bytes);
  return digest.toString();
}
