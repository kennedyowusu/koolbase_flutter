/// Represents the response from the OTA check endpoint.
class OtaCheckResult {
  /// Whether a newer bundle is available.
  final bool hasUpdate;

  /// The version number of the available bundle. Null if no update.
  final int? version;

  /// SHA-256 checksum of the bundle. Null if no update.
  final String? checksum;

  /// Whether this update is mandatory — app should block until applied.
  final bool mandatory;

  /// Presigned download URL. Null if no update.
  final String? downloadUrl;

  /// Optional release notes. Null if not provided.
  final String? releaseNotes;

  /// File size in bytes. Null if no update.
  final int? fileSize;

  const OtaCheckResult({
    required this.hasUpdate,
    this.version,
    this.checksum,
    this.mandatory = false,
    this.downloadUrl,
    this.releaseNotes,
    this.fileSize,
  });

  factory OtaCheckResult.noUpdate() => const OtaCheckResult(hasUpdate: false);

  factory OtaCheckResult.fromJson(Map<String, dynamic> json) {
    return OtaCheckResult(
      hasUpdate: json['has_update'] as bool? ?? false,
      version: json['version'] as int?,
      checksum: json['checksum'] as String?,
      mandatory: json['mandatory'] as bool? ?? false,
      downloadUrl: json['download_url'] as String?,
      releaseNotes: json['release_notes'] as String?,
      fileSize: json['file_size'] as int?,
    );
  }
}

/// State of the OTA download progress.
enum OtaDownloadState { idle, downloading, verifying, extracting, ready, failed }

/// Progress event emitted during bundle download and extraction.
class OtaProgress {
  final OtaDownloadState state;

  /// Download progress from 0.0 to 1.0. Only meaningful during [OtaDownloadState.downloading].
  final double progress;

  /// Error message. Only set when state is [OtaDownloadState.failed].
  final String? error;

  const OtaProgress({
    required this.state,
    this.progress = 0.0,
    this.error,
  });
}
