import 'package:flutter/foundation.dart';

import '../core/models/panel_user.dart';
import '../core/models/commercial/invite.dart';
import '../core/result.dart';
import '../features/profile/profile_use_case.dart';
import '../features/invite/invite_use_case.dart';
import '../features/auth/auth_notifier.dart';

/// ProfileController — 用户中心/邀请/礼品卡的固定 API 边界
class ProfileController extends ChangeNotifier {
  ProfileController({
    required ProfileUseCase profileUseCase,
    required InviteUseCase inviteUseCase,
    required AuthNotifier authNotifier,
  })  : _profileUseCase = profileUseCase,
        _inviteUseCase = inviteUseCase,
        _authNotifier = authNotifier;

  final ProfileUseCase _profileUseCase;
  final InviteUseCase _inviteUseCase;
  final AuthNotifier _authNotifier;

  PanelUser? _user;
  InviteSummary? _inviteSummary;
  bool _isLoading = false;
  String? _error;

  // ── 状态属性 ──
  PanelUser? get user => _user;
  InviteSummary? get inviteSummary => _inviteSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── 操作方法 ──
  Future<void> fetchUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _profileUseCase.fetchUser();
    _isLoading = false;

    switch (result) {
      case Success(value: final v):
        _user = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }

  Future<bool> changePassword(String oldPwd, String newPwd) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _profileUseCase.changePassword(
      oldPassword: oldPwd,
      newPassword: newPwd,
    );
    _isLoading = false;

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

  Future<void> logout() async {
    await _authNotifier.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> fetchInviteSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _inviteUseCase.fetchInviteSummary();
    _isLoading = false;

    switch (result) {
      case Success(value: final v):
        _inviteSummary = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }

  Future<bool> generateInviteCode() async {
    final result = await _inviteUseCase.generateInviteCode();
    switch (result) {
      case Success():
        await fetchInviteSummary();
        return true;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return false;
    }
  }
}
