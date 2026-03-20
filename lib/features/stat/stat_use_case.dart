import '../../core/errors/app_error.dart';
import '../../core/interfaces/panel_adapter.dart';
import '../../core/models/panel_site.dart';
import '../../core/models/panel_user.dart';
import '../../core/result.dart';
import '../../infrastructure/storage/secure_storage.dart';

class StatUseCase {
  StatUseCase({required PanelAdapter adapter, required PanelSite site})
      : _adapter = adapter,
        _site = site;

  final PanelAdapter _adapter;
  final PanelSite _site;

  Future<Result<UserStat>> fetchStat() async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final stat = await _adapter.fetchUserStat(_site, auth);
      return Success(stat);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  AppError _toAppError(Object e) {
    if (e is AppError) return e;
    return PanelUnavailableException(e.toString());
  }
}
