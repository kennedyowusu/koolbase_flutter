import 'package:flutter/foundation.dart';
import 'bundle_model.dart';

/// Merges a bundle payload into the runtime.
/// Called synchronously before the first frame renders.
///
/// Precedence (highest wins):
///   app defaults → Remote Config/Flags → Runtime Bundle
class RuntimeOverrideEngine {
  // Merged config — bundle keys override remote config
  final Map<String, dynamic> _config = {};

  // Merged flags — bundle flags override feature flags
  final Map<String, bool> _flags = {};

  static const _tag = '[RuntimeOverride]';

  /// Apply bundle onto existing remote config and flags.
  /// Only keys present in the bundle are overridden — surgical, not a full wipe.
  void apply({
    required BundleManifest manifest,
    required Map<String, dynamic> remoteConfig,
    required Map<String, dynamic> remoteFlags,
  }) {
    // Start with remote values as base
    _config.addAll(remoteConfig);
    _flags.addAll(remoteFlags.map((k, v) => MapEntry(k, v as bool? ?? false)));

    // Override with bundle values
    _config.addAll(manifest.payload.config);
    _flags.addAll(manifest.payload.flags);

    // Execute directives — fire-once commands
    _applyDirectives(manifest.payload.directives);

    debugPrint('$_tag applied bundle v${manifest.version}');
    debugPrint('$_tag config overrides: ${manifest.payload.config.keys.toList()}');
    debugPrint('$_tag flag overrides:   ${manifest.payload.flags.keys.toList()}');
  }

  void _applyDirectives(Map<String, dynamic> directives) {
    for (final entry in directives.entries) {
      debugPrint('$_tag directive: ${entry.key} = ${entry.value}');
      // v1: directives are fire-once — consumers register handlers externally
      _directiveHandlers[entry.key]?.call(entry.value);
    }
  }

  // External directive handlers — registered by the app
  final Map<String, void Function(dynamic)> _directiveHandlers = {};

  void registerDirectiveHandler(
      String key, void Function(dynamic value) handler) {
    _directiveHandlers[key] = handler;
  }

  // ─── Value Access ──────────────────────────────────────────────────────────

  dynamic getConfig(String key) => _config[key];

  bool getFlag(String key, {bool fallback = false}) =>
      _flags[key] ?? fallback;

  Map<String, dynamic> get allConfig => Map.unmodifiable(_config);
  Map<String, bool> get allFlags => Map.unmodifiable(_flags);

  void reset() {
    _config.clear();
    _flags.clear();
  }
}
