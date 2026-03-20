import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_notifier.dart';
import 'features/auth/auth_use_case.dart';
import 'skins/skin_manager.dart';
import 'skins/theme_token_provider.dart';
import 'routes/app_router.dart';

class HyenaApp extends StatelessWidget {
  const HyenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = SkinManager.instance.tokens;
    final dummyProvider = ThemeTokenProvider(
      tokens: tokens,
      child: const SizedBox.shrink(),
    );

    return ThemeTokenProvider(
      tokens: tokens,
      child: Consumer<AuthNotifier>(
        builder: (context, authNotifier, _) {
          final auth = context.read<AuthUseCase>();
          return MaterialApp.router(
            title: 'HyenaVPN',
            debugShowCheckedModeBanner: false,
            theme: dummyProvider.toMaterialTheme(),
            routerConfig: AppRouter.router(auth),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('zh', 'CN'),
            ],
          );
        },
      ),
    );
  }
}
