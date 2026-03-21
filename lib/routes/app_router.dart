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
import '../core/models/commercial/order.dart';
import '../features/auth/auth_use_case.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/connection/screens/home_screen.dart';
import '../features/diagnostics/screens/diagnostics_screen.dart';
import '../features/invite/screens/invite_screen.dart';
import '../features/stat/screens/traffic_chart_screen.dart';
import '../features/node/screens/node_list_screen.dart';
import '../features/order/screens/order_center_screen.dart';
import '../features/order/screens/order_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/store/screens/store_screen.dart';
import '../features/store/screens/payment_result_screen.dart';
import '../features/ticket/screens/ticket_list_screen.dart';
import '../skins/skin_manager.dart';

class AppRouter {
  static GoRouter router(AuthUseCase auth) {
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
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.splashPage(
                  ctx.read<SplashController>()) ??
              const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.loginPage(
                  ctx.read<AuthController>()) ??
              const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.registerPage(
                  ctx.read<AuthController>()) ??
              const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.forgotPasswordPage(
                  ctx.read<AuthController>()) ??
              const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.homePage(
                  ctx.read<HomeController>()) ??
              const HomeScreen(),
        ),
        GoRoute(
          path: '/nodes',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.nodePage(
                  ctx.read<NodeController>()) ??
              const NodeListScreen(),
        ),
        GoRoute(
          path: '/store',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.storePage(
                  ctx.read<StoreController>()) ??
              const StoreScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.orderCenterPage(
                  ctx.read<OrderController>()) ??
              const OrderCenterScreen(),
        ),
        GoRoute(
          path: '/orders/:tradeNo',
          builder: (_, state) => OrderDetailScreen(
            tradeNo: state.pathParameters['tradeNo']!,
          ),
        ),
        GoRoute(
          path: '/payment-result',
          builder: (_, state) => PaymentResultScreen(
            paymentResult: state.extra! as PaymentResult,
          ),
        ),
        GoRoute(
          path: '/tickets',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.ticketListPage(
                  ctx.read<TicketController>()) ??
              const TicketListScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.profilePage(
                  ctx.read<ProfileController>()) ??
              const ProfileScreen(),
        ),
        GoRoute(
          path: '/invite',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.invitePage(
                  ctx.read<ProfileController>()) ??
              const InviteScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.settingsPage(
                  ctx.read<SettingsController>()) ??
              const SettingsScreen(),
        ),
        GoRoute(
          path: '/diagnostics',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.diagnosticsPage(
                  ctx.read<DiagController>()) ??
              const DiagnosticsScreen(),
        ),
        GoRoute(
          path: '/traffic-chart',
          builder: (ctx, __) =>
              SkinManager.instance.pageFactory.trafficChartPage(
                  ctx.read<TrafficChartController>()) ??
              const TrafficChartScreen(),
        ),
      ],
    );
  }
}
