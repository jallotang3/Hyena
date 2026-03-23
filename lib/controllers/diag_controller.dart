import 'package:flutter/foundation.dart';

import '../core/models/traffic_stats.dart';
import '../infrastructure/logging/app_logger.dart';

export '../core/models/traffic_stats.dart' show EngineState;
import '../infrastructure/logging/log_file_manager.dart';
import '../features/connection/connection_use_case.dart';

/// DiagController — 诊断页的固定 API 边界
class DiagController extends ChangeNotifier {
  DiagController({required ConnectionUseCase connectionUseCase})
      : _conn = connectionUseCase;

  final ConnectionUseCase _conn;

  bool _isExporting = false;

  // ── 状态属性 ──
  List<String> get logs => AppLogger.recentLogs.reversed.toList();
  EngineState get connectionState => _conn.state;
  Duration get connectionDuration => _conn.connectionDuration;
  bool get isExporting => _isExporting;

  // ── 操作方法 ──
  void refreshLogs() {
    notifyListeners();
  }

  Future<void> exportLogs() async {
    _isExporting = true;
    notifyListeners();

    await LogFileManager.instance.shareExport();

    _isExporting = false;
    notifyListeners();
  }

  Future<void> runDiagnostics() async {
    AppLogger.i('=== 诊断开始 ===', tag: LogTag.general);
    AppLogger.i('连接状态: ${_conn.state}', tag: LogTag.general);
    if (_conn.connectedSince != null) {
      AppLogger.i('连接时长: ${_conn.connectionDuration}', tag: LogTag.general);
    }
    AppLogger.i('当前节点: ${_conn.currentNode?.name ?? "无"}', tag: LogTag.general);
    AppLogger.i('路由模式: ${_conn.currentMode}', tag: LogTag.general);
    AppLogger.i('=== 诊断完成 ===', tag: LogTag.general);
    notifyListeners();
  }
}
