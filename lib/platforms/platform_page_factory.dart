import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/home_controller.dart';
import '../controllers/node_controller.dart';
import '../controllers/store_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/ticket_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/splash_controller.dart';
import '../controllers/diag_controller.dart';
import '../controllers/traffic_chart_controller.dart';
import 'mobile/pages/home_page.dart';
import 'mobile/pages/node_list_page.dart';
import 'mobile/pages/settings_page.dart';
import 'mobile/pages/profile_page.dart';
import 'mobile/pages/store_page.dart';
import 'mobile/pages/order_center_page.dart';
import 'mobile/pages/ticket_list_page.dart';
import 'mobile/pages/ticket_detail_page.dart';
import 'mobile/pages/login_page.dart';
import 'mobile/pages/register_page.dart';
import '../features/auth/screens/splash_screen.dart';

/// 平台类型枚举
enum PlatformType {
  mobile,    // Android + iOS (Material Design)
  desktop,   // Windows + macOS + Linux
  ios,       // iOS (Cupertino) - 可选专属实现
}

/// 平台页面工厂抽象接口
///
/// 负责根据不同平台创建对应的页面实现
/// - 移动端：Material Design，垂直布局，底部导航
/// - 桌面端：侧边栏布局，水平分栏，标题栏
/// - iOS：Cupertino 风格（可选）
abstract class PlatformPageFactory {
  /// 根据当前运行平台自动选择合适的工厂实现
  static PlatformPageFactory create() {
    if (kIsWeb) {
      return DesktopPageFactory();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return MobilePageFactory();
      case TargetPlatform.iOS:
        // 可选：使用专门的 iOS Cupertino 工厂
        // 或者复用 MobilePageFactory（Material Design）
        return MobilePageFactory(); // 默认使用 Material
        // return IosPageFactory(); // 如需 Cupertino 风格，取消注释
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return DesktopPageFactory();
      default:
        return MobilePageFactory();
    }
  }

  /// 获取当前平台类型
  PlatformType get platformType;

  // ── 核心页面构建方法 ────────────────────────────────────────────────────

  /// 启动页
  Widget buildSplashPage(SplashController controller);

  /// 登录页
  Widget buildLoginPage(AuthController controller);

  /// 注册页
  Widget buildRegisterPage(AuthController controller);

  /// 忘记密码页
  Widget buildForgotPasswordPage(AuthController controller);

  /// 首页（连接状态、流量、当前节点）
  Widget buildHomePage(HomeController controller);

  /// 节点列表页
  Widget buildNodeListPage(NodeController controller);

  /// 商店页（套餐列表）
  Widget buildStorePage(StoreController controller);

  /// 支付结果页
  Widget buildPaymentResultPage(OrderController controller, String tradeNo);

  /// 订单中心页
  Widget buildOrderCenterPage(OrderController controller);

  /// 订单详情页
  Widget buildOrderDetailPage(OrderController controller, String tradeNo);

  /// 工单列表页
  Widget buildTicketListPage(TicketController controller);

  /// 工单详情页
  Widget buildTicketDetailPage(TicketController controller, int ticketId);

  /// 个人中心页
  Widget buildProfilePage(ProfileController controller);

  /// 邀请页
  Widget buildInvitePage(ProfileController controller);

  /// 设置页
  Widget buildSettingsPage(SettingsController controller);

  /// 诊断页
  Widget buildDiagnosticsPage(DiagController controller);

  /// 流量图表页
  Widget buildTrafficChartPage(TrafficChartController controller);
}

/// 移动端页面工厂（Material Design）
///
/// 特点：
/// - 垂直布局
/// - 底部导航栏
/// - AppBar 标题栏
/// - 适合小屏幕
class MobilePageFactory extends PlatformPageFactory {
  @override
  PlatformType get platformType => PlatformType.mobile;

  @override
  Widget buildSplashPage(SplashController controller) {
    return const SplashScreen();
  }

  @override
  Widget buildLoginPage(AuthController controller) {
    return MobileLoginPage(controller: controller);
  }

  @override
  Widget buildRegisterPage(AuthController controller) {
    return MobileRegisterPage(controller: controller);
  }

  @override
  Widget buildForgotPasswordPage(AuthController controller) {
    // TODO: 实现移动端忘记密码页
    return _placeholder('Mobile Forgot Password Page');
  }

  @override
  Widget buildHomePage(HomeController controller) {
    // 使用实际的移动端首页实现
    return MobileHomePage(controller: controller);
  }

  @override
  Widget buildNodeListPage(NodeController controller) {
    // 使用实际的移动端节点列表页实现
    return MobileNodeListPage(controller: controller);
  }

  @override
  Widget buildStorePage(StoreController controller) {
    // 使用实际的移动端商店页实现
    return MobileStorePage(controller: controller);
  }

