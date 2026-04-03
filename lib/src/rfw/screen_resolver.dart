import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import '../code_push/bundle_cache.dart';
import '../code_push/bundle_model.dart';
import 'rfw_models.dart';

class ScreenResolver {
  final BundleCache cache;

  Archive? _cachedArchive;
  String? _cachedBundleId;

  ScreenResolver({required this.cache});

  Future<ScreenLookupResult> resolve(
    String screenId,
    BundleManifest? activeManifest,
  ) async {
    // Step 1 — no active bundle
    if (activeManifest == null) {
      debugPrint('[ScreenResolver] no active bundle for: $screenId');
      return ScreenLookupResult.noBundle();
    }

    // Step 2 — screen not in manifest
    final filename = activeManifest.payload.screens[screenId];
    if (filename == null) {
      debugPrint('[ScreenResolver] screen not in bundle: $screenId');
      return ScreenLookupResult.screenNotFound();
    }

    // Step 3 — get or decode archive (cached per bundle ID)
    final archive = await _getArchive(activeManifest.bundleId);
    if (archive == null) {
      return ScreenLookupResult.fileNotFound();
    }

    // Step 4 — extract rfw file
    try {
      final rfwFile = archive.files.firstWhere(
        (f) => f.name == 'screens/$filename',
        orElse: () =>
            throw Exception('screens/$filename not found in bundle zip'),
      );
      final rfwBytes = rfwFile.content as List<int>;
      debugPrint(
        '[ScreenResolver] resolved $screenId (${rfwBytes.length} bytes)',
      );
      return ScreenLookupResult.found(rfwBytes);
    } catch (e) {
      debugPrint('[ScreenResolver] extract error for $screenId: $e');
      return ScreenLookupResult.parseError();
    }
  }

  Future<Archive?> _getArchive(String bundleId) async {
    // Return cached archive if same bundle
    if (_cachedBundleId == bundleId && _cachedArchive != null) {
      return _cachedArchive;
    }

    final activeFile = await cache.slotFile(CacheSlot.active);
    if (activeFile == null) return null;

    try {
      final bytes = await activeFile.readAsBytes();
      _cachedArchive = ZipDecoder().decodeBytes(bytes);
      _cachedBundleId = bundleId;
      return _cachedArchive;
    } catch (e) {
      debugPrint('[ScreenResolver] zip decode error: $e');
      return null;
    }
  }

  /// Invalidate cache when a new bundle is activated
  void invalidate() {
    _cachedArchive = null;
    _cachedBundleId = null;
  }
}
