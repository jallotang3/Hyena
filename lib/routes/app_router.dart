import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_use_case.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/connection/screens/home_screen.dart';
import '../features/invite/screens/invite_screen.dart';
import '../features/node/screens/node_list_screen.dart';
import '../features/order/screens/order_center_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/store/screens/store_screen.dart';
import '../features/ticket/screens/ticket_list_screen.dart';

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
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(
            path: '/forgot-password',
            builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/nodes', builder: (_, __) => const NodeListScreen()),
        GoRoute(path: '/store', builder: (_, __) => const StoreScreen()),
        GoRoute(path: '/orders', builder: (_, __) => const OrderCenterScreen()),
        GoRoute(
            path: '/tickets', builder: (_, __) => const TicketListScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/invite', builder: (_, __) => const InviteScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(
            path: '/diagnostics',
            builder: (_, __) =>
                const _PlaceholderScreen('Diagnostics — P3')),
      ],
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(child: Text(name)),
    );
  }
}
