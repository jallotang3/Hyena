import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_use_case.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthUseCase>();
    final result = await auth.login(_emailCtrl.text.trim(), _pwdCtrl.text);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) => context.go('/home'),
      failure: (e) => setState(() => _error = e.message),
    );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  s.loginTitle,
                  style: TextStyle(
                    color: tokens.colorOnBackground,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(s.loginSubtitle,
                    style: TextStyle(color: tokens.colorMuted, fontSize: 14)),
                const SizedBox(height: 40),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.colorError.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(tokens.radiusSmall),
                      border: Border.all(
                          color: tokens.colorError.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: tokens.colorError, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: TextStyle(
                                  color: tokens.colorError, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: TextStyle(color: tokens.colorOnSurface),
                  decoration: InputDecoration(
                    hintText: s.loginEmailHint,
                    hintStyle: TextStyle(color: tokens.colorMuted),
                    prefixIcon:
                        Icon(Icons.mail_outline, color: tokens.colorMuted),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.loginEmailHint;
                    if (!v.contains('@')) return s.errorInvalidCredentials;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _pwdCtrl,
                  obscureText: _obscure,
                  style: TextStyle(color: tokens.colorOnSurface),
                  decoration: InputDecoration(
                    hintText: s.loginPasswordHint,
                    hintStyle: TextStyle(color: tokens.colorMuted),
                    prefixIcon:
                        Icon(Icons.lock_outline, color: tokens.colorMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: tokens.colorMuted),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.loginPasswordHint;
                    return null;
                  },
                  onFieldSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(s.loginForgotPassword,
                        style:
                            TextStyle(color: tokens.colorMuted, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tokens.colorOnPrimary,
                            ),
                          )
                        : Text(s.loginButton,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s.loginRegisterPrompt,
                        style:
                            TextStyle(color: tokens.colorMuted, fontSize: 13)),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text(s.loginRegisterLink,
                          style: TextStyle(
                              color: tokens.colorPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
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
