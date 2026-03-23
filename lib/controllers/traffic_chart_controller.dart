import 'package:flutter/foundation.dart';

import '../core/models/commercial/notice.dart';
import '../core/result.dart';
import '../features/stat/stat_use_case.dart';

export '../core/models/commercial/notice.dart' show TrafficRecord;

/// TrafficChartController — 流量统计图表的固定 API 边界
class TrafficChartController extends ChangeNotifier {
  TrafficChartController({required StatUseCase statUseCase})
      : _useCase = statUseCase;

  final StatUseCase _useCase;

  List<TrafficRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  // ── 状态属性 ──
  List<TrafficRecord> get records => _records;
  int get totalUpload =>
      _records.fold(0, (sum, r) => sum + r.uploadBytes);
  int get totalDownload =>
      _records.fold(0, (sum, r) => sum + r.downloadBytes);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── 操作方法 ──
  Future<void> fetchTrafficLog() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.fetchTrafficLog();
    _isLoading = false;

    switch (result) {
      case Success(value: final v):
        _records = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }
}
