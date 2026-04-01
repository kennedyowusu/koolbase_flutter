import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum CacheSlot { pending, ready, active, archive }

class BundleCache {
  static BundleCache? _instance;
  late final Directory _root;

  BundleCache._();

  static Future<BundleCache> init() async {
    if (_instance != null) return _instance!;
    final base = await getApplicationSupportDirectory();
    final cache = BundleCache._();
    cache._root = Directory('${base.path}/koolbase/code_push');
    for (final slot in CacheSlot.values) {
      await Directory('${cache._root.path}/${slot.name}')
          .create(recursive: true);
    }
    _instance = cache;
    return cache;
  }

  Directory _dir(CacheSlot slot) =>
      Directory('${_root.path}/${slot.name}');

  File _file(CacheSlot slot, String bundleId) =>
      File('${_dir(slot).path}/$bundleId.zip');

  Future<bool> exists(CacheSlot slot, String bundleId) =>
      _file(slot, bundleId).exists();

  Future<File> write(CacheSlot slot, String bundleId, List<int> bytes) async {
    final file = _file(slot, bundleId);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File?> get(CacheSlot slot, String bundleId) async {
    final file = _file(slot, bundleId);
    return await file.exists() ? file : null;
  }

  Future<void> promote(
    String bundleId, {
    required CacheSlot from,
    required CacheSlot to,
  }) async {
    final src = _file(from, bundleId);
    final dst = _file(to, bundleId);
    await src.rename(dst.path);
  }

  Future<void> delete(CacheSlot slot, String bundleId) async {
    final file = _file(slot, bundleId);
    if (await file.exists()) await file.delete();
  }

  // Returns the single zip file in a slot, or null
  Future<File?> slotFile(CacheSlot slot) async {
    final files = await _dir(slot)
        .list()
        .where((f) => f.path.endsWith('.zip'))
        .toList();
    if (files.isEmpty) return null;
    return File(files.first.path);
  }

  String bundleIdFromFile(File file) =>
      file.uri.pathSegments.last.replaceAll('.zip', '');

  // Clear all slots — used for testing
  Future<void> clearAll() async {
    for (final slot in CacheSlot.values) {
      final dir = _dir(slot);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
    }
  }
}
