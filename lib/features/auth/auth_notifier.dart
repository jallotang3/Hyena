import 'package:flutter/material.dart';
import 'auth_use_case.dart';

/// ChangeNotifier 包装器 — 让 Provider Consumer 感知登录态变化
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._useCase);
  final AuthUseCase _useCase;

  bool get isLoggedIn => _useCase.isLoggedIn;

  Future<void> restoreSession() async {
    await _useCase.restoreSession();
    notifyListeners();
  }

  Future<void> logout() async {
    await _useCase.logout();
    notifyListeners();
  }

  /// 登录/注册成功后由 AuthController 调用，通知所有监听登录态的 Widget 刷新
  void notifyAuthChanged() => notifyListeners();
}
