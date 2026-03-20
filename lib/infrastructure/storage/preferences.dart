import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 封装 — 轻量配置（非敏感数据）
class AppPreferences {
  AppPreferences._(this._prefs);

  static AppPreferences? _instance;
  final SharedPreferences _prefs;

  static Future<AppPreferences> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = AppPreferences._(prefs);
    return _instance!;
  }

  static AppPreferences get instance {
    assert(_instance != null, 'AppPreferences.init() must be called first');
    return _instance!;
  }

  // ── locale ────────────────────────────────────────────────────────────────
  static const _keyLocale = 'hyena.locale';
  String? get locale => _prefs.getString(_keyLocale);
  Future<void> setLocale(String tag) => _prefs.setString(_keyLocale, tag);

  // ── 最近使用节点 ────────────────────────────────────────────────────────────
  static const _keyLastNodeId = 'hyena.lastNodeId';
  String? get lastNodeId => _prefs.getString(_keyLastNodeId);
  Future<void> setLastNodeId(String id) => _prefs.setString(_keyLastNodeId, id);

  // ── 自动连接 ────────────────────────────────────────────────────────────────
  static const _keyAutoConnect = 'hyena.autoConnect';
  bool get autoConnect => _prefs.getBool(_keyAutoConnect) ?? false;
  Future<void> setAutoConnect(bool v) => _prefs.setBool(_keyAutoConnect, v);

  // ── 路由模式 ────────────────────────────────────────────────────────────────
  static const _keyRoutingMode = 'hyena.routingMode';
  String get routingMode => _prefs.getString(_keyRoutingMode) ?? 'rule';
  Future<void> setRoutingMode(String mode) => _prefs.setString(_keyRoutingMode, mode);

  // ── 收藏节点 ID 列表 ────────────────────────────────────────────────────────
  static const _keyFavorites = 'hyena.favorites';
  List<String> get favoriteNodeIds => _prefs.getStringList(_keyFavorites) ?? [];
  Future<void> setFavoriteNodeIds(List<String> ids) =>
      _prefs.setStringList(_keyFavorites, ids);

  // ── 皮肤 ID ─────────────────────────────────────────────────────────────────
  static const _keySkinId = 'hyena.skinId';
  String? get skinId => _prefs.getString(_keySkinId);
  Future<void> setSkinId(String id) => _prefs.setString(_keySkinId, id);
}
