import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_use_case.dart';
import '../../../core/interfaces/panel_adapter.dart';
import '../../../core/result.dart';
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
      setState(() => _error = 'Enter a valid email first');
      return;
    }
    setState(() => _sendingCode = true);
    final auth = context.read<AuthUseCase>();
    final result = await auth.sendEmailCode(email);
    if (!mounted) return;
    setState(() {
      _sendingCode = false;
      _error = result.isFailure ? (result as Failure).error.message : null;
    });
    if (result.isSuccess) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Verification code sent!')));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthUseCase>();
    final result = await auth.register(RegisterCredentials(
      email: _emailCtrl.text.trim(),
      password: _pwdCtrl.text,
      emailCode: _codeCtrl.text.trim(),
      inviteCode:
          _inviteCtrl.text.trim().isEmpty ? null : _inviteCtrl.text.trim(),
    ));
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
                Text('CREATE ACCOUNT',
                    style: TextStyle(
                        color: tokens.colorOnBackground,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('Join today',
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
                    hintText: 'Email address',
                    hintStyle: TextStyle(color: tokens.colorMuted),
                    prefixIcon:
                        Icon(Icons.mail_outline, color: tokens.colorMuted),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Invalid email'
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
                          hintText: 'Verification code',
                          hintStyle: TextStyle(color: tokens.colorMuted),
                          prefixIcon:
                              Icon(Icons.pin_outlined, color: tokens.colorMuted),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter code'
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
                            : const Text('SEND'),
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
                    hintText: 'Password',
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
                      (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _inviteCtrl,
                  style: TextStyle(color: tokens.colorOnSurface),
                  decoration: InputDecoration(
                    hintText: 'Invite code (optional)',
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
                        : const Text('REGISTER',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?',
                        style:
                            TextStyle(color: tokens.colorMuted, fontSize: 13)),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text('Sign in',
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
        color: tokens.colorError.withOpacity(0.12),
        borderRadius: BorderRadius.circular(tokens.radiusSmall),
        border: Border.all(color: tokens.colorError.withOpacity(0.4)),
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
