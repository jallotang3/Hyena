import '../../core/errors/app_error.dart';
import '../../core/interfaces/panel_adapter.dart';
import '../../core/models/panel_site.dart';
import '../../core/models/commercial/order.dart';
import '../../core/result.dart';
import '../../infrastructure/storage/secure_storage.dart';

class OrderUseCase {
  OrderUseCase({required PanelAdapter adapter, required PanelSite site})
      : _adapter = adapter,
        _site = site;

  final PanelAdapter _adapter;
  final PanelSite _site;

  Future<Result<List<Order>>> fetchOrders({int? status}) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final orders = await _adapter.fetchOrders(_site, auth, status: status);
      return Success(orders);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<bool>> cancelOrder({required String tradeNo}) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final ok = await _adapter.cancelOrder(_site, auth, tradeNo);
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
