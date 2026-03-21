import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();
  bool _loading = false;
  bool _sendingCode = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _pwdCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = S.of(context)!.emailValidationError);
      return;
    }
    setState(() => _sendingCode = true);
    final ctrl = context.read<AuthController>();
    final ok = await ctrl.sendEmailCode(email);
    if (!mounted) return;
    setState(() {
      _sendingCode = false;
      _error = ctrl.error;
    });
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.of(context)!.emailCodeSent)));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final ctrl = context.read<AuthController>();
    final ok = await ctrl.register(
      _emailCtrl.text.trim(),
      _pwdCtrl.text,
      _codeCtrl.text.trim(),
      _inviteCtrl.text.trim().isEmpty ? null : _inviteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = ctrl.error;
    });
    if (ok) context.go('/home');
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
                Text(s.registerTitle,
                    style: TextStyle(
                        color: tokens.colorOnBackground,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(s.registerSubtitle,
                    style: TextStyle(color: tokens.colorMuted, fontSize: 14)),
                const SizedBox(height: 32),

                if (_error != null) ...[
                  _ErrorBox(message: _error!, tokens: tokens),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: TextStyle(color: tokens.colorOnSurface),
                  decoration: InputDecoration(
                    hintText: s.registerEmailHint,
                    hintStyle: TextStyle(color: tokens.colorMuted),
                    prefixIcon:
                        Icon(Icons.mail_outline, color: tokens.colorMuted),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? s.invalidEmail
                      : null,
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
                          prefixIcon:
                              Icon(Icons.pin_outlined, color: tokens.colorMuted),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? s.codeValidationError
                            : null,
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
                                    strokeWidth: 2,
                                    color: tokens.colorPrimary))
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
                    hintText: s.registerPasswordHint,
                    hintStyle: TextStyle(color: tokens.colorMuted),
                    prefixIcon:
                        Icon(Icons.lock_outline, color: tokens.colorMuted),
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
                const SizedBox(height: 12),

                TextFormField(
                  controller: _inviteCtrl,
                  style: TextStyle(color: tokens.colorOnSurface),
                  decoration: InputDecoration(
                    hintText: s.registerInviteCodeHint,
                    hintStyle: TextStyle(color: tokens.colorMuted),
                    prefixIcon:
                        Icon(Icons.card_giftcard, color: tokens.colorMuted),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: tokens.colorOnPrimary))
                        : Text(s.registerButton,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s.registerHaveAccount,
                        style:
                            TextStyle(color: tokens.colorMuted, fontSize: 13)),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(s.registerLoginLink,
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.tokens});
  final String message;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.colorError.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(tokens.radiusSmall),
        border: Border.all(color: tokens.colorError.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: tokens.colorError, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: TextStyle(color: tokens.colorError, fontSize: 13))),
        ],
      ),
    );
  }
}
