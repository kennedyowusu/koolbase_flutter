enum RealtimeEventType {
  subscribed,
  unsubscribed,
  recordCreated,
  recordUpdated,
  recordDeleted,
  error,
  unknown,
}

class RealtimeEvent {
  final RealtimeEventType type;
  final String? channel;
  final Map<String, dynamic>? payload;
  final DateTime timestamp;

  const RealtimeEvent({
    required this.type,
    this.channel,
    this.payload,
    required this.timestamp,
  });

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? '';
    final type = _parseType(typeStr);
    return RealtimeEvent(
      type: type,
      channel: json['channel'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  static RealtimeEventType _parseType(String type) {
    switch (type) {
      case 'subscribed':
        return RealtimeEventType.subscribed;
      case 'unsubscribed':
        return RealtimeEventType.unsubscribed;
      case 'db.record.created':
        return RealtimeEventType.recordCreated;
      case 'db.record.updated':
        return RealtimeEventType.recordUpdated;
      case 'db.record.deleted':
        return RealtimeEventType.recordDeleted;
      case 'error':
        return RealtimeEventType.error;
      default:
        return RealtimeEventType.unknown;
    }
  }

  Map<String, dynamic>? get record =>
      payload?['record'] as Map<String, dynamic>?;

  String? get recordId => payload?['record_id'] as String?;

  String? get collection => payload?['collection'] as String?;

  @override
  String toString() =>
      'RealtimeEvent(type: $type, channel: $channel, record: $record)';
}
