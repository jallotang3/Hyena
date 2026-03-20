import '../models/panel_site.dart';
import '../models/panel_user.dart';
import '../models/proxy_node.dart';
import '../models/commercial/plan_item.dart';
import '../models/commercial/order.dart';
import '../models/commercial/ticket.dart';
import '../models/commercial/invite.dart';
import '../models/commercial/notice.dart';

/// 面板认证凭证
class Credentials {
  const Credentials({required this.email, required this.password});
  final String email;
  final String password;
}

/// 注册凭证（含邀请码）
class RegisterCredentials {
  const RegisterCredentials({
    required this.email,
    required this.password,
    required this.emailCode,
    this.inviteCode,
  });

  final String email;
  final String password;
  final String emailCode;
  final String? inviteCode;
}

/// 认证结果
class AuthResult {
  const AuthResult({required this.authData, required this.user});
  final String authData;
  final PanelUser user;
}

/// 认证上下文（Token 持有）
class AuthContext {
  const AuthContext({required this.authData, required this.email});
  final String authData;
  final String email;
}

/// 用户设置更新参数
class UserSettings {
  const UserSettings({
    this.remindExpire,
    this.remindTraffic,
  });
  final bool? remindExpire;
  final bool? remindTraffic;
}

/// 创建订单请求
class OrderRequest {
  const OrderRequest({
    required this.planId,
    required this.period,
    this.couponCode,
  });
  final int planId;
  final String period;
  final String? couponCode;
}

/// 验证优惠码请求
class CouponCheckRequest {
  const CouponCheckRequest({required this.code, required this.planId});
  final String code;
  final int planId;
}

/// 礼品卡兑换结果
class GiftCardRedeemResult {
  const GiftCardRedeemResult({required this.success, this.rewards});
  final bool success;
  final List<Map<String, dynamic>>? rewards;
}

/// 礼品卡使用记录
class GiftCardUsage {
  const GiftCardUsage({
    required this.code,
    required this.redeemedAt,
  });
  final String code;
  final DateTime redeemedAt;
}

/// 面板能力声明 — 用于 UI 按能力显示/隐藏功能入口
class PanelCapabilities {
  const PanelCapabilities({
    this.supportsRefreshToken = false,
    this.supportsAnnouncement = false,
    this.supportsOrderManagement = true,
    this.supportsTicketSystem = true,
    this.supportsInviteSystem = true,
    this.supportsGiftCard = false,
    this.supportsKnowledgeBase = false,
    this.supportedProtocols = const {'vless', 'vmess', 'shadowsocks', 'trojan'},
  });

  final bool supportsRefreshToken;
  final bool supportsAnnouncement;
  final bool supportsOrderManagement;
  final bool supportsTicketSystem;
  final bool supportsInviteSystem;
  final bool supportsGiftCard;
  final bool supportsKnowledgeBase;
  final Set<String> supportedProtocols;
}

/// 统一面板适配器接口 — 所有面板实现此接口
abstract class PanelAdapter {
  /// 面板类型标识，用于注册与发现（xboard / v2board / sspanel）
  String get panelType;

  // ── 认证 ──────────────────────────────────────────────────────────────────
  Future<bool> sendEmailVerifyCode(PanelSite site, String email);
  Future<AuthResult> register(PanelSite site, RegisterCredentials cred);
  Future<AuthResult> login(PanelSite site, Credentials credentials);
  Future<void> logout(PanelSite site, AuthContext auth);
  Future<bool> resetPassword(PanelSite site, String email, String code, String newPwd);

  // ── 用户信息 ───────────────────────────────────────────────────────────────
  Future<PanelUser> fetchUserInfo(PanelSite site, AuthContext auth);
  Future<SubscribeInfo> fetchSubscribeInfo(PanelSite site, AuthContext auth);
  Future<List<ProxyNode>> fetchNodes(PanelSite site, AuthContext auth);
  Future<UserStat> fetchUserStat(PanelSite site, AuthContext auth);
  Future<bool> changePassword(PanelSite site, AuthContext auth, String oldPwd, String newPwd);
  Future<String> resetSecurity(PanelSite site, AuthContext auth);
  Future<void> updateUserSettings(PanelSite site, AuthContext auth, UserSettings settings);

  // ── 套餐 ──────────────────────────────────────────────────────────────────
  Future<List<PlanItem>> fetchPlans(PanelSite site, AuthContext auth);
  Future<PlanItem> fetchPlanDetail(PanelSite site, AuthContext auth, int planId);

  // ── 订单与支付 ─────────────────────────────────────────────────────────────
  Future<String> createOrder(PanelSite site, AuthContext auth, OrderRequest req);
  Future<List<PaymentMethod>> fetchPaymentMethods(PanelSite site, AuthContext auth);
  Future<PaymentResult> checkout(PanelSite site, AuthContext auth, String tradeNo, int methodId);
  Future<int> checkOrderStatus(PanelSite site, AuthContext auth, String tradeNo);
  Future<bool> cancelOrder(PanelSite site, AuthContext auth, String tradeNo);
  Future<List<Order>> fetchOrders(PanelSite site, AuthContext auth, {int? status});
  Future<Order> fetchOrderDetail(PanelSite site, AuthContext auth, String tradeNo);

  // ── 优惠码 / 礼品卡 ────────────────────────────────────────────────────────
  Future<CouponInfo> checkCoupon(PanelSite site, AuthContext auth, CouponCheckRequest req);
  Future<GiftCardPreview> checkGiftCard(PanelSite site, AuthContext auth, String code);
  Future<GiftCardRedeemResult> redeemGiftCard(PanelSite site, AuthContext auth, String code);
  Future<List<GiftCardUsage>> fetchGiftCardHistory(PanelSite site, AuthContext auth);

  // ── 工单 ──────────────────────────────────────────────────────────────────
  Future<List<Ticket>> fetchTickets(PanelSite site, AuthContext auth);
  Future<Ticket> fetchTicketDetail(PanelSite site, AuthContext auth, int ticketId);
  Future<bool> createTicket(PanelSite site, AuthContext auth, TicketRequest req);
  Future<bool> replyTicket(PanelSite site, AuthContext auth, int ticketId, String message);
  Future<bool> closeTicket(PanelSite site, AuthContext auth, int ticketId);

  // ── 邀请 & 佣金 ────────────────────────────────────────────────────────────
  Future<InviteSummary> fetchInviteSummary(PanelSite site, AuthContext auth);
  Future<bool> generateInviteCode(PanelSite site, AuthContext auth);
  Future<List<CommissionRecord>> fetchCommissionDetails(PanelSite site, AuthContext auth, int page);
  Future<bool> transferCommissionToBalance(PanelSite site, AuthContext auth, int amount);

  // ── 公告 / 知识库 / 流量统计 ──────────────────────────────────────────────
  Future<List<Notice>> fetchNotices(PanelSite site, AuthContext auth, {int page = 1});
  Future<List<KnowledgeArticle>> fetchKnowledge(PanelSite site, AuthContext auth,
      {String? language, String? keyword});
  Future<KnowledgeArticle> fetchKnowledgeDetail(PanelSite site, AuthContext auth, int id);
  Future<List<TrafficRecord>> fetchTrafficLog(PanelSite site, AuthContext auth);

  Future<PanelCapabilities> getCapabilities();
}
