import 'package:flutter/foundation.dart';
import '../../core/models/proxy_node.dart';
import '../../core/result.dart';
import 'node_use_case.dart';

enum NodeLoadState { idle, loading, loaded, error }

class NodeNotifier extends ChangeNotifier {
  NodeNotifier({required NodeUseCase useCase}) : _useCase = useCase;

  final NodeUseCase _useCase;

  List<ProxyNode> _nodes = [];
  NodeLoadState _state = NodeLoadState.idle;
  String? _errorMessage;
  String _filter = '';

  List<ProxyNode> get nodes => _filter.isEmpty
      ? _nodes
      : _nodes
          .where((n) =>
              n.name.toLowerCase().contains(_filter.toLowerCase()) ||
              n.group.toLowerCase().contains(_filter.toLowerCase()))
          .toList();

  NodeLoadState get loadState => _state;
  String? get errorMessage => _errorMessage;
  String get filter => _filter;

  List<ProxyNode> get favoriteNodes =>
      _nodes.where((n) => _useCase.isFavorite(n.id)).toList();

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
}
