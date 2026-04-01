import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'bundle_cache.dart';
import 'bundle_model.dart';
import 'bundle_verifier.dart';

class KoolbaseUpdater {
  final String baseUrl;
  final String apiKey;
  final BundleCache cache;
  final BundleVerifier verifier;

  static const _tag = '[KoolbaseUpdater]';

  const KoolbaseUpdater({
    required this.baseUrl,
    required this.apiKey,
    required this.cache,
    required this.verifier,
  });

  Future<UpdaterResult> check({
    required String appVersion,
    required String platform,
    required String channel,
    required String deviceId,
    required int currentBundle,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/v1/code-push/check').replace(
        queryParameters: {
          'app_version': appVersion,
          'platform': platform,
          'channel': channel,
          'device_id': deviceId,
          'current_bundle': currentBundle.toString(),
        },
      );

      final res = await http
          .get(uri, headers: {'x-api-key': apiKey})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return UpdaterResult.noUpdate();

      final body = CheckResponse.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);

      switch (body.status) {
        case 'update_available':
          return await _download(body.bundle!);
        case 'rollback':
          return UpdaterResult.rollback(revertTo: body.revertTo ?? 0);
        default:
          return UpdaterResult.noUpdate();
      }
    } catch (e) {
      // Server unreachable — continue silently on current bundle
      debugPrint('$_tag check failed silently: $e');
      return UpdaterResult.noUpdate();
    }
  }

  Future<UpdaterResult> _download(BundleRef ref) async {
    try {
      debugPrint('$_tag downloading bundle v${ref.version}...');
      final res = await http
          .get(Uri.parse(ref.downloadUrl))
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        debugPrint('$_tag download failed: ${res.statusCode}');
        return UpdaterResult.noUpdate();
      }

      final bytes = res.bodyBytes;
      debugPrint('$_tag downloaded ${bytes.length} bytes');

      // Write to pending
      final file = await cache.write(CacheSlot.pending, ref.bundleId, bytes);

      // Verify checksum
      final result = await verifier.verify(file, ref.checksum);
      if (!result.passed) {
        debugPrint('$_tag verification failed: ${result.reason}');
        await cache.delete(CacheSlot.pending, ref.bundleId);
        return UpdaterResult.noUpdate();
      }

      if (result.skipped) {
        debugPrint('$_tag checksum skipped (dev mode)');
      } else {
        debugPrint('$_tag checksum verified');
      }

      // Promote pending → ready
      await cache.promote(
        ref.bundleId,
        from: CacheSlot.pending,
        to: CacheSlot.ready,
      );

      debugPrint('$_tag bundle v${ref.version} ready for next launch');
      return UpdaterResult.readyOnNextLaunch();
    } catch (e) {
      debugPrint('$_tag download error: $e');
      await cache.delete(CacheSlot.pending, ref.bundleId);
      return UpdaterResult.noUpdate();
    }
  }

  Future<BundleManifest?> extractManifest(List<int> bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final manifestFile = archive.files.firstWhere(
        (f) => f.name == 'manifest.json',
        orElse: () => throw Exception('manifest.json not found'),
      );
      final json = jsonDecode(
        utf8.decode(manifestFile.content as List<int>),
      ) as Map<String, dynamic>;
      return BundleManifest.fromJson(json);
    } catch (e) {
      debugPrint('$_tag manifest extraction failed: $e');
      return null;
    }
  }
}

enum UpdaterStatus { noUpdate, readyOnNextLaunch, rollback }

class UpdaterResult {
  final UpdaterStatus status;
  final int? revertTo;

  const UpdaterResult._({required this.status, this.revertTo});

  factory UpdaterResult.noUpdate() =>
      const UpdaterResult._(status: UpdaterStatus.noUpdate);

  factory UpdaterResult.readyOnNextLaunch() =>
      const UpdaterResult._(status: UpdaterStatus.readyOnNextLaunch);

  factory UpdaterResult.rollback({required int revertTo}) =>
      UpdaterResult._(status: UpdaterStatus.rollback, revertTo: revertTo);
}
