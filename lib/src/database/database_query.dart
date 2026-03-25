import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_models.dart';

/// Fluent query builder for a collection
class KoolbaseQuery {
  final String baseUrl;
  final String publicKey;
  final String collectionName;
  final String? _userId;
  final Map<String, dynamic> _filters = {};
  final List<String> _populate = [];
  int _limit = 20;
  int _offset = 0;
  String? _orderBy;
  bool _orderDesc = false;

  KoolbaseQuery({
    required this.baseUrl,
    required this.publicKey,
    required this.collectionName,
    String? userId,
  }) : _userId = userId;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': publicKey,
        if (_userId != null) 'x-user-id': _userId!,
      };

  KoolbaseQuery where(String field, {required dynamic isEqualTo}) {
    _filters[field] = isEqualTo;
    return this;
  }

  KoolbaseQuery limit(int value) {
    _limit = value;
    return this;
  }

  KoolbaseQuery offset(int value) {
    _offset = value;
    return this;
  }

  KoolbaseQuery orderBy(String field, {bool descending = false}) {
    _orderBy = field;
    _orderDesc = descending;
    return this;
  }

  /// Populate related records from another collection.
  KoolbaseQuery populate(List<String> fields) {
    _populate.addAll(fields);
    return this;
  }

  Future<QueryResult> get() async {
    final body = <String, dynamic>{
      'collection': collectionName,
      'filters': _filters,
      'limit': _limit,
      'offset': _offset,
      if (_orderBy != null) 'order_by': _orderBy,
      'order_desc': _orderDesc,
      if (_populate.isNotEmpty) 'populate': _populate,
    };

    final res = await http
        .post(
          Uri.parse('$baseUrl/v1/sdk/db/query'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Query failed');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final records = (data['records'] as List)
        .map((e) => KoolbaseRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return QueryResult(records: records, total: data['total'] as int);
  }
}

/// Document reference for single record operations
class KoolbaseDocRef {
  final String baseUrl;
  final String publicKey;
  final String recordId;
  final String? _userId;

  KoolbaseDocRef({
    required this.baseUrl,
    required this.publicKey,
    required this.recordId,
    String? userId,
  }) : _userId = userId;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': publicKey,
        if (_userId != null) 'x-user-id': _userId!,
      };

  Future<KoolbaseRecord> get() async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/v1/sdk/db/records/$recordId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Record not found');
    }
    return KoolbaseRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<KoolbaseRecord> update(Map<String, dynamic> data) async {
    final res = await http
        .patch(
          Uri.parse('$baseUrl/v1/sdk/db/records/$recordId'),
          headers: _headers,
          body: jsonEncode({'data': data}),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Update failed');
    }
    return KoolbaseRecord.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> delete() async {
    final res = await http
        .delete(
          Uri.parse('$baseUrl/v1/sdk/db/records/$recordId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 204) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Delete failed');
    }
  }
}
