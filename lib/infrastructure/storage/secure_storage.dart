import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/interfaces/panel_adapter.dart';

/// 安全存储封装 — Token/密钥使用平台安全存储
/// Android: Keystore | iOS: Keychain | Windows: DPAPI
class SecureStorage {
  SecureStorage._();
  static final SecureStorage instance = SecureStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyAuthData = 'hyena.auth_data';
  static const _keyEmail = 'hyena.email';

  Future<void> saveAuthData(String authData) =>
      _storage.write(key: _keyAuthData, value: authData);

  Future<String?> readAuthData() => _storage.read(key: _keyAuthData);

  Future<void> saveEmail(String email) =>
      _storage.write(key: _keyEmail, value: email);

  Future<String?> readEmail() => _storage.read(key: _keyEmail);

  Future<void> clearAll() => _storage.deleteAll();

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  /// 组装 AuthContext，方便 UseCase 直接使用
  Future<AuthContext?> readAuthContext() async {
    final authData = await readAuthData();
    final email = await readEmail();
    if (authData == null || email == null) return null;
    return AuthContext(authData: authData, email: email);
  }
}