  @override
  Widget buildPaymentResultPage(OrderController controller, String tradeNo) {
    // TODO: 实现移动端支付结果页
    return _placeholder('Mobile Payment Result Page');
  }

  @override
  Widget buildOrderCenterPage(OrderController controller) {
    // 使用实际的移动端订单中心页实现
    return MobileOrderCenterPage(controller: controller);
  }

  @override
  Widget buildOrderDetailPage(OrderController controller, String tradeNo) {
    // TODO: 实现移动端订单详情页
    return _placeholder('Mobile Order Detail Page');
  }

  @override
  Widget buildTicketListPage(TicketController controller) {
    // 使用实际的移动端工单列表页实现
    return MobileTicketListPage(controller: controller);
  }

  @override
  Widget buildTicketDetailPage(TicketController controller, int ticketId) {
    return MobileTicketDetailPage(controller: controller, ticketId: ticketId);
  }

  @override
  Widget buildProfilePage(ProfileController controller) {
    // 使用实际的移动端个人中心页实现
    return MobileProfilePage(controller: controller);
  }

  @override
  Widget buildInvitePage(ProfileController controller) {
    // TODO: 实现移动端邀请页
    return _placeholder('Mobile Invite Page');
  }

  @override
  Widget buildSettingsPage(SettingsController controller) {
    // 使用实际的移动端设置页实现
    return MobileSettingsPage(controller: controller);
  }

  @override
  Widget buildDiagnosticsPage(DiagController controller) {
    // TODO: 实现移动端诊断页
    return _placeholder('Mobile Diagnostics Page');
  }

  @override
  Widget buildTrafficChartPage(TrafficChartController controller) {
    // TODO: 实现移动端流量图表页
    return _placeholder('Mobile Traffic Chart Page');
  }

  Widget _placeholder(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_android, size: 64),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            const Text('移动端实现（Material Design）'),
          ],
        ),
      ),
    );
  }
}

/// 桌面端页面工厂
///
/// 特点：
/// - 侧边栏导航
/// - 水平分栏布局
/// - 自定义标题栏
/// - 适合大屏幕
class DesktopPageFactory extends PlatformPageFactory {
  @override
  PlatformType get platformType => PlatformType.desktop;

  @override
  Widget buildSplashPage(SplashController controller) {
    // TODO: 实现桌面端启动页
    return _placeholder('Desktop Splash Page');
  }

  @override
  Widget buildLoginPage(AuthController controller) {
    // TODO: 实现桌面端登录页
    return _placeholder('Desktop Login Page');
  }

  @override
  Widget buildRegisterPage(AuthController controller) {
    // TODO: 实现桌面端注册页
    return _placeholder('Desktop Register Page');
  }

  @override
  Widget buildForgotPasswordPage(AuthController controller) {
    // TODO: 实现桌面端忘记密码页
    return _placeholder('Desktop Forgot Password Page');
  }

  @override
  Widget buildHomePage(HomeController controller) {
    // TODO: 实现桌面端首页
    return _placeholder('Desktop Home Page');
  }

  @override
  Widget buildNodeListPage(NodeController controller) {
    // TODO: 实现桌面端节点列表页
    return _placeholder('Desktop Node List Page');
  }

  @override
  Widget buildStorePage(StoreController controller) {
    // TODO: 实现桌面端商店页
    return _placeholder('Desktop Store Page');
  }

  @override
  Widget buildPaymentResultPage(OrderController controller, String tradeNo) {
    // TODO: 实现桌面端支付结果页
    return _placeholder('Desktop Payment Result Page');
  }

  @override
  Widget buildOrderCenterPage(OrderController controller) {
    // TODO: 实现桌面端订单中心页
    return _placeholder('Desktop Order Center Page');
  }

  @override
  Widget buildOrderDetailPage(OrderController controller, String tradeNo) {
    // TODO: 实现桌面端订单详情页
    return _placeholder('Desktop Order Detail Page');
  }

  @override
  Widget buildTicketListPage(TicketController controller) {
    // TODO: 实现桌面端工单列表页
    return _placeholder('Desktop Ticket List Page');
  }

  @override
  Widget buildTicketDetailPage(TicketController controller, int ticketId) {
    // TODO: 实现桌面端工单详情页
    return _placeholder('Desktop Ticket Detail Page');
  }

  @override
  Widget buildProfilePage(ProfileController controller) {
    // TODO: 实现桌面端个人中心页
    return _placeholder('Desktop Profile Page');
  }

  @override
  Widget buildInvitePage(ProfileController controller) {
    // TODO: 实现桌面端邀请页
    return _placeholder('Desktop Invite Page');
  }

