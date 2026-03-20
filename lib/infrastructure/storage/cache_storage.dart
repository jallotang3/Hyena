import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../logging/app_logger.dart';

/// Hive 缓存层 — 节点列表、用户信息、套餐等结构化缓存
class CacheStorage {
  CacheStorage._();
  static final CacheStorage instance = CacheStorage._();

  static const _boxNodes = 'hyena_nodes';
  static const _boxUser = 'hyena_user';
  static const _boxPlans = 'hyena_plans';
  static const _boxOrders = 'hyena_orders';
  static const _ttlKeyPrefix = '_ttl_';

  bool _initialized = false;

  /// 应用启动时调用一次
  static Future<void> initialize() async {
    if (instance._initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(dir.path);
      await Hive.openBox<dynamic>(_boxNodes);
      await Hive.openBox<dynamic>(_boxUser);
      await Hive.openBox<dynamic>(_boxPlans);
      await Hive.openBox<dynamic>(_boxOrders);
      instance._initialized = true;
      AppLogger.i('CacheStorage 初始化完成', tag: LogTag.storage);
    } catch (e) {
      AppLogger.e('CacheStorage 初始化失败: $e', tag: LogTag.storage);
    }
  }

  // ── 通用操作 ──────────────────────────────────────────────────────────────

  Future<void> put(String box, String key, dynamic value,
      {Duration? ttl}) async {
    final b = Hive.box<dynamic>(box);
    await b.put(key, value);
    if (ttl != null) {
      await b.put(
        '$_ttlKeyPrefix$key',
        DateTime.now().add(ttl).millisecondsSinceEpoch,
      );
    }
  }

  dynamic get(String box, String key) {
    final b = Hive.box<dynamic>(box);
    final ttlKey = '$_ttlKeyPrefix$key';
    final expiry = b.get(ttlKey) as int?;
    if (expiry != null &&
        DateTime.now().millisecondsSinceEpoch > expiry) {
      b.delete(key);
      b.delete(ttlKey);
      return null;
    }
    return b.get(key);
  }

  Future<void> delete(String box, String key) async {
    final b = Hive.box<dynamic>(box);
    await b.delete(key);
    await b.delete('$_ttlKeyPrefix$key');
  }

  Future<void> clearBox(String box) async {
    await Hive.box<dynamic>(box).clear();
  }

  // ── 节点缓存 ──────────────────────────────────────────────────────────────

  static const _nodeListKey = 'node_list';
  static const _nodeTtl = Duration(hours: 1);

  Future<void> cacheNodes(List<Map<String, dynamic>> rawNodes) async {
    await put(_boxNodes, _nodeListKey, rawNodes, ttl: _nodeTtl);
    AppLogger.d('节点缓存写入: ${rawNodes.length} 个', tag: LogTag.storage);
  }

  List<Map<String, dynamic>>? getCachedNodes() {
    final cached = get(_boxNodes, _nodeListKey);
    if (cached == null) return null;
    try {
      return (cached as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── 用户信息缓存 ──────────────────────────────────────────────────────────

  static const _userKey = 'user_info';
  static const _userTtl = Duration(minutes: 5);

  Future<void> cacheUser(Map<String, dynamic> data) async {
    await put(_boxUser, _userKey, data, ttl: _userTtl);
  }

  Map<String, dynamic>? getCachedUser() {
    final cached = get(_boxUser, _userKey);
    if (cached == null) return null;
    try {
      return Map<String, dynamic>.from(cached as Map);
    } catch (_) {
      return null;
    }
  }

  // ── 套餐缓存 ──────────────────────────────────────────────────────────────

  static const _planListKey = 'plan_list';
  static const _planTtl = Duration(hours: 2);

  Future<void> cachePlans(List<Map<String, dynamic>> plans) async {
    await put(_boxPlans, _planListKey, plans, ttl: _planTtl);
  }

  List<Map<String, dynamic>>? getCachedPlans() {
    final cached = get(_boxPlans, _planListKey);
    if (cached == null) return null;
    try {
      return (cached as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── 清理所有缓存 ──────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await clearBox(_boxNodes);
    await clearBox(_boxUser);
    await clearBox(_boxPlans);
    await clearBox(_boxOrders);
  }
}
