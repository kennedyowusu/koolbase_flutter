class KoolbaseUser {
  final String id;
  final String projectId;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final bool verified;
  final bool disabled;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KoolbaseUser({
    required this.id,
    required this.projectId,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.verified,
    required this.disabled,
    this.lastLoginAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KoolbaseUser.fromJson(Map<String, dynamic> json) {
    return KoolbaseUser(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      verified: json['verified'] as bool? ?? false,
      disabled: json['disabled'] as bool? ?? false,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'verified': verified,
        'disabled': disabled,
        'last_login_at': lastLoginAt?.toIso8601String(),
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  KoolbaseUser copyWith({
    String? fullName,
    String? avatarUrl,
    bool? verified,
    Map<String, dynamic>? metadata,
  }) {
    return KoolbaseUser(
      id: id,
      projectId: projectId,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      verified: verified ?? this.verified,
      disabled: disabled,
      lastLoginAt: lastLoginAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final KoolbaseUser user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      user: KoolbaseUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
