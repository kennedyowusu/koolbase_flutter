import 'dart:async';
import 'auth_api.dart';
import 'auth_models.dart';
import 'auth_storage.dart';
import 'auth_exceptions.dart';

class KoolbaseAuthClient {
  final AuthApi _api;
  final AuthStorage _storage;

  KoolbaseUser? _currentUser;
  String? _accessToken;
  DateTime? _accessTokenExpiresAt;

  final StreamController<KoolbaseUser?> _authStateController =
      StreamController<KoolbaseUser?>.broadcast();

  KoolbaseAuthClient({
    required AuthApi api,
    AuthStorage? storage,
  })  : _api = api,
        _storage = storage ?? AuthStorage();

  KoolbaseUser? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _currentUser != null && _accessToken != null;
  Stream<KoolbaseUser?> get authStateChanges => _authStateController.stream;

  Future<void> restoreSession() async {
    try {
      final refreshToken = await _storage.readRefreshToken();
      if (refreshToken == null) return;
      final session = await _api.refresh(refreshToken);
      await _setSession(session);
    } catch (_) {
      await _storage.clear();
    }
  }

  Future<KoolbaseUser> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    if (password.length < 8) throw const WeakPasswordException();
    final session = await _api.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
    await _setSession(session);
    return session.user;
  }

  Future<KoolbaseUser> login({
    required String email,
    required String password,
  }) async {
    final session = await _api.login(email: email, password: password);
    await _setSession(session);
    return session.user;
  }

  Future<void> logout() async {
    try {
      if (_accessToken != null) {
        await _api.logout(_accessToken!);
      }
    } catch (_) {
      // Best effort
    } finally {
      await _clearSession();
    }
  }

  Future<KoolbaseUser> getCurrentUser() async {
    final token = await _ensureValidToken();
    final user = await _api.getMe(token);
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  Future<KoolbaseUser> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final token = await _ensureValidToken();
    final user = await _api.updateProfile(
      accessToken: token,
      fullName: fullName,
      avatarUrl: avatarUrl,
    );
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  Future<void> forgotPassword({required String email}) async {
    await _api.forgotPassword(email);
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _api.resetPassword(token: token, password: password);
  }

  Future<void> verifyEmail(String token) async {
    await _api.verifyEmail(token);
  }

  Future<bool> refreshSession() async {
    try {
      final refreshToken = await _storage.readRefreshToken();
      if (refreshToken == null) return false;
      final session = await _api.refresh(refreshToken);
      await _setSession(session);
      return true;
    } catch (_) {
      await _clearSession();
      return false;
    }
  }

  Future<String> _ensureValidToken() async {
    // Check if access token exists and is not expired
    if (_accessToken != null &&
        _accessTokenExpiresAt != null &&
        DateTime.now()
            .isBefore(_accessTokenExpiresAt!.subtract(const Duration(minutes: 1)))) {
      return _accessToken!;
    }

    // Try to refresh
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) throw const SessionExpiredException();

    try {
      final session = await _api.refresh(refreshToken);
      await _setSession(session);
      return session.accessToken;
    } catch (_) {
      await _clearSession();
      throw const SessionExpiredException();
    }
  }

  Future<void> _setSession(AuthSession session) async {
    _accessToken = session.accessToken;
    _accessTokenExpiresAt = session.expiresAt;
    _currentUser = session.user;
    await _storage.saveRefreshToken(session.refreshToken);
    _authStateController.add(session.user);
  }

  Future<void> _clearSession() async {
    _accessToken = null;
    _accessTokenExpiresAt = null;
    _currentUser = null;
    await _storage.clear();
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
