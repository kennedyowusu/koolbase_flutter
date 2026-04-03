import 'package:flutter/foundation.dart';
import 'bundle_cache.dart';
import 'flow_executor.dart';
import 'flow_models.dart';
import '../rfw/screen_resolver.dart';
import '../rfw/rfw_models.dart';
import 'bundle_loader.dart';
import 'bundle_model.dart';
import 'bundle_verifier.dart';
import 'runtime_override.dart';
import 'updater.dart';

class KoolbaseCodePushClient implements KoolbaseScreenClient {
  final String baseUrl;
  final String apiKey;
  final String channel;

  late final BundleCache _cache;
  late final KoolbaseUpdater _updater;
  late final BundleLoader _loader;
  final RuntimeOverrideEngine _override = RuntimeOverrideEngine();

  BundleManifest? _activeManifest;
  bool _initialized = false;
  late final ScreenResolver _screenResolver;

  static const _tag = '[KoolbaseCodePush]';

  KoolbaseCodePushClient({
    required this.baseUrl,
    required this.apiKey,
    this.channel = 'stable',
  });

  RuntimeOverrideEngine get override => _override;
  BundleManifest? get activeManifest => _activeManifest;
  bool get hasActiveBundle => _activeManifest != null;

  Future<void> init({
    required String appVersion,
    required String platform,
    required String deviceId,
    required Map<String, dynamic> remoteConfig,
    required Map<String, dynamic> remoteFlags,
  }) async {
    if (_initialized) return;

    _cache = await BundleCache.init();
    _screenResolver = ScreenResolver(cache: _cache);
    _updater = KoolbaseUpdater(
      baseUrl: baseUrl,
      apiKey: apiKey,
      cache: _cache,
      verifier: const BundleVerifier(),
    );
    _loader = BundleLoader(cache: _cache, updater: _updater);

    final currentVersion = await _loader.activeVersion();
    _activeManifest = await _loader.load();

    if (_activeManifest != null) {
      _override.apply(
        manifest: _activeManifest!,
        remoteConfig: remoteConfig,
        remoteFlags: remoteFlags,
      );
      debugPrint('$_tag bundle v${_activeManifest!.version} active');
      _screenResolver.invalidate();
    } else {
      debugPrint('$_tag no active bundle — using app defaults');
    }

    _initialized = true;

    _checkInBackground(
      appVersion: appVersion,
      platform: platform,
      deviceId: deviceId,
      currentBundle: currentVersion,
    );
  }

  final FlowExecutor _flowExecutor = FlowExecutor();

  // ignore: annotate_overrides
  Future<ScreenLookupResult> resolveScreen(String screenId) {
    return _screenResolver.resolve(screenId, _activeManifest);
  }

  void _checkInBackground({
    required String appVersion,
    required String platform,
    required String deviceId,
    required int currentBundle,
  }) {
    Future(() async {
      final result = await _updater.check(
        appVersion: appVersion,
        platform: platform,
        channel: channel,
        deviceId: deviceId,
        currentBundle: currentBundle,
      );

      switch (result.status) {
        case UpdaterStatus.readyOnNextLaunch:
          debugPrint('$_tag update downloaded — will activate on next launch');
          break;
        case UpdaterStatus.rollback:
          debugPrint('$_tag rollback to v${result.revertTo} on next launch');
          break;
        case UpdaterStatus.noUpdate:
          debugPrint('$_tag no update available');
          break;
      }
    });
  }

  // ignore: annotate_overrides
  FlowResult executeFlow({
    required String flowId,
    Map<String, dynamic>? context,
  }) {
    if (_activeManifest == null) {
      return FlowResult.noEvent();
    }
    final ctx = FlowContext(
      context: context,
      config: _activeManifest!.payload.config,
      flags: _activeManifest!.payload.flags,
    );
    return _flowExecutor.execute(
      flowId: flowId,
      flows: _activeManifest!.payload.flows,
      ctx: ctx,
    );
  }

  void onDirective(String key, void Function(dynamic value) handler) {
    _override.registerDirectiveHandler(key, handler);
  }
}
