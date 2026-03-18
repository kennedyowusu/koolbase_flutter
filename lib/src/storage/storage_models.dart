class KoolbaseBucket {
  final String id;
  final String projectId;
  final String name;
  final bool public;
  final DateTime createdAt;

  const KoolbaseBucket({
    required this.id,
    required this.projectId,
    required this.name,
    required this.public,
    required this.createdAt,
  });

  factory KoolbaseBucket.fromJson(Map<String, dynamic> json) {
    return KoolbaseBucket(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      public: json['public'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class KoolbaseObject {
  final String id;
  final String projectId;
  final String bucketId;
  final String? userId;
  final String path;
  final int size;
  final String? contentType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KoolbaseObject({
    required this.id,
    required this.projectId,
    required this.bucketId,
    this.userId,
    required this.path,
    required this.size,
    this.contentType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KoolbaseObject.fromJson(Map<String, dynamic> json) {
    return KoolbaseObject(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      bucketId: json['bucket_id'] as String,
      userId: json['user_id'] as String?,
      path: json['path'] as String,
      size: json['size'] as int? ?? 0,
      contentType: json['content_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class UploadResult {
  final KoolbaseObject object;
  final String downloadUrl;

  const UploadResult({required this.object, required this.downloadUrl});
}
