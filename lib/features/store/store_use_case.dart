import '../../core/errors/app_error.dart';
import '../../core/interfaces/panel_adapter.dart';
import '../../core/models/panel_site.dart';
import '../../core/models/commercial/plan_item.dart';
import '../../core/models/commercial/order.dart';
import '../../core/result.dart';
import '../../infrastructure/storage/secure_storage.dart';

class StoreUseCase {
  StoreUseCase({required PanelAdapter adapter, required PanelSite site})
      : _adapter = adapter,
        _site = site;

  final PanelAdapter _adapter;
  final PanelSite _site;

  Future<Result<List<PlanItem>>> fetchPlans() async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final plans = await _adapter.fetchPlans(_site, auth);
      return Success(plans);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<String>> createOrder({
    required int planId,
    required String period,
    String? couponCode,
  }) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final tradeNo = await _adapter.createOrder(
          _site, auth, OrderRequest(planId: planId, period: period, couponCode: couponCode));
      return Success(tradeNo);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<PaymentResult>> checkout({
    required String tradeNo,
    required int methodId,
  }) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final result = await _adapter.checkout(_site, auth, tradeNo, methodId);
      return Success(result);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<List<PaymentMethod>>> fetchPaymentMethods() async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final methods = await _adapter.fetchPaymentMethods(_site, auth);
      return Success(methods);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<CouponInfo>> checkCoupon({
    required String code,
    required int planId,
  }) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final info = await _adapter.checkCoupon(
          _site, auth, CouponCheckRequest(code: code, planId: planId));
      return Success(info);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  AppError _toAppError(Object e) {
    if (e is AppError) return e;
    return PanelUnavailableException(e.toString());
  }
}
