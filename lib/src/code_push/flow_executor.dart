import 'package:flutter/foundation.dart';
import 'flow_models.dart';

// ─── FlowContext ──────────────────────────────────────────────────────────────

/// Mutable execution context — holds data sources for condition evaluation.
class FlowContext {
  /// App-provided data (user, cart, session, etc.)
  final Map<String, dynamic> context;

  /// Active bundle config values
  final Map<String, dynamic> config;

  /// Active bundle flag values
  final Map<String, bool> flags;

  FlowContext({
    Map<String, dynamic>? context,
    Map<String, dynamic>? config,
    Map<String, bool>? flags,
  })  : context = Map<String, dynamic>.from(context ?? {}),
        config = Map<String, dynamic>.from(config ?? {}),
        flags = Map<String, bool>.from(flags ?? {});

  /// Resolve a data ref to its value
  dynamic resolve(FlowDataRef ref) {
    final key = ref.key;
    return switch (ref.source) {
      'context' => _nestedGet(context, key),
      'config' => _nestedGet(config, key),
      'flags' => flags[key],
      _ => null,
    };
  }

  /// Set a value in the mutable context
  void set(String key, dynamic value) {
    _nestedSet(context, key, value);
  }

  /// Get a nested value using dot notation (e.g. "user.plan")
  dynamic _nestedGet(Map<String, dynamic> map, String key) {
    final parts = key.split('.');
    dynamic current = map;
    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Set a nested value using dot notation
  void _nestedSet(Map<String, dynamic> map, String key, dynamic value) {
    final parts = key.split('.');
    Map<String, dynamic> current = map;
    for (int i = 0; i < parts.length - 1; i++) {
      current.putIfAbsent(parts[i], () => <String, dynamic>{});
      current = current[parts[i]] as Map<String, dynamic>;
    }
    current[parts.last] = value;
  }
}

// ─── FlowExecutor ─────────────────────────────────────────────────────────────

class FlowExecutor {
  static const _tag = '[FlowExecutor]';

  /// Execute a named flow from the bundle's flows map.
  /// Returns a FlowResult — always safe, never throws.
  FlowResult execute({
    required String flowId,
    required Map<String, dynamic> flows,
    required FlowContext ctx,
  }) {
    try {
      final flowJson = flows[flowId];
      if (flowJson == null) {
        debugPrint('$_tag flow not found: $flowId');
        return FlowResult.noEvent();
      }

      final node = FlowNode.fromJson(flowJson as Map<String, dynamic>);
      return _evalNode(node, ctx);
    } catch (e) {
      debugPrint('$_tag error executing flow $flowId: $e');
      return FlowResult.failed(e.toString());
    }
  }

  // ─── Node evaluation ───────────────────────────────────────────────────────

  FlowResult _evalNode(FlowNode node, FlowContext ctx) {
    return switch (node) {
      IfNode n => _evalIf(n, ctx),
      SequenceNode n => _evalSequence(n, ctx),
      EventNode n => _evalEvent(n),
      SetNode n => _evalSet(n, ctx),
      _ => FlowResult.noEvent(),
    };
  }

  FlowResult _evalIf(IfNode node, FlowContext ctx) {
    final result = _evalCondition(node.condition, ctx);
    if (result) {
      return _evalNode(node.then, ctx);
    } else if (node.orElse != null) {
      return _evalNode(node.orElse!, ctx);
    }
    return FlowResult.noEvent();
  }

  FlowResult _evalSequence(SequenceNode node, FlowContext ctx) {
    for (final step in node.steps) {
      final result = _evalNode(step, ctx);
      // Stop at first terminal event
      if (result.hasEvent) return result;
    }
    return FlowResult.noEvent();
  }

  FlowResult _evalEvent(EventNode node) {
    debugPrint('$_tag emitting event: ${node.name}');
    return FlowResult.event(node.name, node.args);
  }

  FlowResult _evalSet(SetNode node, FlowContext ctx) {
    ctx.set(node.key, node.value);
    debugPrint('$_tag set ${node.key} = ${node.value}');
    return FlowResult.noEvent();
  }

  // ─── Condition evaluation ──────────────────────────────────────────────────

  bool _evalCondition(FlowCondition condition, FlowContext ctx) {
    return switch (condition.op) {
      FlowOperator.eq => _evalEq(condition, ctx),
      FlowOperator.neq => !_evalEq(condition, ctx),
      FlowOperator.gt => _evalGt(condition, ctx),
      FlowOperator.lt => _evalLt(condition, ctx),
      FlowOperator.and => _evalAnd(condition, ctx),
      FlowOperator.or => _evalOr(condition, ctx),
      FlowOperator.exists => _evalExists(condition, ctx),
    };
  }

  bool _evalEq(FlowCondition c, FlowContext ctx) {
    final left = c.left != null ? ctx.resolve(c.left!) : null;
    return left?.toString() == c.right?.toString();
  }

  bool _evalGt(FlowCondition c, FlowContext ctx) {
    final left = _toNum(c.left != null ? ctx.resolve(c.left!) : null);
    final right = _toNum(c.right);
    if (left == null || right == null) return false;
    return left > right;
  }

  bool _evalLt(FlowCondition c, FlowContext ctx) {
    final left = _toNum(c.left != null ? ctx.resolve(c.left!) : null);
    final right = _toNum(c.right);
    if (left == null || right == null) return false;
    return left < right;
  }

  bool _evalAnd(FlowCondition c, FlowContext ctx) {
    if (c.conditions == null || c.conditions!.isEmpty) return false;
    return c.conditions!.every((sub) => _evalCondition(sub, ctx));
  }

  bool _evalOr(FlowCondition c, FlowContext ctx) {
    if (c.conditions == null || c.conditions!.isEmpty) return false;
    return c.conditions!.any((sub) => _evalCondition(sub, ctx));
  }

  bool _evalExists(FlowCondition c, FlowContext ctx) {
    if (c.value == null) return false;
    final val = ctx.resolve(c.value!);
    return val != null;
  }

  num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
