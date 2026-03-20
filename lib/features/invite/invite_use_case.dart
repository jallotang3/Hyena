import '../../core/errors/app_error.dart';
import '../../core/interfaces/panel_adapter.dart';
import '../../core/models/panel_site.dart';
import '../../core/models/commercial/invite.dart';
import '../../core/result.dart';
import '../../infrastructure/storage/secure_storage.dart';

class InviteUseCase {
  InviteUseCase({required PanelAdapter adapter, required PanelSite site})
      : _adapter = adapter,
        _site = site;

  final PanelAdapter _adapter;
  final PanelSite _site;

  Future<Result<InviteSummary>> fetchInviteSummary() async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final summary = await _adapter.fetchInviteSummary(_site, auth);
      return Success(summary);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<bool>> generateInviteCode() async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final ok = await _adapter.generateInviteCode(_site, auth);
      return Success(ok);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  AppError _toAppError(Object e) {
    if (e is AppError) return e;
    return PanelUnavailableException(e.toString());
  }
}
