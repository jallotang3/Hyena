import 'package:flutter/material.dart';
import 'auth_use_case.dart';

/// ChangeNotifier 包装器 — 让 Provider Consumer 感知登录态变化
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this.useCase);
  final AuthUseCase useCase;

  bool get isLoggedIn => useCase.isLoggedIn;

  Future<void> restoreSession() async {
    await useCase.restoreSession();
    notifyListeners();
  }

  Future<void> logout() async {
    await useCase.logout();
    notifyListeners();
  }
}
