import '../../config/app_config.dart';

/// 每个发行包对应唯一站点，baseUrl / panelType 由构建期 CI/CD 模板注入，
/// 运行时从编译常量读取，用户不可修改。
class PanelSite {
  const PanelSite({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.panelType,
  });

  final String id;
  final String name;

  /// 面板 API 基础路径，例如 https://panel.example.com
  final String baseUrl;

  /// 面板类型标识：xboard / v2board / sspanel
  final String panelType;

  /// 从构建期编译常量构造（dart-define 注入）
  factory PanelSite.fromBuildConfig() => PanelSite(
        id: AppConfig.siteId,
        name: AppConfig.siteName,
        baseUrl: AppConfig.panelApiBase,
        panelType: AppConfig.panelType,
      );

  @override
  String toString() => 'PanelSite($panelType @ $baseUrl)';
}
