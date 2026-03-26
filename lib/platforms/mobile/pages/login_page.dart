import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 移动端登录页（Material Design）
class MobileLoginPage extends StatefulWidget {
  final AuthController controller;

  const MobileLoginPage({required this.controller, super.key});

  @override
  State<MobileLoginPage> createState() => _MobileLoginPageState();
}

class _MobileLoginPageState extends State<MobileLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await widget.controller.login(
      _emailCtrl.text.trim(),
      _pwdCtrl.text,
    );

    if (ok && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: tokens.colorPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.vpn_key,
                      size: 40,
                      color: tokens.colorPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 标题
                Text(
                  s.loginTitle,
                  style: TextStyle(
                    color: tokens.colorOnBackground,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  s.loginSubtitle,
                  style: TextStyle(
                    color: tokens.colorMuted,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // 邮箱输入
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: tokens.colorOnBackground),
                  decoration: InputDecoration(
                    labelText: s.loginEmailHint,
                    labelStyle: TextStyle(color: tokens.colorMuted),
                    prefixIcon: Icon(Icons.email_outlined, color: tokens.colorMuted),
                    filled: true,
                    fillColor: tokens.colorSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return s.loginEmailHint;
                    }
                    if (!v.contains('@')) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 密码输入
                TextFormField(
                  controller: _pwdCtrl,
                  obscureText: _obscure,
                  style: TextStyle(color: tokens.colorOnBackground),
                  decoration: InputDecoration(
                    labelText: s.loginPasswordHint,
                    labelStyle: TextStyle(color: tokens.colorMuted),
                    prefixIcon: Icon(Icons.lock_outline, color: tokens.colorMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: tokens.colorMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    filled: true,
                    fillColor: tokens.colorSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return s.loginPasswordHint;
                    }
                    if (v.length < 6) {
                      return 'Password too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 忘记密码
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      s.loginForgotPassword,
                      style: TextStyle(color: tokens.colorPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 错误提示
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    if (widget.controller.error != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: tokens.colorError.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(tokens.radiusSmall),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: tokens.colorError, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.controller.error!,
                                style: TextStyle(color: tokens.colorError, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // 登录按钮
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    return ElevatedButton(
                      onPressed: widget.controller.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.colorPrimary,
                        foregroundColor: tokens.colorOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMedium),
                        ),
                      ),
                      child: widget.controller.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: tokens.colorOnPrimary,
                              ),
                            )
                          : Text(
                              s.loginButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 注册提示
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.loginRegisterPrompt,
                      style: TextStyle(color: tokens.colorMuted),
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text(
                        s.loginRegisterLink,
                        style: TextStyle(
                          color: tokens.colorPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
