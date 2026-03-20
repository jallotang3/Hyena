import '../../core/errors/app_error.dart';
import '../../core/interfaces/panel_adapter.dart';
import '../../core/models/panel_site.dart';
import '../../core/models/panel_user.dart';
import '../../core/models/commercial/notice.dart';
import '../../core/result.dart';
import '../../infrastructure/storage/cache_storage.dart';
import '../../infrastructure/storage/secure_storage.dart';

class ProfileUseCase {
  ProfileUseCase({required PanelAdapter adapter, required PanelSite site})
      : _adapter = adapter,
        _site = site;

  final PanelAdapter _adapter;
  final PanelSite _site;

  Future<Result<PanelUser>> fetchUser() async {
    final cached = CacheStorage.instance.getCachedUser();
    if (cached != null) {
      try {
        return Success(PanelUser.fromJson(cached));
      } catch (_) {}
    }
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final user = await _adapter.fetchUserInfo(_site, auth);
      await CacheStorage.instance.cacheUser(user.toJson());
      return Success(user);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<List<TrafficRecord>>> fetchTrafficLogs() async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final logs = await _adapter.fetchTrafficLog(_site, auth);
      return Success(logs);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<bool>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final ok = await _adapter.changePassword(_site, auth, oldPassword, newPassword);
      return Success(ok);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<void> invalidateCache() =>
      CacheStorage.instance.clearBox('hyena_user');

  AppError _toAppError(Object e) {
    if (e is AppError) return e;
    return PanelUnavailableException(e.toString());
  }
}
