import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_models.dart';
import 'database_query.dart';

class KoolbaseDatabaseClient {
  final String baseUrl;
  final String publicKey;
  String? _userId;

  KoolbaseDatabaseClient({
    required this.baseUrl,
    required this.publicKey,
  });

  /// Set the current authenticated user ID for permission checks
  void setUserId(String? userId) => _userId = userId;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': publicKey,
        if (_userId != null) 'x-user-id': _userId!,
      };

  /// Get a fluent query builder for a collection
  KoolbaseQuery collection(String name) {
    return KoolbaseQuery(
      baseUrl: baseUrl,
      publicKey: publicKey,
      collectionName: name,
      userId: _userId,
    );
  }

  /// Get a reference to a specific record by ID
  KoolbaseDocRef doc(String recordId) {
    return KoolbaseDocRef(
      baseUrl: baseUrl,
      publicKey: publicKey,
      recordId: recordId,
      userId: _userId,
    );
  }

  /// Insert a new record into a collection
  Future<KoolbaseRecord> insert({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/sdk/db/insert'),
      headers: _headers,
      body: jsonEncode({'collection': collection, 'data': data}),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Insert failed');
    }

    return KoolbaseRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }
}
