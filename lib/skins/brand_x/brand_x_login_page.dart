import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme_token_provider.dart';

/// Brand X 自定义登录页 — 温暖出行风格
///
/// 特点：
/// - 渐变品牌 Banner（橙色波浪）
/// - 圆角卡片表单
/// - 暖橙 CTA 按钮
/// - 仅通过 AuthController 交互，不直接访问 UseCase/Storage
class BrandXLoginPage extends StatelessWidget {
  const BrandXLoginPage({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: const _BrandXLoginView(),
    );
  }
}

class _BrandXLoginView extends StatefulWidget {
  const _BrandXLoginView();

  @override
  State<_BrandXLoginView> createState() => _BrandXLoginViewState();
}

class _BrandXLoginViewState extends State<_BrandXLoginView> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AuthController>();
    final s = S.of(context)!;
    final tokens = ThemeTokenProvider.tokensOf(context);

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _BrandXLoginHeader(tokens: tokens, s: s)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 32),
                _FormCard(
                  tokens: tokens,
                  s: s,
                  emailCtrl: _emailCtrl,
                  pwdCtrl: _pwdCtrl,
                  obscure: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                ),
                const SizedBox(height: 20),
                _LoginButton(
                  tokens: tokens,
                  s: s,
                  controller: c,
                  onTap: () => c.login(
                    _emailCtrl.text.trim(),
                    _pwdCtrl.text,
                  ),
                ),
                const SizedBox(height: 16),
                _FooterLinks(tokens: tokens, s: s),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandXLoginHeader extends StatelessWidget {
  const _BrandXLoginHeader({required this.tokens, required this.s});

  final ThemeTokens tokens;
  final S s;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.colorPrimary,
            tokens.colorPrimary.withRed(
              (tokens.colorPrimary.r * 0.8).round(),
            ),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.public,
                  color: tokens.colorOnPrimary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.appName,
                style: TextStyle(
                  color: tokens.colorOnPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.splashTagline,
                style: TextStyle(
                  color: tokens.colorOnPrimary.withAlpha(200),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.tokens,
    required this.s,
    required this.emailCtrl,
    required this.pwdCtrl,
    required this.obscure,
    required this.onToggleObscure,
  });

  final ThemeTokens tokens;
  final S s;
  final TextEditingController emailCtrl;
  final TextEditingController pwdCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.loginEmailHint,
            style: TextStyle(
              color: tokens.colorOnSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _TextField(
            controller: emailCtrl,
            tokens: tokens,
            hint: s.loginEmailHint,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Text(
            s.loginPasswordHint,
            style: TextStyle(
              color: tokens.colorOnSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _TextField(
            controller: pwdCtrl,
            tokens: tokens,
            hint: s.loginPasswordHint,
            obscure: obscure,
            suffix: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: tokens.colorMuted,
                size: 18,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.tokens,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });

  final TextEditingController controller;
  final ThemeTokens tokens;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TextStyle(color: tokens.colorOnSurface, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: tokens.colorMuted, fontSize: 14),
        suffixIcon: suffix,
        filled: true,
        fillColor: tokens.colorSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          borderSide:
              BorderSide(color: tokens.colorPrimary.withAlpha(120), width: 1.5),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.tokens,
    required this.s,
    required this.controller,
    required this.onTap,
  });

  final ThemeTokens tokens;
  final S s;
  final AuthController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLoading = controller.isLoading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.colorPrimary,
          foregroundColor: tokens.colorOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.colorOnPrimary,
                ),
              )
            : Text(
                s.loginButton,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks({required this.tokens, required this.s});

  final ThemeTokens tokens;
  final S s;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          s.loginRegisterPrompt,
          style: TextStyle(color: tokens.colorMuted, fontSize: 13),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/register'),
          child: Text(
            s.loginRegisterLink,
            style: TextStyle(
              color: tokens.colorPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/forgot-password'),
          child: Text(
            s.loginForgotPassword,
            style: TextStyle(
              color: tokens.colorMuted,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
