import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/home_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/node_controller.dart';
import '../controllers/store_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/ticket_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/diag_controller.dart';
import '../controllers/traffic_chart_controller.dart';
import '../controllers/splash_controller.dart';
import '../features/auth/auth_notifier.dart';
import '../skins/skin_manager.dart';
import '../platforms/mobile/widgets/mobile_shell.dart';

// PaymentResult 类型定义
class PaymentResult {
  final String tradeNo;
  final bool success;

  PaymentResult({required this.tradeNo, required this.success});
}

/// 应用路由配置
///
/// 架构说明：
/// 1. 优先使用 PlatformPageFactory（处理平台差异）
/// 2. 其次使用 SkinPageFactory（可选品牌定制）
/// 3. 最后回退到默认 Screen 实现
class AppRouter {
  static GoRouter router(AuthNotifier auth) {
    final platformFactory = SkinManager.instance.platformFactory;
    final skinFactory = SkinManager.instance.pageFactory;

    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = auth.isLoggedIn;
        final loc = state.matchedLocation;
        final isAuthRoute = loc == '/login' ||
            loc == '/register' ||
            loc == '/forgot-password' ||
            loc == '/splash';
        if (!isLoggedIn && !isAuthRoute) return '/login';
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (ctx, __) {
            final controller = ctx.read<SplashController>();
            final skinPage = skinFactory.splashPage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildSplashPage(controller);
          },
        ),
        GoRoute(
          path: '/login',
          builder: (ctx, __) {
            final controller = ctx.read<AuthController>();
            final skinPage = skinFactory.loginPage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildLoginPage(controller);
          },
        ),
        GoRoute(
          path: '/register',
          builder: (ctx, __) {
            final controller = ctx.read<AuthController>();
            final skinPage = skinFactory.registerPage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildRegisterPage(controller);
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (ctx, __) {
            final controller = ctx.read<AuthController>();
            final skinPage = skinFactory.forgotPasswordPage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildForgotPasswordPage(controller);
          },
        ),

        // ── 主 Tab Shell（持久化底部导航栏）──
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MobileShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                builder: (ctx, __) {
                  final controller = ctx.read<HomeController>();
                  final skinPage = skinFactory.homePage(controller);
                  if (skinPage != null) return skinPage;
                  return platformFactory.buildHomePage(controller);
                },
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/nodes',
                builder: (ctx, __) {
                  final controller = ctx.read<NodeController>();
                  final skinPage = skinFactory.nodePage(controller);
                  if (skinPage != null) return skinPage;
                  return platformFactory.buildNodeListPage(controller);
                },
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/store',
                builder: (ctx, __) {
                  final controller = ctx.read<StoreController>();
                  final skinPage = skinFactory.storePage(controller);
                  if (skinPage != null) return skinPage;
                  return platformFactory.buildStorePage(controller);
                },
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/profile',
                builder: (ctx, __) {
                  final controller = ctx.read<ProfileController>();
                  final skinPage = skinFactory.profilePage(controller);
                  if (skinPage != null) return skinPage;
                  return platformFactory.buildProfilePage(controller);
                },
              ),
            ]),
          ],
        ),

        GoRoute(
          path: '/orders',
          builder: (ctx, __) {
            final controller = ctx.read<OrderController>();
            final skinPage = skinFactory.orderCenterPage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildOrderCenterPage(controller);
          },
        ),
        GoRoute(
          path: '/orders/:tradeNo',
          builder: (ctx, state) {
            final tradeNo = state.pathParameters['tradeNo']!;
            final controller = ctx.read<OrderController>();
            final skinPage = skinFactory.orderDetailPage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildOrderDetailPage(controller, tradeNo);
          },
        ),
        GoRoute(
          path: '/payment-result',
          builder: (ctx, state) {
            final pr = state.extra! as PaymentResult;
            final controller = ctx.read<OrderController>();
            final skinPage = skinFactory.paymentResultPage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildPaymentResultPage(controller, pr.tradeNo);
          },
        ),
        GoRoute(
          path: '/tickets',
          builder: (ctx, __) {
            final controller = ctx.read<TicketController>();
            final skinPage = skinFactory.ticketListPage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildTicketListPage(controller);
          },
        ),
        GoRoute(
          path: '/tickets/:id',
          builder: (ctx, state) {
            final id = int.parse(state.pathParameters['id']!);
            final controller = ctx.read<TicketController>();
            return platformFactory.buildTicketDetailPage(controller, id);
          },
        ),
        GoRoute(
          path: '/invite',
          builder: (ctx, __) {
            final controller = ctx.read<ProfileController>();
            final skinPage = skinFactory.invitePage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildInvitePage(controller);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (ctx, __) {
            final controller = ctx.read<SettingsController>();
            final skinPage = skinFactory.settingsPage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildSettingsPage(controller);
          },
        ),
        GoRoute(
          path: '/diagnostics',
          builder: (ctx, __) {
            final controller = ctx.read<DiagController>();
            final skinPage = skinFactory.diagnosticsPage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildDiagnosticsPage(controller);
          },
        ),
        GoRoute(
          path: '/traffic-chart',
          builder: (ctx, __) {
            final controller = ctx.read<TrafficChartController>();
            final skinPage = skinFactory.trafficChartPage(controller);
            if (skinPage != null) return skinPage;
            return platformFactory.buildTrafficChartPage(controller);
          },
        ),
      ],
    );
  }
}
