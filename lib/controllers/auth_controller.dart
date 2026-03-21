import 'package:flutter/foundation.dart';

import '../core/interfaces/panel_adapter.dart';
import '../core/result.dart';
import '../features/auth/auth_use_case.dart';
import '../features/auth/auth_notifier.dart';

/// AuthController — 登录/注册/忘记密码的固定 API 边界
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthUseCase authUseCase,
    required AuthNotifier authNotifier,
  })  : _useCase = authUseCase,
        _authNotifier = authNotifier;

  final AuthUseCase _useCase;
  final AuthNotifier _authNotifier;

  bool _isLoading = false;
  bool _isSendingCode = false;
  String? _error;
  bool _resetSuccess = false;

  // ── 状态属性 ──
  bool get isLoading => _isLoading;
  bool get isSendingCode => _isSendingCode;
  String? get error => _error;
  bool get resetSuccess => _resetSuccess;

  // ── 操作方法 ──
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.login(email, password);
    _isLoading = false;

    switch (result) {
      case Success():
        _authNotifier.notifyAuthChanged();
        notifyListeners();
        return true;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String emailCode,
    String? inviteCode,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.register(RegisterCredentials(
      email: email,
      password: password,
      emailCode: emailCode,
      inviteCode: inviteCode,
    ));
    _isLoading = false;

    switch (result) {
      case Success():
        _authNotifier.notifyAuthChanged();
        notifyListeners();
        return true;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> sendEmailCode(String email) async {
    _isSendingCode = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.sendEmailCode(email);
    _isSendingCode = false;

    switch (result) {
      case Success():
        notifyListeners();
        return true;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    _isLoading = true;
    _error = null;
    _resetSuccess = false;
    notifyListeners();

    final result = await _useCase.resetPassword(email, code, newPassword);
    _isLoading = false;

    switch (result) {
      case Success():
        _resetSuccess = true;
        notifyListeners();
        return true;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
