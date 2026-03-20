import '../../core/errors/app_error.dart';
import '../../core/interfaces/panel_adapter.dart';
import '../../core/models/panel_site.dart';
import '../../core/models/commercial/notice.dart';
import '../../core/result.dart';
import '../../infrastructure/storage/secure_storage.dart';

class GiftCardUseCase {
  GiftCardUseCase({required PanelAdapter adapter, required PanelSite site})
      : _adapter = adapter,
        _site = site;

  final PanelAdapter _adapter;
  final PanelSite _site;

  Future<Result<GiftCardPreview>> checkGiftCard({required String code}) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final preview = await _adapter.checkGiftCard(_site, auth, code);
      return Success(preview);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<GiftCardRedeemResult>> redeemGiftCard({required String code}) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final result = await _adapter.redeemGiftCard(_site, auth, code);
      return Success(result);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<List<GiftCardUsage>>> fetchHistory() async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final history = await _adapter.fetchGiftCardHistory(_site, auth);
      return Success(history);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  AppError _toAppError(Object e) {
    if (e is AppError) return e;
    return PanelUnavailableException(e.toString());
  }
}
