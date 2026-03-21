import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'core/models/panel_site.dart';
import 'infrastructure/storage/cache_storage.dart';
import 'infrastructure/storage/preferences.dart';
import 'infrastructure/storage/secure_storage.dart';
import 'infrastructure/logging/app_logger.dart';
import 'adapters/panel/registry.dart';
import 'adapters/panel/xboard/xboard_adapter.dart';
import 'adapters/engine/registry.dart';
import 'adapters/engine/singbox/singbox_driver.dart';
import 'features/auth/auth_notifier.dart';
import 'features/auth/auth_use_case.dart';
import 'features/connection/connection_use_case.dart';
import 'features/giftcard/giftcard_use_case.dart';
import 'features/invite/invite_use_case.dart';
import 'features/knowledge/knowledge_use_case.dart';
import 'features/node/node_notifier.dart';
import 'features/node/node_use_case.dart';
import 'features/notice/notice_use_case.dart';
import 'features/order/order_use_case.dart';
import 'features/profile/profile_use_case.dart';
import 'features/settings/locale_notifier.dart';
import 'features/stat/stat_use_case.dart';
import 'features/store/store_use_case.dart';
import 'features/ticket/ticket_use_case.dart';
import 'controllers/auth_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/node_controller.dart';
import 'controllers/store_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/ticket_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/diag_controller.dart';
import 'controllers/notice_controller.dart';
import 'controllers/knowledge_controller.dart';
import 'controllers/traffic_chart_controller.dart';
import 'controllers/splash_controller.dart';
import 'skins/skin_manager.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const isDev = !bool.fromEnvironment('dart.vm.product');
  AppLogger.setVerbose(isDev);
  await AppLogger.enableFileLogging();
  AppLogger.i('Hyena ${AppConfig.appVersion} starting…', tag: LogTag.general);

  await AppPreferences.init();
  await CacheStorage.initialize();

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

  final nodeUseCase = NodeUseCase(adapter: adapter, site: site);
  final storeUseCase = StoreUseCase(adapter: adapter, site: site);
  final orderUseCase = OrderUseCase(adapter: adapter, site: site);
  final ticketUseCase = TicketUseCase(adapter: adapter, site: site);
  final profileUseCase = ProfileUseCase(adapter: adapter, site: site);
  final inviteUseCase = InviteUseCase(adapter: adapter, site: site);
  final giftCardUseCase = GiftCardUseCase(adapter: adapter, site: site);
  final noticeUseCase = NoticeUseCase(adapter: adapter, site: site);
  final knowledgeUseCase = KnowledgeUseCase(adapter: adapter, site: site);
  final statUseCase = StatUseCase(adapter: adapter, site: site);

  final authNotifier = AuthNotifier(authUseCase);
  final nodeNotifier = NodeNotifier(useCase: nodeUseCase);
  final localeNotifier = LocaleNotifier();

  AppLogger.i('Site: ${site.panelType} @ ${site.baseUrl}', tag: LogTag.general);

  runApp(
    MultiProvider(
      providers: [
        // 基础 Notifiers（内部使用，Controller 依赖）
        ChangeNotifierProvider.value(value: authNotifier),
        ChangeNotifierProvider.value(value: nodeNotifier),
        ChangeNotifierProvider.value(value: localeNotifier),

        // UseCase 注入（Controller 内部依赖，页面不应直接使用）
        Provider<AuthUseCase>.value(value: authUseCase),
        Provider<ConnectionUseCase>.value(value: connectionUseCase),
        Provider<NodeUseCase>.value(value: nodeUseCase),
        Provider<StoreUseCase>.value(value: storeUseCase),
        Provider<OrderUseCase>.value(value: orderUseCase),
        Provider<TicketUseCase>.value(value: ticketUseCase),
        Provider<ProfileUseCase>.value(value: profileUseCase),
        Provider<InviteUseCase>.value(value: inviteUseCase),
        Provider<GiftCardUseCase>.value(value: giftCardUseCase),
        Provider<NoticeUseCase>.value(value: noticeUseCase),
        Provider<KnowledgeUseCase>.value(value: knowledgeUseCase),
        Provider<StatUseCase>.value(value: statUseCase),

        // ScreenControllers（页面通过这些交互）
        ChangeNotifierProvider(
          create: (_) => HomeController(
            connectionUseCase: connectionUseCase,
            authUseCase: authUseCase,
            nodeNotifier: nodeNotifier,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            authUseCase: authUseCase,
            authNotifier: authNotifier,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NodeController(
            nodeNotifier: nodeNotifier,
            connectionUseCase: connectionUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StoreController(storeUseCase: storeUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderController(orderUseCase: orderUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => TicketController(ticketUseCase: ticketUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileController(
            profileUseCase: profileUseCase,
            inviteUseCase: inviteUseCase,
            authNotifier: authNotifier,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsController(localeNotifier: localeNotifier),
        ),
        ChangeNotifierProvider(
          create: (_) => DiagController(connectionUseCase: connectionUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => NoticeController(noticeUseCase: noticeUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => KnowledgeController(knowledgeUseCase: knowledgeUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => TrafficChartController(statUseCase: statUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => SplashController(
            authUseCase: authUseCase,
            nodeUseCase: nodeUseCase,
            connectionUseCase: connectionUseCase,
          ),
        ),
      ],
      child: const HyenaApp(),
    ),
  );
}
