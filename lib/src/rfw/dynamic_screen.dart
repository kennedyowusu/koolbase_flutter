import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';
import 'koolbase_widget_library.dart';
import 'rfw_models.dart';

class KoolbaseDynamicScreen extends StatefulWidget {
  final String screenId;
  final Map<String, Object> data;

  final void Function(String eventName, DynamicMap args)? onEvent;
  final Widget? fallback;
  final Widget? loading;
  final List<KoolbaseRfwWidget> customWidgets;

  const KoolbaseDynamicScreen({
    super.key,
    required this.screenId,
    this.data = const {},
    this.onEvent,
    this.fallback,
    this.loading,
    this.customWidgets = const [],
  });

  @override
  State<KoolbaseDynamicScreen> createState() => _KoolbaseDynamicScreenState();
}

class _KoolbaseDynamicScreenState extends State<KoolbaseDynamicScreen> {
  late final Runtime _runtime;
  bool _loading = true;
  bool _useFallback = false;
  RemoteWidgetLibrary? _remoteLibrary;

  static const _localLibName = LibraryName(['local']);
  static const _customLibName = LibraryName(['custom']);
  static const _remoteLibName = LibraryName(['remote']);
  static const _rootWidget = FullyQualifiedWidgetName(
    LibraryName(['remote']),
    'root',
  );

  @override
  void initState() {
    super.initState();
    _initRuntime();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading) return;
    _resolveScreen();
  }

  @override
  void didUpdateWidget(covariant KoolbaseDynamicScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenId != widget.screenId) {
      setState(() {
        _loading = true;
        _useFallback = false;
        _remoteLibrary = null;
      });
      _resolveScreen();
    }
  }

  void _initRuntime() {
    _runtime = Runtime();

    _runtime.update(_localLibName, createKoolbaseWidgetLibrary());

    if (widget.customWidgets.isNotEmpty) {
      _runtime.update(
        _customLibName,
        createCustomWidgetLibrary(widget.customWidgets),
      );
    }
  }

  Future<void> _resolveScreen() async {
    final scope = KoolbaseCodePushScope.of(context);
    if (scope == null) {
      _setFallback('no KoolbaseCodePushScope in widget tree');
      return;
    }

    final result = await scope.resolveScreen(widget.screenId);

    if (!mounted) return;

    if (!result.isFound) {
      _setFallback('lookup failed: ${result.status}');
      return;
    }

    // Parse rfw binary
    try {
      final library = decodeLibraryBlob(
        Uint8List.fromList(result.rfwBytes!),
      );
      _runtime.update(_remoteLibName, library);
      if (mounted) {
        setState(() {
          _remoteLibrary = library;
          _loading = false;
        });
      }
    } catch (e) {
      _setFallback('parse error: $e');
    }
  }

  void _setFallback(String reason) {
    debugPrint(
        '[KoolbaseDynamicScreen] fallback for ${widget.screenId}: $reason');
    if (mounted) {
      setState(() {
        _loading = false;
        _useFallback = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.loading ?? const SizedBox.shrink();
    }

    if (_useFallback || _remoteLibrary == null) {
      return widget.fallback ?? const SizedBox.shrink();
    }

    return _RfwErrorBoundary(
      fallback: widget.fallback ?? const SizedBox.shrink(),
      screenId: widget.screenId,
      child: RemoteWidget(
        runtime: _runtime,
        widget: _rootWidget,
        data: DynamicContent(widget.data),
        // FIX 5: correct event signature
        onEvent: widget.onEvent != null
            ? (String name, DynamicMap args) {
                try {
                  widget.onEvent!(name, args);
                } catch (e) {
                  debugPrint(
                    '[KoolbaseDynamicScreen] onEvent error [$name]: $e',
                  );
                }
              }
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }
}

// ─── Error boundary ──────────────────────────────────────────────────────────

class _RfwErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget fallback;
  final String screenId;

  const _RfwErrorBoundary({
    required this.child,
    required this.fallback,
    required this.screenId,
  });

  @override
  State<_RfwErrorBoundary> createState() => _RfwErrorBoundaryState();
}

class _RfwErrorBoundaryState extends State<_RfwErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) return widget.fallback;
    return widget.child;
  }

  @override
  void didUpdateWidget(_RfwErrorBoundary old) {
    super.didUpdateWidget(old);
    if (old.child != widget.child) {
      setState(() => _hasError = false);
    }
  }
}

// ─── Scope ───────────────────────────────────────────────────────────────────

class KoolbaseCodePushScope extends InheritedWidget {
  final KoolbaseScreenClient client;

  const KoolbaseCodePushScope({
    super.key,
    required this.client,
    required super.child,
  });

  static KoolbaseScreenClient? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<KoolbaseCodePushScope>()
        ?.client;
  }

  @override
  bool updateShouldNotify(KoolbaseCodePushScope old) => client != old.client;
}
