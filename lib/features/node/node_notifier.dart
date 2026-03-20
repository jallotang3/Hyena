import 'package:flutter/foundation.dart';
import '../../core/models/proxy_node.dart';
import '../../core/result.dart';
import 'node_latency_service.dart';
import 'node_use_case.dart';

enum NodeLoadState { idle, loading, loaded, error }

enum NodeSortMode { name, latency, group }

class NodeNotifier extends ChangeNotifier {
  NodeNotifier({required NodeUseCase useCase}) : _useCase = useCase;

  final NodeUseCase _useCase;

  List<ProxyNode> _nodes = [];
  NodeLoadState _state = NodeLoadState.idle;
  String? _errorMessage;
  String _filter = '';
  NodeSortMode _sortMode = NodeSortMode.name;
  bool _testing = false;

  NodeLoadState get loadState => _state;
  String? get errorMessage => _errorMessage;
  String get filter => _filter;
  NodeSortMode get sortMode => _sortMode;
  bool get isTesting => _testing;

  List<ProxyNode> get nodes {
    var list = _filter.isEmpty
        ? List<ProxyNode>.from(_nodes)
        : _nodes
            .where((n) =>
                n.name.toLowerCase().contains(_filter.toLowerCase()) ||
                n.group.toLowerCase().contains(_filter.toLowerCase()))
            .toList();
    _applySort(list);
    return list;
  }

  List<ProxyNode> get favoriteNodes {
    final list = _nodes.where((n) => _useCase.isFavorite(n.id)).toList();
    _applySort(list);
    return list;
  }

  Future<void> load({bool forceRefresh = false}) async {
    _state = NodeLoadState.loading;
    notifyListeners();

    final result = await _useCase.fetchNodes(forceRefresh: forceRefresh);

    if (result.isSuccess) {
      final ids = _useCase.getFavoriteIds();
      _nodes = result.value
          .map((n) => n.copyWith(isFavorite: ids.contains(n.id)))
          .toList();
      _state = NodeLoadState.loaded;
      _errorMessage = null;
    } else {
      _state = NodeLoadState.error;
      _errorMessage = (result as Failure).error.message;
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(String nodeId) async {
    await _useCase.toggleFavorite(nodeId);
    final ids = _useCase.getFavoriteIds();
    _nodes = _nodes
        .map((n) => n.copyWith(isFavorite: ids.contains(n.id)))
        .toList();
    notifyListeners();
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  void setSortMode(NodeSortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  /// 单节点测速
  Future<void> testNode(String nodeId) async {
    final idx = _nodes.indexWhere((n) => n.id == nodeId);
    if (idx == -1) return;
    final node = _nodes[idx];
    final latency = await NodeLatencyService.testSingle(node);
    _nodes[idx] = node.copyWith(latency: latency);
    notifyListeners();
  }

  /// 全量批量测速
  Future<void> testAllNodes() async {
    if (_testing) return;
    _testing = true;
    notifyListeners();

    await NodeLatencyService.testBatch(
      _nodes,
      onResult: (nodeId, latency) {
        final idx = _nodes.indexWhere((n) => n.id == nodeId);
        if (idx != -1) {
          _nodes[idx] = _nodes[idx].copyWith(latency: latency);
          notifyListeners();
        }
      },
    );

    _testing = false;
    notifyListeners();
  }

  void _applySort(List<ProxyNode> list) {
    switch (_sortMode) {
      case NodeSortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case NodeSortMode.latency:
        list.sort((a, b) {
          if (a.latency == null && b.latency == null) return 0;
          if (a.latency == null) return 1;
          if (b.latency == null) return -1;
          return a.latency!.compareTo(b.latency!);
        });
      case NodeSortMode.group:
        list.sort((a, b) {
          final g = a.group.compareTo(b.group);
          return g != 0 ? g : a.name.compareTo(b.name);
        });
    }
  }
}
