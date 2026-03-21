import 'package:flutter/widgets.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../skin_page_factory.dart';
import 'brand_x_home_page.dart';
import 'brand_x_login_page.dart';

/// Brand X 页面工厂
///
/// 覆盖 home + login 两个页面，其余使用默认实现（返回 null）
class BrandXPageFactory extends SkinPageFactory {
  @override
  Widget? homePage(HomeController c) => BrandXHomePage(controller: c);

  @override
  Widget? loginPage(AuthController c) => BrandXLoginPage(controller: c);
}
