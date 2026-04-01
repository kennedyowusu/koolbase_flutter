import 'package:flutter/foundation.dart';
import 'bundle_cache.dart';
import 'bundle_model.dart';
import 'updater.dart';

class BundleLoader {
  final BundleCache cache;
  final KoolbaseUpdater updater;

  static const _tag = '[BundleLoader]';

  const BundleLoader({required this.cache, required this.updater});

  /// Runs on every cold launch before first frame.
  /// Promotes ready → active, handles rollback, returns active manifest.
  Future<BundleManifest?> load({int? revertTo}) async {
    // Handle rollback instruction from server
    if (revertTo != null) {
      await _handleRollback(revertTo);
    }

    // Promote ready → active if available
    await _promoteIfReady();

    // Load and return active manifest
    return await _loadActive();
  }

  Future<void> _promoteIfReady() async {
    final readyFile = await cache.slotFile(CacheSlot.ready);
    if (readyFile == null) return;

    final bundleId = cache.bundleIdFromFile(readyFile);

    try {
      // Archive current active first
      await _archiveCurrent();

      // Promote ready → active
      await cache.promote(bundleId,
          from: CacheSlot.ready, to: CacheSlot.active);

      debugPrint('$_tag promoted bundle $bundleId to active');
    } catch (e) {
      // Promotion failed — delete bad ready bundle, trigger one re-check
      debugPrint('$_tag promotion failed: $e');
      await cache.delete(CacheSlot.ready, bundleId);

      // One immediate re-check, non-blocking
      // params will be filled by the caller context
    }
  }

  Future<void> _archiveCurrent() async {
    final activeFile = await cache.slotFile(CacheSlot.active);
    if (activeFile == null) return;

    final bundleId = cache.bundleIdFromFile(activeFile);

    // Clear old archive — keep exactly one version back
    final archiveFile = await cache.slotFile(CacheSlot.archive);
    if (archiveFile != null) {
      await archiveFile.delete();
    }

    await cache.promote(bundleId,
        from: CacheSlot.active, to: CacheSlot.archive);

    debugPrint('$_tag archived bundle $bundleId');
  }

  Future<void> _handleRollback(int revertTo) async {
    debugPrint('$_tag handling rollback to v$revertTo');

    // Delete current active
    final activeFile = await cache.slotFile(CacheSlot.active);
    if (activeFile != null) {
      final bundleId = cache.bundleIdFromFile(activeFile);
      await cache.delete(CacheSlot.active, bundleId);
    }

    if (revertTo == 0) {
      // Revert to app defaults — no bundle
      debugPrint('$_tag reverting to app defaults');
      return;
    }

    // Try to restore from archive
    final archiveFile = await cache.slotFile(CacheSlot.archive);
    if (archiveFile != null) {
      final bundleId = cache.bundleIdFromFile(archiveFile);
      await cache.promote(bundleId,
          from: CacheSlot.archive, to: CacheSlot.active);
      debugPrint('$_tag restored bundle $bundleId from archive');
    }
  }

  Future<BundleManifest?> _loadActive() async {
    final activeFile = await cache.slotFile(CacheSlot.active);
    if (activeFile == null) return null;

    try {
      final bytes = await activeFile.readAsBytes();
      return await updater.extractManifest(bytes);
    } catch (e) {
      debugPrint('$_tag failed to load active bundle: $e');
      return null;
    }
  }

  Future<int> activeVersion() async {
    final activeFile = await cache.slotFile(CacheSlot.active);
    if (activeFile == null) return 0;
    try {
      final bytes = await activeFile.readAsBytes();
      final manifest = await updater.extractManifest(bytes);
      return manifest?.version ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
