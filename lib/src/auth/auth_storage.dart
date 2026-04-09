import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kRefreshTokenKey = 'koolbase_refresh_token';

class AuthStorage {
  final FlutterSecureStorage _storage;

  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _kRefreshTokenKey, value: token);
  }

  Future<String?> readRefreshToken() async {
    return _storage.read(key: _kRefreshTokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kRefreshTokenKey);
  }
}
