import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'realtime_models.dart';

class KoolbaseRealtimeClient {
  final String baseUrl;
  final String publicKey;

  String? _token;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _disposed = false;

  final Map<String, StreamController<RealtimeEvent>> _controllers = {};
  final Set<String> _subscriptions = {};
  final Map<String, int> _subscriberCount = {};

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  KoolbaseRealtimeClient({
    required this.baseUrl,
    required this.publicKey,
  });

  /// Stream of connection state — true = connected, false = disconnected
  Stream<bool> get connectionState => _connectionController.stream;

  /// Set the user access token for authenticated subscriptions
  void setToken(String? token) {
    _token = token;
    if (token != null && _channel == null) {
      _connect();
    } else if (token == null) {
      _disconnect();
    }
  }

  String get _wsUrl {
    final base = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base/v1/realtime/ws?token=$_token';
  }

  void _connect() {
    if (_token == null || _disposed) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      // Fix: send subscriptions after connection stabilizes
      Future.microtask(() {
        if (_disposed || _channel == null) return;
        _connectionController.add(true);
        for (final channel in _subscriptions) {
          final parts = channel.split(':');
          if (parts.length == 2) {
            _sendSubscribe(parts[0], parts[1]);
          }
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
      _scheduleReconnect();
    }
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connectionController.add(false);
  }

  void _scheduleReconnect() {
    if (_disposed || _token == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed && _token != null) _connect();
    });
  }

  void _sendSubscribe(String projectId, String collection) {
    _channel?.sink.add(jsonEncode({
      'action': 'subscribe',
      'project_id': projectId,
      'collection': collection,
    }));
  }

  void _sendUnsubscribe(String projectId, String collection) {
    _channel?.sink.add(jsonEncode({
      'action': 'unsubscribe',
      'project_id': projectId,
      'collection': collection,
    }));
  }

  void _dispatch(RealtimeEvent event) {
    final channel = event.channel ?? '';
    _controllers[channel]?.add(event);
  }

  /// Subscribe to a collection — returns a stream of realtime events
  Stream<RealtimeEvent> on({
    required String projectId,
    required String collection,
  }) {
    final channelKey = '$projectId:$collection';

    if (!_controllers.containsKey(channelKey)) {
      _controllers[channelKey] = StreamController<RealtimeEvent>.broadcast(
        onCancel: () {
          _subscriberCount[channelKey] =
              (_subscriberCount[channelKey] ?? 1) - 1;

          if ((_subscriberCount[channelKey] ?? 0) <= 0) {
            _subscriptions.remove(channelKey);
            _sendUnsubscribe(projectId, collection);
            _controllers.remove(channelKey)?.close();
            _subscriberCount.remove(channelKey);
          }
        },
      );
    }

    _subscriberCount[channelKey] = (_subscriberCount[channelKey] ?? 0) + 1;

    if (!_subscriptions.contains(channelKey)) {
      _subscriptions.add(channelKey);
      if (_channel != null) {
        _sendSubscribe(projectId, collection);
      } else if (_token != null) {
        _connect();
      }
    }

    return _controllers[channelKey]!.stream;
  }

  /// Convenience: stream only record-created events
  Stream<Map<String, dynamic>> onRecordCreated({
    required String projectId,
    required String collection,
  }) {
    return on(projectId: projectId, collection: collection)
        .where((e) => e.type == RealtimeEventType.recordCreated)
        .where((e) => e.record != null)
        .map((e) => e.record!);
  }

  /// Convenience: stream only record-updated events
  Stream<Map<String, dynamic>> onRecordUpdated({
    required String projectId,
    required String collection,
  }) {
    return on(projectId: projectId, collection: collection)
        .where((e) => e.type == RealtimeEventType.recordUpdated)
        .where((e) => e.record != null)
        .map((e) => e.record!);
  }

  /// Convenience: stream only record-deleted events (returns record ID)
  Stream<String> onRecordDeleted({
    required String projectId,
    required String collection,
  }) {
    return on(projectId: projectId, collection: collection)
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
