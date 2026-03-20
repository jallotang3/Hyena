import '../../core/errors/app_error.dart';
import '../../core/interfaces/panel_adapter.dart';
import '../../core/models/panel_site.dart';
import '../../core/models/proxy_node.dart';
import '../../core/result.dart';
import '../../infrastructure/logging/app_logger.dart';
import '../../infrastructure/storage/cache_storage.dart';
import '../../infrastructure/storage/preferences.dart';
import '../../infrastructure/storage/secure_storage.dart';

class NodeUseCase {
  NodeUseCase({required PanelAdapter adapter, required PanelSite site})
      : _adapter = adapter,
        _site = site;

  final PanelAdapter _adapter;
  final PanelSite _site;

  Future<Result<List<ProxyNode>>> fetchNodes({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _nodesFromCache();
      if (cached != null) {
        AppLogger.d('节点命中缓存: ${cached.length} 个', tag: LogTag.node);
        return Success(cached);
      }
    }
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final nodes = await _adapter.fetchNodes(_site, auth);
      await _cacheNodes(nodes);
      return Success(nodes);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  List<String> getFavoriteIds() => AppPreferences.instance.favoriteNodeIds;

  Future<void> toggleFavorite(String nodeId) async {
    final prefs = AppPreferences.instance;
    final favorites = List<String>.from(prefs.favoriteNodeIds);
    if (favorites.contains(nodeId)) {
      favorites.remove(nodeId);
    } else {
      favorites.add(nodeId);
    }
    await prefs.setFavoriteNodeIds(favorites);
  }

  bool isFavorite(String nodeId) =>
      AppPreferences.instance.favoriteNodeIds.contains(nodeId);

  String? getLastNodeId() => AppPreferences.instance.lastNodeId;
  Future<void> setLastNodeId(String id) =>
      AppPreferences.instance.setLastNodeId(id);

  List<ProxyNode>? _nodesFromCache() {
    final raw = CacheStorage.instance.getCachedNodes();
    if (raw == null) return null;
    try {
      return raw.map(ProxyNode.fromJson).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheNodes(List<ProxyNode> nodes) async {
    final raw = nodes.map((n) => n.toJson()).toList();
    await CacheStorage.instance.cacheNodes(raw);
  }

  AppError _toAppError(Object e) {
    if (e is AppError) return e;
    return PanelUnavailableException(e.toString());
  }
}
