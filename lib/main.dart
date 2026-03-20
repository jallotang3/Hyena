import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'core/models/panel_site.dart';
import 'infrastructure/storage/preferences.dart';
import 'infrastructure/storage/secure_storage.dart';
import 'infrastructure/logging/app_logger.dart';
import 'adapters/panel/registry.dart';
import 'adapters/panel/xboard/xboard_adapter.dart';
import 'adapters/engine/registry.dart';
import 'adapters/engine/singbox/singbox_driver.dart';
import 'features/auth/auth_notifier.dart';
import 'features/auth/auth_use_case.dart';
import 'features/connection/connection_notifier.dart';
import 'features/connection/connection_use_case.dart';
import 'skins/skin_manager.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const isDev = !bool.fromEnvironment('dart.vm.product');
  AppLogger.setVerbose(isDev);
  AppLogger.i('Hyena ${AppConfig.appVersion} starting…', tag: LogTag.general);

  await AppPreferences.init();

  final skinId = AppPreferences.instance.skinId ?? AppConfig.skinId;
  await SkinManager.instance.load(skinId);

  final adapterRegistry = PanelAdapterRegistry.instance;
  adapterRegistry.register(XboardAdapter());

  final engineRegistry = EngineRegistry.instance;
  final singboxDriver = SingboxDriver();
  engineRegistry.register(singboxDriver);

  final site = PanelSite.fromBuildConfig();
  final adapter = adapterRegistry.resolve(site.panelType);

  final authUseCase = AuthUseCase(
    adapter: adapter,
    site: site,
    storage: SecureStorage.instance,
  );
  final connectionUseCase = ConnectionUseCase(engine: singboxDriver);
  await connectionUseCase.initialize();

  AppLogger.i('Site: ${site.panelType} @ ${site.baseUrl}', tag: LogTag.general);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthNotifier(authUseCase)),
        ChangeNotifierProvider(
            create: (_) => ConnectionNotifier(connectionUseCase)),
        Provider<AuthUseCase>.value(value: authUseCase),
        Provider<ConnectionUseCase>.value(value: connectionUseCase),
      ],
      child: const HyenaApp(),
    ),
  );
}
