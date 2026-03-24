import 'dart:convert';
import 'package:http/http.dart' as http;
import 'functions_models.dart';
export 'functions_models.dart';

/// Client for invoking Koolbase Functions from Flutter.
class KoolbaseFunctionsClient {
  final String baseUrl;
  final String publicKey;

  const KoolbaseFunctionsClient({
    required this.baseUrl,
    required this.publicKey,
  });

  /// Invoke a deployed function by name.
  ///
  /// [name] — the function name as deployed in the dashboard.
  /// [body] — optional JSON payload sent as the request body.
  /// [timeout] — request timeout, defaults to 30 seconds.
  ///
  /// Returns a [FunctionInvokeResult] with the response data.
  /// Throws [FunctionInvokeException] on network errors or non-2xx responses.
  ///
  /// Example:
  /// ```dart
  /// final result = await Koolbase.functions.invoke(
  ///   'send-welcome-email',
  ///   body: {'userId': '123', 'email': 'user@example.com'},
  /// );
  ///
  /// if (result.success) {
  ///   print(result.data);
  /// }
  /// ```
  Future<FunctionInvokeResult> invoke(
    String name, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = Uri.parse('$baseUrl/v1/sdk/functions/$name');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': publicKey,
            },
            body: body != null ? jsonEncode(body) : '{}',
          )
          .timeout(timeout);

      final raw = response.body;
      Map<String, dynamic>? data;

      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        // Response is not JSON — leave data as null
      }

      final success = response.statusCode >= 200 && response.statusCode < 300;

      if (!success) {
        final message =
            data?['error'] as String? ?? 'Function invocation failed';
        throw FunctionInvokeException(message, statusCode: response.statusCode);
      }

      return FunctionInvokeResult(
        statusCode: response.statusCode,
        data: data,
        raw: raw,
        success: success,
      );
    } on FunctionInvokeException {
      rethrow;
    } catch (e) {
      throw FunctionInvokeException('Network error: $e');
    }
  }
}
