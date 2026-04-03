import 'package:flutter/material.dart';

class KoolbaseRfwWidget {
  final String name;
  final Widget Function(
    BuildContext context,
    Map<String, dynamic> data,
  ) builder;

  const KoolbaseRfwWidget({
    required this.name,
    required this.builder,
  });
}

enum ScreenLookupStatus {
  found,
  noBundle,
  screenNotFound,
  fileNotFound,
  parseError,
}

class ScreenLookupResult {
  final ScreenLookupStatus status;
  final List<int>? rfwBytes;

  const ScreenLookupResult._({required this.status, this.rfwBytes});

  factory ScreenLookupResult.found(List<int> bytes) =>
      ScreenLookupResult._(status: ScreenLookupStatus.found, rfwBytes: bytes);

  factory ScreenLookupResult.noBundle() =>
      const ScreenLookupResult._(status: ScreenLookupStatus.noBundle);

  factory ScreenLookupResult.screenNotFound() =>
      const ScreenLookupResult._(status: ScreenLookupStatus.screenNotFound);

  factory ScreenLookupResult.fileNotFound() =>
      const ScreenLookupResult._(status: ScreenLookupStatus.fileNotFound);

  factory ScreenLookupResult.parseError() =>
      const ScreenLookupResult._(status: ScreenLookupStatus.parseError);

  bool get isFound => status == ScreenLookupStatus.found;
}

abstract class KoolbaseScreenClient {
  Future<ScreenLookupResult> resolveScreen(String screenId);
}
