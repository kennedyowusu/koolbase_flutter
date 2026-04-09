// ─── Node Types ──────────────────────────────────────────────────────────────

enum FlowNodeType { ifNode, sequence, event, set }

// ─── Operators ───────────────────────────────────────────────────────────────

enum FlowOperator {
  eq, neq,
  gt, gte,
  lt, lte,
  and, or,
  exists, notExists,
  contains, startsWith, endsWith,
  inList, notInList,
  between,
  isTrue, isFalse,
}

// ─── Data Source ─────────────────────────────────────────────────────────────

class FlowDataRef {
  final String from;

  const FlowDataRef({required this.from});

  factory FlowDataRef.fromJson(Map<String, dynamic> json) {
    return FlowDataRef(from: json['from'] as String);
  }

  /// Source type: first segment before the dot
  String get source => from.split('.').first;

  /// Key: everything after the first dot
  String get key => from.substring(from.indexOf('.') + 1);
}

// ─── Condition ───────────────────────────────────────────────────────────────

class FlowCondition {
  final FlowOperator op;

  /// Left operand — always a data ref
  final FlowDataRef? left;

  /// Right operand — a literal value (String, int, double, bool)
  final dynamic right;

  /// For 'exists' operator — single value ref
  final FlowDataRef? value;

  /// For 'and' / 'or' — sub-conditions
  final List<FlowCondition>? conditions;

  const FlowCondition({
    required this.op,
    this.left,
    this.right,
    this.value,
    this.conditions,
  });

  factory FlowCondition.fromJson(Map<String, dynamic> json) {
    final op = _parseOp(json['op'] as String);
    return FlowCondition(
      op: op,
      left: json['left'] != null
          ? FlowDataRef.fromJson(json['left'] as Map<String, dynamic>)
          : null,
      right: json['right'],
      value: json['value'] != null
          ? FlowDataRef.fromJson(json['value'] as Map<String, dynamic>)
          : null,
      conditions: json['conditions'] != null
          ? (json['conditions'] as List)
              .map((c) => FlowCondition.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  static FlowOperator _parseOp(String op) {
    return switch (op) {
      'eq'          => FlowOperator.eq,
      'neq'         => FlowOperator.neq,
      'gt'          => FlowOperator.gt,
      'gte'         => FlowOperator.gte,
      'lt'          => FlowOperator.lt,
      'lte'         => FlowOperator.lte,
      'and'         => FlowOperator.and,
      'or'          => FlowOperator.or,
      'exists'      => FlowOperator.exists,
      'not_exists'  => FlowOperator.notExists,
      'contains'    => FlowOperator.contains,
      'starts_with' => FlowOperator.startsWith,
      'ends_with'   => FlowOperator.endsWith,
      'in_list'     => FlowOperator.inList,
      'not_in_list' => FlowOperator.notInList,
      'between'     => FlowOperator.between,
      'is_true'     => FlowOperator.isTrue,
      'is_false'    => FlowOperator.isFalse,
      _             => FlowOperator.eq,
    };
  }
}

// ─── Flow Nodes ──────────────────────────────────────────────────────────────

abstract class FlowNode {
  const FlowNode();

  factory FlowNode.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'if' => IfNode.fromJson(json),
      'sequence' => SequenceNode.fromJson(json),
      'event' => EventNode.fromJson(json),
      'set' => SetNode.fromJson(json),
      _ => const EventNode(name: 'unknown'),
    };
  }
}

/// Branch on a condition
class IfNode extends FlowNode {
  final FlowCondition condition;
  final FlowNode then;
  final FlowNode? orElse;

  const IfNode({
    required this.condition,
    required this.then,
    this.orElse,
  });

  factory IfNode.fromJson(Map<String, dynamic> json) {
    return IfNode(
      condition:
          FlowCondition.fromJson(json['condition'] as Map<String, dynamic>),
      then: FlowNode.fromJson(json['then'] as Map<String, dynamic>),
      orElse: json['else'] != null
          ? FlowNode.fromJson(json['else'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Run steps in order — stops at first event (terminal)
class SequenceNode extends FlowNode {
  final List<FlowNode> steps;

  const SequenceNode({required this.steps});

  factory SequenceNode.fromJson(Map<String, dynamic> json) {
    return SequenceNode(
      steps: (json['steps'] as List)
          .map((s) => FlowNode.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Emit a named event — terminal node, execution stops here
class EventNode extends FlowNode {
  final String name;
  final Map<String, dynamic> args;

  const EventNode({required this.name, this.args = const {}});

  factory EventNode.fromJson(Map<String, dynamic> json) {
    return EventNode(
      name: json['name'] as String,
      args: (json['args'] as Map<String, dynamic>?) ?? {},
    );
  }
}

/// Set a value in the mutable context
class SetNode extends FlowNode {
  final String key;
  final dynamic value;

  const SetNode({required this.key, required this.value});

  factory SetNode.fromJson(Map<String, dynamic> json) {
    return SetNode(
      key: json['key'] as String,
      value: json['value'],
    );
  }
}

// ─── Flow Result ─────────────────────────────────────────────────────────────

class FlowResult {
  /// The event name emitted by the terminal EventNode
  final String? eventName;

  /// Args attached to the event
  final Map<String, dynamic> args;

  /// Whether the flow completed successfully
  final bool completed;

  /// Error message if flow evaluation failed
  final String? error;

  const FlowResult._({
    this.eventName,
    this.args = const {},
    required this.completed,
    this.error,
  });

  factory FlowResult.event(String name, Map<String, dynamic> args) =>
      FlowResult._(eventName: name, args: args, completed: true);

  factory FlowResult.noEvent() => const FlowResult._(completed: true);

  factory FlowResult.failed(String error) =>
      FlowResult._(completed: false, error: error);

  bool get hasEvent => eventName != null;
}
