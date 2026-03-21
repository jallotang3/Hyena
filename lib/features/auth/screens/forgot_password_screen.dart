import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  bool _sendingCode = false;
  bool _obscure = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = S.of(context)!.emailValidationError);
      return;
    }
    setState(() {
      _sendingCode = true;
      _error = null;
    });
    final ctrl = context.read<AuthController>();
    final ok = await ctrl.sendEmailCode(email);
    if (!mounted) return;
    setState(() {
      _sendingCode = false;
      _error = ctrl.error;
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context)!.resetCodeSent)));
    }
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final ctrl = context.read<AuthController>();
    final ok = await ctrl.resetPassword(
      _emailCtrl.text.trim(),
      _codeCtrl.text.trim(),
      _pwdCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = ctrl.error;
    });
    if (ok) {
      setState(() => _success = S.of(context)!.resetPasswordSuccess);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go('/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: tokens.colorOnBackground),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.forgotPasswordTitle,
                    style: TextStyle(
                        color: tokens.colorOnBackground,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(s.forgotPasswordSubtitle,
                    style: TextStyle(color: tokens.colorMuted, fontSize: 13)),
                const SizedBox(height: 32),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.colorError.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(tokens.radiusSmall),
                      border: Border.all(color: tokens.colorError.withValues(alpha: 0.4)),
                    ),
                    child: Text(_error!,
                        style: TextStyle(color: tokens.colorError, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_success != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.colorSuccess.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(tokens.radiusSmall),
                    ),
                    child: Text(_success!,
                        style: TextStyle(color: tokens.colorSuccess, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: TextStyle(color: tokens.colorOnSurface),
                  decoration: InputDecoration(
                    hintText: s.loginEmailHint,
                    hintStyle: TextStyle(color: tokens.colorMuted),
                    prefixIcon: Icon(Icons.mail_outline, color: tokens.colorMuted),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? s.invalidEmail : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codeCtrl,
                        style: TextStyle(color: tokens.colorOnSurface),
                        decoration: InputDecoration(
                          hintText: s.registerEmailCodeHint,
                          hintStyle: TextStyle(color: tokens.colorMuted),
                          prefixIcon: Icon(Icons.pin_outlined, color: tokens.colorMuted),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? s.codeValidationError : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _sendingCode ? null : _sendCode,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: tokens.colorPrimary),
                          foregroundColor: tokens.colorPrimary,
                        ),
                        child: _sendingCode
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: tokens.colorPrimary))
                            : Text(s.sendCode),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _pwdCtrl,
                  obscureText: _obscure,
                  style: TextStyle(color: tokens.colorOnSurface),
                  decoration: InputDecoration(
                    hintText: s.newPassword,
                    hintStyle: TextStyle(color: tokens.colorMuted),
                    prefixIcon: Icon(Icons.lock_outline, color: tokens.colorMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: tokens.colorMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? s.minChars : null,
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _reset,
                    child: _loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: tokens.colorOnPrimary))
                        : Text(s.forgotPasswordButton,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
