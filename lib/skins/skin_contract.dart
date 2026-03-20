import 'skin_page_factory.dart';
import 'theme_token_provider.dart';

/// 皮肤合约接口 — 每个皮肤包必须实现此接口
abstract class SkinContract {
  String get contractVersion;
  String get skinId;
  ThemeTokens get themeTokens;
  SkinPageFactory get pageFactory;
}
