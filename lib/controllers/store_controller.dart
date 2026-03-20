import 'package:flutter/foundation.dart';

import '../core/models/commercial/plan_item.dart';
import '../core/models/commercial/order.dart';
import '../core/result.dart';
import '../features/store/store_use_case.dart';

/// StoreController — 商店/下单的固定 API 边界
class StoreController extends ChangeNotifier {
  StoreController({required StoreUseCase storeUseCase})
      : _useCase = storeUseCase;

  final StoreUseCase _useCase;

  List<PlanItem> _plans = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedPeriod;
  CouponInfo? _couponResult;
  List<PaymentMethod> _paymentMethods = [];
  bool _isSubmitting = false;

  // ── 状态属性 ──
  List<PlanItem> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedPeriod => _selectedPeriod;
  CouponInfo? get couponResult => _couponResult;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get isSubmitting => _isSubmitting;

  // ── 操作方法 ──
  Future<void> fetchPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.fetchPlans();
    _isLoading = false;

    switch (result) {
      case Success(value: final v):
        _plans = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }

  void selectPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  Future<void> checkCoupon(String code, int planId) async {
    final result = await _useCase.checkCoupon(code: code, planId: planId);
    switch (result) {
      case Success(value: final v):
        _couponResult = v;
      case Failure(error: final e):
        _error = e.message;
        _couponResult = null;
    }
    notifyListeners();
  }

  Future<String?> createOrder(
    int planId,
    String period,
    String? couponCode,
  ) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.createOrder(
      planId: planId,
      period: period,
      couponCode: couponCode,
    );
    _isSubmitting = false;

    switch (result) {
      case Success(value: final tradeNo):
        notifyListeners();
        return tradeNo;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return null;
    }
  }

  Future<void> fetchPaymentMethods() async {
    final result = await _useCase.fetchPaymentMethods();
    switch (result) {
      case Success(value: final v):
        _paymentMethods = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }

  Future<PaymentResult?> checkout(String tradeNo, int methodId) async {
    _isSubmitting = true;
    notifyListeners();

    final result = await _useCase.checkout(
      tradeNo: tradeNo,
      methodId: methodId,
    );
    _isSubmitting = false;

    switch (result) {
      case Success(value: final v):
        notifyListeners();
        return v;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return null;
    }
  }
}
