import 'package:flutter/foundation.dart';

import '../core/models/proxy_node.dart';
import '../features/node/node_notifier.dart';
import '../features/connection/connection_use_case.dart';
import '../infrastructure/storage/preferences.dart';

/// NodeController — 节点列表的固定 API 边界
class NodeController extends ChangeNotifier {
  NodeController({
    required NodeNotifier nodeNotifier,
    required ConnectionUseCase connectionUseCase,
  })  : _nodeNotifier = nodeNotifier,
        _conn = connectionUseCase {
    _nodeNotifier.addListener(_onNotifierChanged);
  }

  final NodeNotifier _nodeNotifier;
  final ConnectionUseCase _conn;

  void _onNotifierChanged() => notifyListeners();

  // ── 状态属性 ──
  List<ProxyNode> get nodes => _nodeNotifier.nodes;
  List<ProxyNode> get favoriteNodes => _nodeNotifier.favoriteNodes;
  bool get isLoading => _nodeNotifier.loadState == NodeLoadState.loading;
  bool get isTesting => _nodeNotifier.isTesting;
  String? get error => _nodeNotifier.errorMessage;
  NodeSortMode get sortMode => _nodeNotifier.sortMode;
  ProxyNode? get selectedNode => _conn.currentNode;

  // ── 操作方法 ──
  Future<void> load({bool forceRefresh = false}) async {
    await _nodeNotifier.load(forceRefresh: forceRefresh);
  }

  Future<void> testAllNodes() async {
    await _nodeNotifier.testAllNodes();
  }

  void setSortMode(NodeSortMode mode) {
    _nodeNotifier.setSortMode(mode);
  }

  void setFilter(String keyword) {
    _nodeNotifier.setFilter(keyword);
  }

  void toggleFavorite(String nodeId) {
    _nodeNotifier.toggleFavorite(nodeId);
  }

  Future<void> selectAndConnect(ProxyNode node) async {
    await AppPreferences.instance.setLastNodeId(node.id);
    await _conn.connect(node);
    notifyListeners();
  }

  @override
  void dispose() {
    _nodeNotifier.removeListener(_onNotifierChanged);
    super.dispose();
  }
}
