import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 移动端注册页（Material Design）
class MobileRegisterPage extends StatefulWidget {
  final AuthController controller;

  const MobileRegisterPage({required this.controller, super.key});

  @override
  State<MobileRegisterPage> createState() => _MobileRegisterPageState();
}

class _MobileRegisterPageState extends State<MobileRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _emailCodeCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _inviteCodeCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailCodeCtrl.dispose();
    _pwdCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_emailCtrl.text.isEmpty || !_emailCtrl.text.contains('@')) {
      return;
    }
    await widget.controller.sendEmailCode(_emailCtrl.text.trim());
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await widget.controller.register(
      _emailCtrl.text.trim(),
      _pwdCtrl.text,
      _emailCodeCtrl.text.trim(),
      _inviteCodeCtrl.text.isEmpty ? null : _inviteCodeCtrl.text.trim(),
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
      appBar: AppBar(
        backgroundColor: tokens.colorBackground,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tokens.colorOnBackground),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                Text(
                  s.registerTitle,
                  style: TextStyle(
                    color: tokens.colorOnBackground,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.registerSubtitle,
                  style: TextStyle(
                    color: tokens.colorMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // 邮箱输入
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: tokens.colorOnBackground),
                  decoration: InputDecoration(
                    labelText: s.registerEmailHint,
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
                      return s.registerEmailHint;
                    }
                    if (!v.contains('@')) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 邮箱验证码
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailCodeCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: tokens.colorOnBackground),
                        decoration: InputDecoration(
                          labelText: s.registerEmailCodeHint,
                          labelStyle: TextStyle(color: tokens.colorMuted),
                          prefixIcon: Icon(Icons.verified_outlined, color: tokens.colorMuted),
                          filled: true,
                          fillColor: tokens.colorSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(tokens.radiusMedium),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return s.registerEmailCodeHint;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ListenableBuilder(
                      listenable: widget.controller,
                      builder: (context, _) {
                        final t = ThemeTokenProvider.tokensOf(context);
                        return ElevatedButton(
                          onPressed: widget.controller.isSendingCode ? null : _sendCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.colorPrimary,
                            foregroundColor: t.colorOnPrimary,
                            minimumSize: const Size(88, 52),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(t.radiusMedium),
                            ),
                          ),
                          child: widget.controller.isSendingCode
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: t.colorOnPrimary,
                                  ),
                                )
                              : Text(s.registerSendCode),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 密码输入
                TextFormField(
                  controller: _pwdCtrl,
                  obscureText: _obscure,
                  style: TextStyle(color: tokens.colorOnBackground),
                  decoration: InputDecoration(
                    labelText: s.registerPasswordHint,
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
                      return s.registerPasswordHint;
                    }
                    if (v.length < 6) {
                      return 'Password too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 邀请码（可选）
                TextFormField(
                  controller: _inviteCodeCtrl,
                  style: TextStyle(color: tokens.colorOnBackground),
                  decoration: InputDecoration(
                    labelText: s.registerInviteCodeHint,
                    labelStyle: TextStyle(color: tokens.colorMuted),
                    prefixIcon: Icon(Icons.card_giftcard_outlined, color: tokens.colorMuted),
                    filled: true,
                    fillColor: tokens.colorSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                      borderSide: BorderSide.none,
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

                // 注册按钮
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    return ElevatedButton(
                      onPressed: widget.controller.isLoading ? null : _register,
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
                              s.registerButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 登录提示
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.registerHaveAccount,
                      style: TextStyle(color: tokens.colorMuted),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        s.registerLoginLink,
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
