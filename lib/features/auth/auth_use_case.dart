import '../../core/errors/app_error.dart';
import '../../core/interfaces/panel_adapter.dart';
import '../../core/models/panel_site.dart';
import '../../core/models/panel_user.dart';
import '../../core/result.dart';
import '../../infrastructure/storage/secure_storage.dart';
import '../../infrastructure/logging/app_logger.dart';

/// 认证 UseCase — 注册/登录/登出/Token 持久化
class AuthUseCase {
  AuthUseCase({
    required PanelAdapter adapter,
    required PanelSite site,
    required SecureStorage storage,
  })  : _adapter = adapter,
        _site = site,
        _storage = storage;

  final PanelAdapter _adapter;
  final PanelSite _site;
  final SecureStorage _storage;

  PanelUser? _currentUser;
  PanelUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// 尝试从 SecureStorage 恢复登录态
  Future<bool> restoreSession() async {
    final authData = await _storage.readAuthData();
    final email = await _storage.readEmail();
    if (authData == null || email == null) return false;

    try {
      final user = await _adapter.fetchUserInfo(
        _site,
        AuthContext(authData: authData, email: email),
      );
      _currentUser = user;
      AppLogger.i('会话恢复成功: $email', tag: LogTag.auth);
      return true;
    } catch (e) {
      AppLogger.w('会话恢复失败: $e', tag: LogTag.auth);
      await _storage.clearAll();
      return false;
    }
  }

  Future<Result<PanelUser>> sendEmailCode(String email) async {
    try {
      await _adapter.sendEmailVerifyCode(_site, email);
      return Success(PanelUser(
        email: email,
        trafficUsed: 0,
        trafficTotal: 0,
        expireAt: null,
        planName: '',
      ));
    } catch (e, s) {
      AppLogger.e('发送验证码失败', tag: LogTag.auth, error: e, stack: s);
      return Failure(_toAppError(e));
    }
  }

  Future<Result<PanelUser>> register(RegisterCredentials cred) async {
    try {
      final result = await _adapter.register(_site, cred);
      await _persistAuth(result.authData, result.user.email);
      _currentUser = result.user;
      return Success(result.user);
    } catch (e, s) {
      AppLogger.e('注册失败', tag: LogTag.auth, error: e, stack: s);
      return Failure(_toAppError(e));
    }
  }

  Future<Result<PanelUser>> login(String email, String password) async {
    try {
      final result = await _adapter.login(
        _site,
        Credentials(email: email, password: password),
      );
      await _persistAuth(result.authData, result.user.email);
      _currentUser = result.user;
      AppLogger.i('登录成功', tag: LogTag.auth);
      return Success(result.user);
    } catch (e, s) {
      AppLogger.e('登录失败', tag: LogTag.auth, error: e, stack: s);
      return Failure(_toAppError(e));
    }
  }

  Future<Result<bool>> resetPassword(
      String email, String code, String newPwd) async {
    try {
      await _adapter.resetPassword(_site, email, code, newPwd);
      return const Success(true);
    } catch (e, s) {
      AppLogger.e('重置密码失败', tag: LogTag.auth, error: e, stack: s);
      return Failure(_toAppError(e));
    }
  }

  Future<void> logout() async {
    final authData = await _storage.readAuthData();
    final email = await _storage.readEmail();
    if (authData != null && email != null) {
      try {
        await _adapter.logout(
          _site,
          AuthContext(authData: authData, email: email),
        );
      } catch (_) {}
    }
    await _storage.clearAll();
    _currentUser = null;
    AppLogger.i('已退出登录', tag: LogTag.auth);
  }

  Future<AuthContext?> getAuthContext() async {
    final authData = await _storage.readAuthData();
    final email = await _storage.readEmail();
    if (authData == null || email == null) return null;
    return AuthContext(authData: authData, email: email);
  }

  Future<void> _persistAuth(String authData, String email) async {
    await _storage.saveAuthData(authData);
    await _storage.saveEmail(email);
  }

  AppError _toAppError(Object e) {
    if (e is AppError) return e;
    return PanelUnavailableException(e.toString());
  }
}
