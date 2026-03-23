import '../infrastructure/logging/app_logger.dart';
import '../platforms/platform_page_factory.dart';
import 'skin_contract.dart';
import 'skin_page_factory.dart';
import 'theme_token_provider.dart';
import 'default/theme_tokens.dart';
import 'default/default_page_factory.dart';
import 'brand_x/theme_tokens.dart';
import 'brand_x/brand_x_page_factory.dart';

/// 皮肤管理器 — 按 skinId 加载皮肤包，加载失败自动回退 default
///
/// 架构说明：
/// - PlatformPageFactory: 处理平台差异（移动端/桌面端/iOS）
/// - SkinPageFactory: 处理品牌定制（可选覆盖特定页面）
/// - ThemeTokens: 处理主题样式（颜色/字体/圆角）
class SkinManager {
  SkinManager._();
  static final SkinManager instance = SkinManager._();

  static const String _supportedContractVersion = '1';

  late PlatformPageFactory _platformFactory;
  ThemeTokens _tokens = kDefaultThemeTokens;
  SkinPageFactory _pageFactory = DefaultPageFactory();
  String _activeSkinId = 'default';

  /// 平台页面工厂（处理平台差异）
  PlatformPageFactory get platformFactory => _platformFactory;

  /// 主题令牌（处理品牌样式）
  ThemeTokens get tokens => _tokens;

  /// 皮肤页面工厂（可选覆盖特定页面）
  SkinPageFactory get pageFactory => _pageFactory;

  String get activeSkinId => _activeSkinId;

  /// 初始化平台工厂
  void initPlatform() {
    _platformFactory = PlatformPageFactory.create();
    AppLogger.i('平台工厂初始化: ${_platformFactory.platformType}', tag: LogTag.skin);
  }

  Future<void> load(String skinId) async {
    try {
      final contract = await _resolveSkin(skinId);
      final major = contract.contractVersion.split('.').first;
      if (major != _supportedContractVersion) {
        AppLogger.w(
          '皮肤 $skinId 合约版本 ${contract.contractVersion} 不兼容'
          '（需要 $_supportedContractVersion.x），降级使用 default',
          tag: LogTag.skin,
        );
        _fallbackToDefault();
        return;
      }
      _tokens = contract.themeTokens;
      _pageFactory = contract.pageFactory;
      _activeSkinId = contract.skinId;
      AppLogger.i('皮肤加载成功: $skinId (v${contract.contractVersion})',
          tag: LogTag.skin);
    } catch (e) {
      AppLogger.w('皮肤 $skinId 加载失败，回退到 default: $e', tag: LogTag.skin);
      _fallbackToDefault();
    }
  }

  void _fallbackToDefault() {
    _tokens = kDefaultThemeTokens;
    _pageFactory = DefaultPageFactory();
    _activeSkinId = 'default';
  }

  Future<SkinContract> _resolveSkin(String skinId) async {
    return switch (skinId) {
      'default' => _DefaultSkinContract(),
      'brand_x' => _BrandXSkinContract(),
      _ => throw ArgumentError('Unknown skinId: $skinId'),
    };
  }
}

class _DefaultSkinContract implements SkinContract {
  @override
  String get contractVersion => '1.0.0';
  @override
  String get skinId => 'default';
  @override
  ThemeTokens get themeTokens => kDefaultThemeTokens;
  @override
  SkinPageFactory get pageFactory => DefaultPageFactory();
}

class _BrandXSkinContract implements SkinContract {
  @override
  String get contractVersion => '1.0.0';
  @override
  String get skinId => 'brand_x';
  @override
  ThemeTokens get themeTokens => kBrandXThemeTokens;
  @override
  SkinPageFactory get pageFactory => BrandXPageFactory();
}
