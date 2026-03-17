import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_models.dart';
import 'auth_exceptions.dart';

class AuthApi {
  final String baseUrl;
  final String publicKey;

  const AuthApi({required this.baseUrl, required this.publicKey});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': publicKey,
      };

  Map<String, String> _authHeaders(String accessToken) => {
        'Content-Type': 'application/json',
        'x-api-key': publicKey,
        'Authorization': 'Bearer $accessToken',
      };

  Future<AuthSession> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/v1/sdk/auth/register'),
          headers: _headers,
          body: jsonEncode({
            'email': email,
            'password': password,
            if (fullName != null) 'full_name': fullName,
          }),
        )
        .timeout(const Duration(seconds: 10));
    return _parseSession(res);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/v1/sdk/auth/login'),
          headers: _headers,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));
    return _parseSession(res);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/v1/sdk/auth/refresh'),
          headers: _headers,
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(const Duration(seconds: 10));
    return _parseSession(res);
  }

  Future<void> logout(String accessToken) async {
    await http
        .post(
          Uri.parse('$baseUrl/v1/sdk/auth/logout'),
          headers: _authHeaders(accessToken),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<KoolbaseUser> getMe(String accessToken) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/v1/sdk/auth/me'),
          headers: _authHeaders(accessToken),
        )
        .timeout(const Duration(seconds: 10));
    _checkError(res);
    return KoolbaseUser.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<KoolbaseUser> updateProfile({
    required String accessToken,
    String? fullName,
    String? avatarUrl,
  }) async {
    final res = await http
        .patch(
          Uri.parse('$baseUrl/v1/sdk/auth/me'),
          headers: _authHeaders(accessToken),
          body: jsonEncode({
            if (fullName != null) 'full_name': fullName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          }),
        )
        .timeout(const Duration(seconds: 10));
    _checkError(res);
    return KoolbaseUser.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> forgotPassword(String email) async {
    await http
        .post(
          Uri.parse('$baseUrl/v1/sdk/auth/password-reset'),
          headers: _headers,
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/v1/sdk/auth/password-reset/confirm'),
          headers: _headers,
          body: jsonEncode({'token': token, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));
    _checkError(res);
  }

  Future<void> verifyEmail(String token) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/v1/sdk/auth/verify-email'),
          headers: _headers,
          body: jsonEncode({'token': token}),
        )
        .timeout(const Duration(seconds: 10));
    _checkError(res);
  }

  AuthSession _parseSession(http.Response res) {
    if (res.statusCode == 409) throw const EmailAlreadyInUseException();
    if (res.statusCode == 401) throw const InvalidCredentialsException();
    if (res.statusCode == 403) throw const UserDisabledException();
    _checkError(res);
    return AuthSession.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  void _checkError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    throw KoolbaseAuthException(
      body['error'] as String? ?? 'An unexpected error occurred',
    );
  }
}
