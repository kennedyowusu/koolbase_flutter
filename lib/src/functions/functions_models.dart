/// The result of a function invocation.
class FunctionInvokeResult {
  /// HTTP status code returned by the function.
  final int statusCode;

  /// The parsed JSON response body, or null if empty.
  final Map<String, dynamic>? data;

  /// Raw response body as a string.
  final String raw;

  /// Whether the invocation was successful (statusCode 200–299).
  final bool success;

  const FunctionInvokeResult({
    required this.statusCode,
    required this.data,
    required this.raw,
    required this.success,
  });
}

/// Exception thrown when a function invocation fails.
class FunctionInvokeException implements Exception {
  final String message;
  final int? statusCode;

  const FunctionInvokeException(this.message, {this.statusCode});

  @override
  String toString() => 'FunctionInvokeException: $message';
}
