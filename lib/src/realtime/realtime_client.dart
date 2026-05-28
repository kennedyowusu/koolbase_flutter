import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'realtime_models.dart';

class KoolbaseRealtimeClient {
  final String baseUrl;
  final String publicKey;
  final Future<String?> Function() accessTokenProvider;

  String? _token;
  String? _projectId; // derived from the session token
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _connecting = false;

  // Keyed by collection — one user session means one project.
  final Map<String, StreamController<RealtimeEvent>> _controllers = {};
  final Set<String> _subscriptions = {};
  final Map<String, int> _subscriberCount = {};

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  KoolbaseRealtimeClient({
    required this.baseUrl,
    required this.publicKey,
    required this.accessTokenProvider,
  });

  Stream<bool> get connectionState => _connectionController.stream;

  String get _wsUrl {
    final base = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base/v1/realtime/ws?token=$_token';
  }

  /// Extracts the project_id claim from a Koolbase session JWT.
  static String? _projectIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final map = jsonDecode(utf8.decode(base64.decode(payload)))
          as Map<String, dynamic>;
      return map['project_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _connect() async {
    if (_disposed || _connecting || _channel != null) return;
    _connecting = true;

    final token = await accessTokenProvider();
    if (token == null || _disposed) {
      _connecting = false;
      _scheduleReconnect();
      return;
    }
    _token = token;
    _projectId = _projectIdFromToken(token);
    if (_projectId == null) {
      _connecting = false;
      _scheduleReconnect();
      return;
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _connecting = false;

      Future.microtask(() {
        if (_disposed || _channel == null) return;
        _connectionController.add(true);
        for (final collection in _subscriptions) {
          _sendSubscribe(collection);
        }
      });

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final event = RealtimeEvent.fromJson(json);
            _dispatch(event);
          } catch (e) {
            // Ignore malformed messages
          }
        },
        onDone: () {
          _channel = null;
          _connectionController.add(false);
          _scheduleReconnect();
        },
        onError: (error) {
          _channel = null;
          _connectionController.add(false);
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _connecting = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _subscriptions.isEmpty) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed) _connect();
    });
  }

  void _sendSubscribe(String collection) {
    final pid = _projectId;
    if (pid == null) return;
    _channel?.sink.add(jsonEncode({
      'action': 'subscribe',
      'project_id': pid,
      'collection': collection,
    }));
  }

  void _sendUnsubscribe(String collection) {
    final pid = _projectId;
    if (pid == null) return;
    _channel?.sink.add(jsonEncode({
      'action': 'unsubscribe',
      'project_id': pid,
      'collection': collection,
    }));
  }

  void _dispatch(RealtimeEvent event) {
    final collection = event.collection; // from payload; null on acks/errors
    if (collection == null) return;
    _controllers[collection]?.add(event);
  }

  /// Subscribe to a collection — returns a stream of realtime events.
  /// The project is taken from the signed-in user's session.
  Stream<RealtimeEvent> on({required String collection}) {
    if (!_controllers.containsKey(collection)) {
      _controllers[collection] = StreamController<RealtimeEvent>.broadcast(
        onCancel: () {
          _subscriberCount[collection] =
              (_subscriberCount[collection] ?? 1) - 1;
          if ((_subscriberCount[collection] ?? 0) <= 0) {
            _subscriptions.remove(collection);
            _sendUnsubscribe(collection);
            _controllers.remove(collection)?.close();
            _subscriberCount.remove(collection);
          }
        },
      );
    }

    _subscriberCount[collection] = (_subscriberCount[collection] ?? 0) + 1;

    if (!_subscriptions.contains(collection)) {
      _subscriptions.add(collection);
      if (_channel != null && _projectId != null) {
        _sendSubscribe(collection);
      } else {
        _connect();
      }
    }

    return _controllers[collection]!.stream;
  }

  Stream<Map<String, dynamic>> onRecordCreated({required String collection}) {
    return on(collection: collection)
        .where((e) => e.type == RealtimeEventType.recordCreated)
        .where((e) => e.record != null)
        .map((e) => e.record!);
  }

  Stream<Map<String, dynamic>> onRecordUpdated({required String collection}) {
    return on(collection: collection)
        .where((e) => e.type == RealtimeEventType.recordUpdated)
        .where((e) => e.record != null)
        .map((e) => e.record!);
  }

  Stream<String> onRecordDeleted({required String collection}) {
    return on(collection: collection)
        .where((e) => e.type == RealtimeEventType.recordDeleted)
        .where((e) => e.recordId != null)
        .map((e) => e.recordId!);
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _connectionController.close();
    for (final ctrl in _controllers.values) {
      ctrl.close();
    }
    _controllers.clear();
    _subscriptions.clear();
    _subscriberCount.clear();
  }
}
