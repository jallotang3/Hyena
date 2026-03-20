import '../infrastructure/logging/app_logger.dart';
import 'skin_contract.dart';
import 'skin_page_factory.dart';
import 'theme_token_provider.dart';
import 'default/theme_tokens.dart';
import 'default/default_page_factory.dart';

/// 皮肤管理器 — 按 skinId 加载皮肤包，加载失败自动回退 default
class SkinManager {
  SkinManager._();
  static final SkinManager instance = SkinManager._();

  ThemeTokens _tokens = kDefaultThemeTokens;
  SkinPageFactory _pageFactory = DefaultPageFactory();
  String _activeSkinId = 'default';

  ThemeTokens get tokens => _tokens;
  SkinPageFactory get pageFactory => _pageFactory;
  String get activeSkinId => _activeSkinId;

  Future<void> load(String skinId) async {
    try {
      final contract = await _resolveSkin(skinId);
      _tokens = contract.themeTokens;
      _pageFactory = contract.pageFactory;
      _activeSkinId = contract.skinId;
      AppLogger.i('皮肤加载成功: $skinId', tag: LogTag.skin);
    } catch (e) {
      AppLogger.w('皮肤 $skinId 加载失败，回退到 default: $e', tag: LogTag.skin);
      _tokens = kDefaultThemeTokens;
      _pageFactory = DefaultPageFactory();
      _activeSkinId = 'default';
    }
  }

  Future<SkinContract> _resolveSkin(String skinId) async {
    return switch (skinId) {
      'default' => _DefaultSkinContract(),
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
