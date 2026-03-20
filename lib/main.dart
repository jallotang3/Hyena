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
import 'features/connection/connection_notifier.dart';
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

  AppLogger.i('Site: ${site.panelType} @ ${site.baseUrl}', tag: LogTag.general);

  runApp(
    MultiProvider(
      providers: [
        // Notifiers（响应式状态）
        ChangeNotifierProvider(create: (_) => AuthNotifier(authUseCase)),
        ChangeNotifierProvider(
            create: (_) => ConnectionNotifier(connectionUseCase)),
        ChangeNotifierProvider(
            create: (_) => NodeNotifier(useCase: nodeUseCase)),
        ChangeNotifierProvider(create: (_) => LocaleNotifier()),

        // UseCase 直接注入（页面按需读取）
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
      ],
      child: const HyenaApp(),
    ),
  );
}
