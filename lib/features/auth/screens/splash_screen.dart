import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/splash_controller.dart';
import '../../../skins/theme_token_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final ctrl = context.read<SplashController>();
    await ctrl.initialize();

    if (!mounted) return;
    final target = ctrl.shouldNavigateTo ?? '/login';
    context.go(target);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: tokens.colorPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(tokens.radiusLarge),
                  border: Border.all(color: tokens.colorPrimary, width: 1.5),
                ),
                child: Icon(Icons.shield_outlined,
                    color: tokens.colorPrimary, size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                'HYENA VPN',
                style: TextStyle(
                  color: tokens.colorOnBackground,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fast. Private. Yours.',
                style: TextStyle(
                  color: tokens.colorMuted,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.colorPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
