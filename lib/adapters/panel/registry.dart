import '../../core/interfaces/panel_adapter.dart';
import '../../core/errors/app_error.dart';

/// 面板适配器注册中心 — 按 panelType 字符串查找适配器实现
class PanelAdapterRegistry {
  PanelAdapterRegistry._();
  static final PanelAdapterRegistry instance = PanelAdapterRegistry._();

  final Map<String, PanelAdapter> _adapters = {};

  /// 注册适配器（应用启动时调用）
  void register(PanelAdapter adapter) {
    _adapters[adapter.panelType] = adapter;
  }

  /// 按 panelType 获取适配器，未注册则抛出异常
  PanelAdapter resolve(String panelType) {
    final adapter = _adapters[panelType];
    if (adapter == null) throw UnsupportedPanelException(panelType);
    return adapter;
  }

  bool isSupported(String panelType) => _adapters.containsKey(panelType);

  List<String> get supportedPanelTypes => List.unmodifiable(_adapters.keys);
}
