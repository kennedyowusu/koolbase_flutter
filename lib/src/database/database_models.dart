class KoolbaseCollection {
  final String id;
  final String projectId;
  final String name;
  final String readRule;
  final String writeRule;
  final String deleteRule;
  final DateTime createdAt;

  const KoolbaseCollection({
    required this.id,
    required this.projectId,
    required this.name,
    required this.readRule,
    required this.writeRule,
    required this.deleteRule,
    required this.createdAt,
  });

  factory KoolbaseCollection.fromJson(Map<String, dynamic> json) {
    return KoolbaseCollection(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      readRule: json['read_rule'] as String,
      writeRule: json['write_rule'] as String,
      deleteRule: json['delete_rule'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class KoolbaseRecord {
  final String id;
  final String projectId;
  final String collectionId;
  final String? createdBy;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KoolbaseRecord({
    required this.id,
    required this.projectId,
    required this.collectionId,
    this.createdBy,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KoolbaseRecord.fromJson(Map<String, dynamic> json) {
    return KoolbaseRecord(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      collectionId: json['collection_id'] as String,
      createdBy: json['created_by'] as String?,
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'collection_id': collectionId,
        if (createdBy != null) 'created_by': createdBy,
        'data': data,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class QueryResult {
  final List<KoolbaseRecord> records;
  final int total;
  final bool isFromCache;

  const QueryResult({
    required this.records,
    required this.total,
    this.isFromCache = false,
  });
}
