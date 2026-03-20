import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_notifier.dart';
import 'features/auth/auth_use_case.dart';
import 'l10n/app_localizations.dart';
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
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          );
        },
      ),
    );
  }
}
