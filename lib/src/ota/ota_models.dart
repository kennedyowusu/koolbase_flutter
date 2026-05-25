/// Represents the response from the OTA check endpoint.
class OtaCheckResult {
  /// Whether a newer bundle is available.
  final bool hasUpdate;

  /// Whether the server asked the device to roll back (its current bundle
  /// was recalled). When true, [revertTo] holds the version to fall back to.
  final bool isRollback;

  /// The version to revert to when [isRollback] is true. Null otherwise.
  final int? revertTo;

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
    this.isRollback = false,
    this.revertTo,
    this.version,
    this.checksum,
    this.mandatory = false,
    this.downloadUrl,
    this.releaseNotes,
    this.fileSize,
  });

  factory OtaCheckResult.noUpdate() => const OtaCheckResult(hasUpdate: false);

  /// Parses the Koolbase code-push check response.
  ///
  ///   {"status":"update_available","bundle":{...}}
  ///   {"status":"rollback","revert_to":"3"}
  ///   {"status":"no_update"}
  factory OtaCheckResult.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String?;

    if (status == 'update_available') {
      final bundle = json['bundle'] as Map<String, dynamic>? ?? const {};
      return OtaCheckResult(
        hasUpdate: true,
        version: bundle['version'] as int?,
        checksum: bundle['checksum'] as String?,
        mandatory: bundle['mandatory'] as bool? ?? false,
        downloadUrl: bundle['download_url'] as String?,
        releaseNotes: bundle['release_notes'] as String?,
        fileSize: bundle['size_bytes'] as int?,
      );
    }

    if (status == 'rollback') {
      final raw = json['revert_to'];
      final revertTo = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
      return OtaCheckResult(
          hasUpdate: false, isRollback: true, revertTo: revertTo);
    }

    return OtaCheckResult.noUpdate();
  }
}

/// State of the OTA download progress.
enum OtaDownloadState {
  idle,
  downloading,
  verifying,
  extracting,
  ready,
  failed
}

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
