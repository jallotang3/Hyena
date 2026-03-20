import 'package:flutter/foundation.dart';

import '../core/models/commercial/notice.dart';
import '../core/result.dart';
import '../features/notice/notice_use_case.dart';

/// NoticeController — 公告列表的固定 API 边界
class NoticeController extends ChangeNotifier {
  NoticeController({required NoticeUseCase noticeUseCase})
      : _useCase = noticeUseCase;

  final NoticeUseCase _useCase;

  List<Notice> _notices = [];
  bool _isLoading = false;
  String? _error;

  // ── 状态属性 ──
  List<Notice> get notices => _notices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── 操作方法 ──
  Future<void> fetchNotices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.fetchNotices();
    _isLoading = false;

    switch (result) {
      case Success(value: final v):
        _notices = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }

  void markAsRead(int noticeId) {
    notifyListeners();
  }
}
