import 'package:flutter/foundation.dart';
import 'package:koolbase_flutter/koolbase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../koolbase.dart';

/// KoolbaseAppleAuth — Sign in with Apple for Koolbase
///
/// Usage:
/// ```dart
/// final session = await KoolbaseAppleAuth.signIn();
/// ```
class KoolbaseAppleAuth {
  /// Sign in with Apple and authenticate with Koolbase.
  /// Returns a KoolbaseSession on success.
  static Future<Map<String, dynamic>?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        debugPrint('[KoolbaseAppleAuth] No identity token returned');
        return null;
      }

      // Build display name from Apple credential
      final name = [
        credential.givenName,
        credential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      // Authenticate with Koolbase
      final session = await Koolbase.auth.oauthLogin(
        provider: 'apple',
        token: identityToken,
        email: credential.email ?? '',
        name: name,
      );

      return session;
    } catch (e) {
      debugPrint('[KoolbaseAppleAuth] Sign in failed: $e');
      return null;
    }
  }
}
