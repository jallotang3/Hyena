import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_notifier.dart';
import 'features/settings/locale_notifier.dart';
import 'l10n/app_localizations.dart';
import 'skins/skin_manager.dart';
import 'skins/theme_token_provider.dart';
import 'routes/app_router.dart';

class HyenaApp extends StatelessWidget {
  const HyenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = SkinManager.instance.tokens;
    final tokenProvider = ThemeTokenProvider(
      tokens: tokens,
      child: const SizedBox.shrink(),
    );

    return ThemeTokenProvider(
      tokens: tokens,
      child: Consumer2<AuthNotifier, LocaleNotifier>(
        builder: (context, authNotifier, localeNotifier, _) {
          return MaterialApp.router(
            title: 'HyenaVPN',
            debugShowCheckedModeBanner: false,
            theme: tokenProvider.toMaterialTheme(),
            routerConfig: AppRouter.router(authNotifier),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: localeNotifier.locale,
          );
        },
      ),
    );
  }
}
