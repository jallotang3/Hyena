import 'package:flutter/foundation.dart';

import '../core/models/proxy_node.dart';
import '../core/result.dart';
import '../features/auth/auth_use_case.dart';
import '../features/node/node_use_case.dart';
import '../features/connection/connection_use_case.dart';
import '../infrastructure/logging/app_logger.dart';

/// SplashController — 启动页的固定 API 边界
class SplashController extends ChangeNotifier {
  SplashController({
    required AuthUseCase authUseCase,
    required NodeUseCase nodeUseCase,
    required ConnectionUseCase connectionUseCase,
  })  : _authUseCase = authUseCase,
        _nodeUseCase = nodeUseCase,
        _connUseCase = connectionUseCase;

  final AuthUseCase _authUseCase;
  final NodeUseCase _nodeUseCase;
  final ConnectionUseCase _connUseCase;

  bool _isInitialized = false;
  String? _shouldNavigateTo;

  // ── 状态属性 ──
  bool get isInitialized => _isInitialized;
  String? get shouldNavigateTo => _shouldNavigateTo;

  // ── 操作方法 ──
  Future<void> initialize() async {
    try {
      final restored = await _authUseCase.restoreSession();
      if (restored) {
        _shouldNavigateTo = '/home';
        _tryAutoConnect();
      } else {
        _shouldNavigateTo = '/login';
      }
    } catch (e) {
      AppLogger.e('启动初始化失败: $e', tag: LogTag.general);
      _shouldNavigateTo = '/login';
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _tryAutoConnect() async {
    try {
      final lastId = _nodeUseCase.getLastNodeId();
      if (lastId == null) return;

      final nodesResult = await _nodeUseCase.fetchNodes();
      if (nodesResult is! Success<List<ProxyNode>>) return;

      final nodes = nodesResult.value;
      ProxyNode? lastNode;
      for (final n in nodes) {
        if (n.id == lastId) {
          lastNode = n;
          break;
        }
      }

      await _connUseCase.tryAutoConnect(lastNode);
    } catch (e) {
      AppLogger.w('自动连接失败: $e', tag: LogTag.vpn);
    }
  }
}
