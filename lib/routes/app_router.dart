import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_use_case.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/connection/screens/home_screen.dart';

class AppRouter {
  static GoRouter router(AuthUseCase auth) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = auth.isLoggedIn;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password' ||
            state.matchedLocation == '/splash';

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
        // P2 页面（占位，后续实现）
        GoRoute(
            path: '/nodes',
            builder: (_, __) => const _PlaceholderScreen('Nodes')),
        GoRoute(
            path: '/store',
            builder: (_, __) => const _PlaceholderScreen('Store')),
        GoRoute(
            path: '/orders',
            builder: (_, __) => const _PlaceholderScreen('Orders')),
        GoRoute(
            path: '/tickets',
            builder: (_, __) => const _PlaceholderScreen('Tickets')),
        GoRoute(
            path: '/profile',
            builder: (_, __) => const _PlaceholderScreen('Profile')),
        GoRoute(
            path: '/invite',
            builder: (_, __) => const _PlaceholderScreen('Invite')),
        GoRoute(
            path: '/settings',
            builder: (_, __) => const _PlaceholderScreen('Settings')),
        GoRoute(
            path: '/diagnostics',
            builder: (_, __) => const _PlaceholderScreen('Diagnostics')),
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
      body: Center(child: Text('$name — Coming in P2')),
    );
  }
}
