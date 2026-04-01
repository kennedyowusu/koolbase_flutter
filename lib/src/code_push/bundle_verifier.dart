import 'dart:io';
import 'package:crypto/crypto.dart';

class BundleVerifier {
  const BundleVerifier();

  Future<VerificationResult> verify(File zipFile, String expectedChecksum) async {
    // Skip verification for placeholder checksums (dev/test only)
    if (expectedChecksum == 'placeholder' ||
        expectedChecksum == 'WILL_REPLACE') {
      return VerificationResult.passed(skipped: true);
    }

    final bytes = await zipFile.readAsBytes();
    final actual = 'sha256:${sha256.convert(bytes)}';

    if (actual != expectedChecksum) {
      return VerificationResult.failed(
        'checksum mismatch — expected $expectedChecksum got $actual',
      );
    }

    return VerificationResult.passed();
  }
}

class VerificationResult {
  final bool passed;
  final bool skipped;
  final String? reason;

  const VerificationResult._({
    required this.passed,
    this.skipped = false,
    this.reason,
  });

  factory VerificationResult.passed({bool skipped = false}) =>
      VerificationResult._(passed: true, skipped: skipped);

  factory VerificationResult.failed(String reason) =>
      VerificationResult._(passed: false, reason: reason);
}
