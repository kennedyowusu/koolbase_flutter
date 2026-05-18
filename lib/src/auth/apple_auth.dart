/// KoolbaseAppleAuth — Sign in with Apple for Koolbase.
///
/// **DEPRECATED in v2.9.0.** Apple Sign-In via this class was internally
/// routed through [KoolbaseAuthClient.oauthLogin], which called
/// `/v1/auth/oauth` — the **dashboard's developer OAuth handler**, not
/// an end-user surface. As a result, [signIn] never actually created
/// project-scoped sessions for end-users.
///
/// A proper end-user Apple Sign-In flow requires a server-side
/// `/v1/sdk/auth/oauth/apple` endpoint that:
/// 1. Accepts the Apple identityToken from this SDK
/// 2. Verifies the token via Apple's JWKS
/// 3. Creates or finds a user in the calling project (via x-api-key)
/// 4. Returns an [AuthSession] with access + refresh tokens
///
/// That endpoint is tracked for v2.10.x along with the equivalent Google
/// and GitHub flows. For now, [signIn] throws [UnimplementedError]. Use
/// [KoolbaseAuthClient.login] with email and password until the proper
/// server endpoints ship.
@Deprecated(
    'Apple Sign-In for end-users blocked on server-side /v1/sdk/auth/oauth '
    'endpoint. Use email/password authentication for now. Tracking: v2.10.x.')
class KoolbaseAppleAuth {
  /// **DEPRECATED.** See class-level documentation.
  ///
  /// Throws [UnimplementedError]. Will be properly implemented in v2.10.x
  /// once the server endpoint ships.
  @Deprecated(
      'Apple Sign-In for end-users blocked on server-side /v1/sdk/auth/oauth '
      'endpoint. Use email/password authentication for now. Tracking: v2.10.x.')
  static Future<Map<String, dynamic>?> signIn() async {
    throw UnimplementedError(
      'KoolbaseAppleAuth.signIn is not yet supported. The previous '
      "implementation routed through /v1/auth/oauth — the dashboard's "
      'developer OAuth handler, which does not create project-scoped '
      'sessions for end-users. A proper /v1/sdk/auth/oauth/apple endpoint '
      'is tracked for v2.10.x. For now, use KoolbaseAuthClient.login with '
      'email/password.',
    );
  }
}
