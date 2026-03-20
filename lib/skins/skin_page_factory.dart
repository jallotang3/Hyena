import 'package:flutter/widgets.dart';

import '../controllers/home_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/node_controller.dart';
import '../controllers/store_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/ticket_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/diag_controller.dart';
import '../controllers/notice_controller.dart';
import '../controllers/knowledge_controller.dart';
import '../controllers/traffic_chart_controller.dart';
import '../controllers/splash_controller.dart';

/// 页面工厂接口 — 皮肤可覆盖任意页面
/// 返回 null 表示使用默认页面实现
abstract class SkinPageFactory {
  Widget? splashPage(SplashController c) => null;
  Widget? loginPage(AuthController c) => null;
  Widget? registerPage(AuthController c) => null;
  Widget? forgotPasswordPage(AuthController c) => null;
  Widget? homePage(HomeController c) => null;
  Widget? nodePage(NodeController c) => null;
  Widget? storePage(StoreController c) => null;
  Widget? orderConfirmPage(StoreController c) => null;
  Widget? paymentResultPage(OrderController c) => null;
  Widget? orderCenterPage(OrderController c) => null;
  Widget? orderDetailPage(OrderController c) => null;
  Widget? ticketListPage(TicketController c) => null;
  Widget? newTicketPage(TicketController c) => null;
  Widget? ticketDetailPage(TicketController c) => null;
  Widget? profilePage(ProfileController c) => null;
  Widget? invitePage(ProfileController c) => null;
  Widget? settingsPage(SettingsController c) => null;
  Widget? diagnosticsPage(DiagController c) => null;
  Widget? noticePage(NoticeController c) => null;
  Widget? knowledgePage(KnowledgeController c) => null;
  Widget? knowledgeDetailPage(KnowledgeController c) => null;
  Widget? trafficChartPage(TrafficChartController c) => null;
}
