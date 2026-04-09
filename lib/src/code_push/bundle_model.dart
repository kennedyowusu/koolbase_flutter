class BundleManifest {
  final String bundleId;
  final String appId;
  final int version;
  final String baseAppVersion;
  final String maxAppVersion;
  final String platform;
  final String channel;
  final String checksum;
  final String signature;
  final int sizeBytes;
  final BundlePayload payload;

  const BundleManifest({
    required this.bundleId,
    required this.appId,
    required this.version,
    required this.baseAppVersion,
    required this.maxAppVersion,
    required this.platform,
    required this.channel,
    required this.checksum,
    required this.signature,
    required this.sizeBytes,
    required this.payload,
  });

  factory BundleManifest.fromJson(Map<String, dynamic> json) {
    return BundleManifest(
      bundleId: json['bundle_id'] as String,
      appId: json['app_id'] as String,
      version: json['version'] as int,
      baseAppVersion: json['base_app_version'] as String,
      maxAppVersion: json['max_app_version'] as String,
      platform: json['platform'] as String,
      channel: json['channel'] as String,
      checksum: json['checksum'] as String,
      signature: json['signature'] as String,
      sizeBytes: json['size_bytes'] as int,
      payload: BundlePayload.fromJson(json['payload'] as Map<String, dynamic>),
    );
  }
}

class BundlePayload {
  final Map<String, dynamic> config;
  final Map<String, bool> flags;
  final Map<String, dynamic> directives;
  final BundleAssets assets;
  final Map<String, String> screens;

  /// Event-driven logic flows — Map of flowId to flow node tree
  final Map<String, dynamic> flows;

  const BundlePayload({
    required this.config,
    required this.flags,
    required this.directives,
    required this.assets,
    this.screens = const {},
    this.flows = const {},
  });

  factory BundlePayload.fromJson(Map<String, dynamic> json) {
    return BundlePayload(
      config: (json['config'] as Map<String, dynamic>?) ?? {},
      flags: ((json['flags'] as Map<String, dynamic>?) ?? {})
          .map((k, v) => MapEntry(k, v as bool)),
      directives: (json['directives'] as Map<String, dynamic>?) ?? {},
      assets: BundleAssets.fromJson(
          (json['assets'] as Map<String, dynamic>?) ?? {}),
      screens: ((json['screens'] as Map<String, dynamic>?) ?? {})
          .map((k, v) => MapEntry(k, v as String)),
      flows: (json['flows'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class BundleAssets {
  final List<String> images;
  final List<String> json;
  final List<String> fonts;

  const BundleAssets({
    required this.images,
    required this.json,
    required this.fonts,
  });

  factory BundleAssets.fromJson(Map<String, dynamic> json) {
    return BundleAssets(
      images: List<String>.from(json['images'] ?? []),
      json: List<String>.from(json['json'] ?? []),
      fonts: List<String>.from(json['fonts'] ?? []),
    );
  }
}

class CheckResponse {
  final String status;
  final BundleRef? bundle;
  final int? revertTo;

  const CheckResponse({
    required this.status,
    this.bundle,
    this.revertTo,
  });

  factory CheckResponse.fromJson(Map<String, dynamic> json) {
    return CheckResponse(
      status: json['status'] as String,
      bundle: json['bundle'] != null
          ? BundleRef.fromJson(json['bundle'] as Map<String, dynamic>)
          : null,
      revertTo: json['revert_to'] != null
          ? int.tryParse(json['revert_to'].toString())
          : null,
    );
  }
}

class BundleRef {
  final String bundleId;
  final int version;
  final String downloadUrl;
  final String checksum;
  final String signature;
  final int sizeBytes;

  const BundleRef({
    required this.bundleId,
    required this.version,
    required this.downloadUrl,
    required this.checksum,
    required this.signature,
    required this.sizeBytes,
  });

  factory BundleRef.fromJson(Map<String, dynamic> json) {
    return BundleRef(
      bundleId: json['bundle_id'] as String,
      version: json['version'] as int,
      downloadUrl: json['download_url'] as String,
      checksum: json['checksum'] as String,
      signature: json['signature'] as String,
      sizeBytes: json['size_bytes'] as int,
    );
  }
}