  @override
  Widget buildSettingsPage(SettingsController controller) {
    // TODO: 实现桌面端设置页
    return _placeholder('Desktop Settings Page');
  }

  @override
  Widget buildDiagnosticsPage(DiagController controller) {
    // TODO: 实现桌面端诊断页
    return _placeholder('Desktop Diagnostics Page');
  }

  @override
  Widget buildTrafficChartPage(TrafficChartController controller) {
    // TODO: 实现桌面端流量图表页
    return _placeholder('Desktop Traffic Chart Page');
  }

  Widget _placeholder(String title) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧边栏
          Container(
            width: 200,
            color: Colors.grey[900],
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Hyena',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.white),
                  title: const Text('首页', style: TextStyle(color: Colors.white)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.dns, color: Colors.white),
                  title: const Text('节点', style: TextStyle(color: Colors.white)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.white),
                  title: const Text('设置', style: TextStyle(color: Colors.white)),
                  onTap: () {},
                ),
              ],
            ),
          ),
          // 右侧内容区
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.desktop_windows, size: 64),
                  const SizedBox(height: 16),
                  Text(title, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  const Text('桌面端实现（侧边栏布局）'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS 专属页面工厂（Cupertino 风格）
///
/// 特点：
/// - Cupertino 组件
/// - iOS 原生交互
/// - 底部 Tab Bar
/// - 适合 iOS 用户习惯
///
/// 注意：这是可选实现，如果不需要 iOS 专属体验，
/// 可以直接使用 MobilePageFactory
class IosPageFactory extends PlatformPageFactory {
  @override
  PlatformType get platformType => PlatformType.ios;

  @override
  Widget buildSplashPage(SplashController controller) {
    // TODO: 实现 iOS 启动页
    return _placeholder('iOS Splash Page');
  }

  @override
  Widget buildLoginPage(AuthController controller) {
    // TODO: 实现 iOS 登录页
    return _placeholder('iOS Login Page');
  }

  @override
  Widget buildRegisterPage(AuthController controller) {
    // TODO: 实现 iOS 注册页
    return _placeholder('iOS Register Page');
  }

  @override
  Widget buildForgotPasswordPage(AuthController controller) {
    // TODO: 实现 iOS 忘记密码页
    return _placeholder('iOS Forgot Password Page');
  }

  @override
  Widget buildHomePage(HomeController controller) {
    // TODO: 实现 iOS 首页
    return _placeholder('iOS Home Page');
  }

  @override
  Widget buildNodeListPage(NodeController controller) {
    // TODO: 实现 iOS 节点列表页
    return _placeholder('iOS Node List Page');
  }

  @override
  Widget buildStorePage(StoreController controller) {
    // TODO: 实现 iOS 商店页
    return _placeholder('iOS Store Page');
  }

  @override
  Widget buildPaymentResultPage(OrderController controller, String tradeNo) {
    // TODO: 实现 iOS 支付结果页
    return _placeholder('iOS Payment Result Page');
  }

  @override
  Widget buildOrderCenterPage(OrderController controller) {
    // TODO: 实现 iOS 订单中心页
    return _placeholder('iOS Order Center Page');
  }

  @override
  Widget buildOrderDetailPage(OrderController controller, String tradeNo) {
    // TODO: 实现 iOS 订单详情页
    return _placeholder('iOS Order Detail Page');
  }

  @override
  Widget buildTicketListPage(TicketController controller) {
    // TODO: 实现 iOS 工单列表页
    return _placeholder('iOS Ticket List Page');
  }

  @override
  Widget buildTicketDetailPage(TicketController controller, int ticketId) {
    // TODO: 实现 iOS 工单详情页
    return _placeholder('iOS Ticket Detail Page');
  }

  @override
  Widget buildProfilePage(ProfileController controller) {
    // TODO: 实现 iOS 个人中心页
    return _placeholder('iOS Profile Page');
  }

  @override
  Widget buildInvitePage(ProfileController controller) {
    // TODO: 实现 iOS 邀请页
    return _placeholder('iOS Invite Page');
  }

  @override
  Widget buildSettingsPage(SettingsController controller) {
    // TODO: 实现 iOS 设置页
    return _placeholder('iOS Settings Page');
  }

  @override
  Widget buildDiagnosticsPage(DiagController controller) {
    // TODO: 实现 iOS 诊断页
    return _placeholder('iOS Diagnostics Page');
  }

  @override
  Widget buildTrafficChartPage(TrafficChartController controller) {
    // TODO: 实现 iOS 流量图表页
    return _placeholder('iOS Traffic Chart Page');
  }

  Widget _placeholder(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple, size: 64),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            const Text('iOS 实现（Cupertino 风格）'),
          ],
        ),
      ),
    );
  }
}
