import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/models/commercial/order.dart';
import '../core/result.dart';
import '../features/order/order_use_case.dart';

/// OrderController — 订单中心/详情/支付结果的固定 API 边界
class OrderController extends ChangeNotifier {
  OrderController({required OrderUseCase orderUseCase})
      : _useCase = orderUseCase;

  final OrderUseCase _useCase;

  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;
  bool _isPaid = false;

  // ── 状态属性 ──
  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPaid => _isPaid;

  // ── 操作方法 ──
  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.fetchOrders();
    _isLoading = false;

    switch (result) {
      case Success(value: final v):
        _orders = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }

  Future<void> fetchOrderDetail(String tradeNo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.fetchOrderDetail(tradeNo: tradeNo);
    _isLoading = false;

    switch (result) {
      case Success(value: final v):
        _currentOrder = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }

  Future<bool> cancelOrder(String tradeNo) async {
    final result = await _useCase.cancelOrder(tradeNo: tradeNo);
    switch (result) {
      case Success():
        await fetchOrders();
        return true;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> checkOrderStatus(String tradeNo) async {
    final result = await _useCase.checkOrderStatus(tradeNo: tradeNo);
    switch (result) {
      case Success(value: final status):
        _isPaid = status == 3; // 3 = paid in xboard
        notifyListeners();
        return _isPaid;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return false;
    }
  }

  Future<void> pollPaymentStatus(String tradeNo) async {
    for (int i = 0; i < 100; i++) {
      final paid = await checkOrderStatus(tradeNo);
      if (paid) return;
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}
