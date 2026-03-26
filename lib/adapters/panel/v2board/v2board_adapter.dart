import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/interfaces/panel_adapter.dart';
import '../../../core/models/panel_site.dart';
import '../../../core/models/panel_user.dart';
import '../../../core/models/proxy_node.dart';
import '../../../core/models/commercial/plan_item.dart';
import '../../../core/models/commercial/order.dart';
import '../../../core/models/commercial/ticket.dart';
import '../../../core/models/commercial/invite.dart';
import '../../../core/models/commercial/notice.dart';
import '../../../core/errors/app_error.dart';
import '../../../infrastructure/logging/app_logger.dart';
import '../xboard/node_normalizer.dart';

/// v2board 面板适配器
///
/// API 基础约定（与 xboard 的主要差异）：
/// - 基础路径：{baseUrl}/api/v1（相同）
/// - 认证字段：token（v2board），auth_data（xboard）
/// - 响应格式：{ "data": ..., "message": "..." }（相同）
///
/// 功能差异对照（见 PanelCapabilities）：
/// | 功能       | xboard | v2board |
/// |-----------|--------|---------|
/// | 礼品卡     | ✅     | ❌      |
/// | 知识库     | ✅     | ❌      |
/// | 公告       | ✅     | ✅      |
/// | 邀请佣金   | ✅     | ✅      |
class V2boardAdapter implements PanelAdapter {
  V2boardAdapter();

  @override
  String get panelType => 'v2board';

  final Map<String, Dio> _dioCache = {};

  Dio _dio(PanelSite site, [String? authData]) {
    final key = '${site.baseUrl}|${authData ?? ''}';
    return _dioCache.putIfAbsent(key, () {
      final dio = Dio(BaseOptions(
        baseUrl: '${site.baseUrl}/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authData != null && authData.isNotEmpty) 'Authorization': authData,
        },
      ));
      dio.interceptors.add(_V2boardLoggingInterceptor());
      return dio;
    });
  }

  // ── 认证 ─────────────────────────────────────────────────────────────────

  @override
  Future<bool> sendEmailVerifyCode(PanelSite site, String email) async {
    try {
      await _dio(site).post('/passport/comm/sendEmailVerify',
          data: {'email': email});
      return true;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<AuthResult> register(PanelSite site, RegisterCredentials cred) async {
    try {
      final resp = await _dio(site).post('/passport/auth/register', data: {
        'email': cred.email,
        'password': cred.password,
        'email_code': cred.emailCode,
        if (cred.inviteCode != null && cred.inviteCode!.isNotEmpty)
          'invite_code': cred.inviteCode,
      });
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      final authData = _extractToken(data);
      if (authData.isEmpty) throw const AuthException('注册返回 Token 为空');
      return AuthResult(authData: authData, user: _mapUser(data, cred.email));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<AuthResult> login(PanelSite site, Credentials credentials) async {
    try {
      final resp = await _dio(site).post('/passport/auth/login', data: {
        'email': credentials.email,
        'password': credentials.password,
      });
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      final authData = _extractToken(data);
      if (authData.isEmpty) throw const AuthException('登录 Token 为空');
      return AuthResult(
          authData: authData, user: _mapUser(data, credentials.email));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> logout(PanelSite site, AuthContext auth) async {
    // v2board 无专用登出接口，仅清除本地 Token 即可
    AppLogger.i('v2board: 登出（本地清除 Token）', tag: LogTag.auth);
  }

  @override
  Future<bool> resetPassword(
      PanelSite site, String email, String code, String newPwd) async {
    try {
      await _dio(site).post('/passport/auth/forget', data: {
        'email': email,
        'email_code': code,
        'password': newPwd,
      });
      return true;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 用户信息 ───────────────────────────────────────────────────────────────

  @override
  Future<PanelUser> fetchUserInfo(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/info');
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return _mapUser(data, auth.email);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<SubscribeInfo> fetchSubscribeInfo(
      PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/getSubscribe');
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return SubscribeInfo(
        subscribeUrl: data['subscribe_url']?.toString() ?? '',
        deviceLimit: (data['device_limit'] as num?)?.toInt(),
        speedLimit: (data['speed_limit'] as num?)?.toInt(),
        token: data['token']?.toString(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<ProxyNode>> fetchNodes(PanelSite site, AuthContext auth) async {
    try {
      // 优先尝试 API 方式
      final resp =
          await _dio(site, auth.authData).get('/user/server/fetch');
      final raw = _data(resp.data);
      if (raw is List) {
        final nodes = <ProxyNode>[];
        for (final item in raw) {
          try {
            final node =
                NodeNormalizer.fromXboardServer(item as Map<String, dynamic>);
            if (node != null) nodes.add(node);
          } catch (e) {
            AppLogger.w('v2board: 节点解析失败: $e', tag: LogTag.node);
          }
        }
        return nodes;
      }

      // 回退：订阅 URL 方式
      final subInfo = await fetchSubscribeInfo(site, auth);
      if (subInfo.subscribeUrl.isNotEmpty) {
        return _parseSubscribeUrl(subInfo.subscribeUrl);
      }
      return [];
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<ProxyNode>> _parseSubscribeUrl(String url) async {
    try {
      final resp = await Dio().get<String>(url);
      final body = resp.data ?? '';
      final decoded = utf8.decode(base64.decode(body.trim()));
      return NodeNormalizer.fromSubscriptionContent(decoded);
    } catch (e) {
      AppLogger.w('v2board: 订阅解析失败: $e', tag: LogTag.node);
      return [];
    }
  }

  @override
  Future<UserStat> fetchUserStat(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/getStat');
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return UserStat(
        pendingOrderCount:
            (data['pending_order_count'] as num?)?.toInt() ?? 0,
        openTicketCount:
            (data['ticket_pending_count'] as num?)?.toInt() ?? 0,
        inviteCount: (data['invite_count'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> changePassword(
      PanelSite site, AuthContext auth, String oldPwd, String newPwd) async {
    try {
      await _dio(site, auth.authData).post('/user/changePassword', data: {
        'old_password': oldPwd,
        'new_password': newPwd,
      });
      return true;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<String> resetSecurity(PanelSite site, AuthContext auth) async {
    try {
      final resp =
          await _dio(site, auth.authData).get('/user/resetSecurity');
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return data['subscribe_url']?.toString() ?? '';
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> updateUserSettings(
      PanelSite site, AuthContext auth, UserSettings settings) async {
    try {
      await _dio(site, auth.authData).post('/user/update', data: {
        if (settings.remindExpire != null)
          'remind_expire': settings.remindExpire! ? 1 : 0,
        if (settings.remindTraffic != null)
          'remind_traffic': settings.remindTraffic! ? 1 : 0,
      });
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 套餐 ──────────────────────────────────────────────────────────────────

  @override
  Future<List<PlanItem>> fetchPlans(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/plan/fetch');
      final list = _data(resp.data);
      if (list is! List) return [];
      return list.map((p) => _mapPlan(p as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<PlanItem> fetchPlanDetail(
      PanelSite site, AuthContext auth, int planId) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/plan/fetch',
          queryParameters: {'id': planId});
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return _mapPlan(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 订单与支付 ─────────────────────────────────────────────────────────────

  @override
  Future<String> createOrder(
      PanelSite site, AuthContext auth, OrderRequest req) async {
    try {
      final resp = await _dio(site, auth.authData).post('/user/order/save',
          data: {
            'plan_id': req.planId,
            'period': req.period,
            if (req.couponCode != null && req.couponCode!.isNotEmpty)
              'coupon_code': req.couponCode,
          });
      return _data(resp.data)?.toString() ?? '';
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<PaymentMethod>> fetchPaymentMethods(
      PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/order/getPaymentMethod');
      final list = _data(resp.data);
      if (list is! List) return [];
      return list
          .map((m) => _mapPaymentMethod(m as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<PaymentResult> checkout(
      PanelSite site, AuthContext auth, String tradeNo, int methodId) async {
    try {
      final resp =
          await _dio(site, auth.authData).post('/user/order/checkout', data: {
        'trade_no': tradeNo,
        'method': methodId,
      });
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      // type='1' 代表跳转支付，redirectUrl 在 data['data'] 字段
      final redirectUrl =
          data['type']?.toString() == '1' ? data['data']?.toString() : null;
      return PaymentResult(
        type: data['type']?.toString() ?? 'unknown',
        tradeNo: tradeNo,
        data: data,
        redirectUrl: redirectUrl,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<int> checkOrderStatus(
      PanelSite site, AuthContext auth, String tradeNo) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/order/check', queryParameters: {'trade_no': tradeNo});
      return (_data(resp.data) as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> cancelOrder(
      PanelSite site, AuthContext auth, String tradeNo) async {
    try {
      await _dio(site, auth.authData)
          .post('/user/order/cancel', data: {'trade_no': tradeNo});
      return true;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<Order>> fetchOrders(PanelSite site, AuthContext auth,
      {int? status}) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/order/fetch',
          queryParameters: {if (status != null) 'status': status});
      final list = _data(resp.data);
      if (list is! List) return [];
      return list.map((o) => _mapOrder(o as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<Order> fetchOrderDetail(
      PanelSite site, AuthContext auth, String tradeNo) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/order/detail', queryParameters: {'trade_no': tradeNo});
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return _mapOrder(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 优惠码（支持）/ 礼品卡（不支持）────────────────────────────────────────

  @override
  Future<CouponInfo> checkCoupon(
      PanelSite site, AuthContext auth, CouponCheckRequest req) async {
    try {
      final resp = await _dio(site, auth.authData).post('/user/coupon/check',
          data: {'code': req.code, 'plan_id': req.planId});
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return CouponInfo(
        code: req.code,
        type: (data['type'] as num?)?.toInt() ?? 1,
        value: (data['value'] as num?)?.toInt() ?? 0,
        limitUse: (data['limit_use'] as num?)?.toInt(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<GiftCardPreview> checkGiftCard(
      PanelSite site, AuthContext auth, String code) async {
    throw UnsupportedError('v2board 不支持礼品卡功能');
  }

  @override
  Future<GiftCardRedeemResult> redeemGiftCard(
      PanelSite site, AuthContext auth, String code) async {
    throw UnsupportedError('v2board 不支持礼品卡功能');
  }

  @override
  Future<List<GiftCardUsage>> fetchGiftCardHistory(
      PanelSite site, AuthContext auth) async {
    return [];
  }

  // ── 工单 ──────────────────────────────────────────────────────────────────

  @override
  Future<List<Ticket>> fetchTickets(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/ticket/fetch');
      final list = _data(resp.data);
      if (list is! List) return [];
      return list.map((t) => _mapTicket(t as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<Ticket> fetchTicketDetail(
      PanelSite site, AuthContext auth, int ticketId) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/ticket/fetch', queryParameters: {'id': ticketId});
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return _mapTicket(data, withMessages: true);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> createTicket(
      PanelSite site, AuthContext auth, TicketRequest req) async {
    try {
      await _dio(site, auth.authData).post('/user/ticket/save', data: {
        'subject': req.subject,
        'level': req.level.code,
        'message': req.message,
      });
      return true;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> replyTicket(
      PanelSite site, AuthContext auth, int ticketId, String message) async {
    try {
      await _dio(site, auth.authData).post('/user/ticket/reply',
          data: {'id': ticketId, 'message': message});
      return true;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> closeTicket(
      PanelSite site, AuthContext auth, int ticketId) async {
    try {
      await _dio(site, auth.authData)
          .post('/user/ticket/close', data: {'id': ticketId});
      return true;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 邀请 & 佣金 ────────────────────────────────────────────────────────────

  @override
  Future<InviteSummary> fetchInviteSummary(
      PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/invite/fetch');
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      final stat = data['stat'] as List?;
      final codes = (data['codes'] as List?)
              ?.map((c) {
                final m = c as Map<String, dynamic>;
                return InviteCode(
                  id: (m['id'] as num?)?.toInt() ?? 0,
                  code: m['code']?.toString() ?? '',
                  status: (m['pv'] as num?)?.toInt() ?? 0,
                  createdAt: DateTime.fromMillisecondsSinceEpoch(
                      ((m['created_at'] as num?)?.toInt() ?? 0) * 1000),
                );
              })
              .toList() ??
          [];
      return InviteSummary(
        codes: codes,
        registeredCount: (stat?[0] as num?)?.toInt() ?? 0,
        commissionTotal: (stat?[1] as num?)?.toInt() ?? 0,
        commissionPending: (stat?[2] as num?)?.toInt() ?? 0,
        commissionBalance:
            (data['commission_balance'] as num?)?.toInt() ?? 0,
        commissionRate:
            (data['commission_rate'] as num?)?.toDouble() ?? 0.0,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> generateInviteCode(PanelSite site, AuthContext auth) async {
    try {
      await _dio(site, auth.authData).get('/user/invite/save');
      return true;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<CommissionRecord>> fetchCommissionDetails(
      PanelSite site, AuthContext auth, int page) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/invite/details', queryParameters: {'page': page});
      final list = _data(resp.data);
      if (list is! List) return [];
      return list.map((r) {
        final m = r as Map<String, dynamic>;
        return CommissionRecord(
          id: (m['id'] as num?)?.toInt() ?? 0,
          inviteUserId: (m['invite_user_id'] as num?)?.toInt() ?? 0,
          getAmount: (m['get_amount'] as num?)?.toInt() ?? 0,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
              ((m['created_at'] as num?)?.toInt() ?? 0) * 1000),
        );
      }).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> transferCommissionToBalance(
      PanelSite site, AuthContext auth, int amount) async {
    try {
      await _dio(site, auth.authData)
          .post('/user/transfer', data: {'transfer_amount': amount});
      return true;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 公告 / 知识库（不支持）/ 流量统计 ─────────────────────────────────────

  @override
  Future<List<Notice>> fetchNotices(PanelSite site, AuthContext auth,
      {int page = 1}) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/notice/fetch', queryParameters: {'page': page});
      final list = _data(resp.data);
      if (list is! List) return [];
      return list.map((n) {
        final m = n as Map<String, dynamic>;
        return Notice(
          id: (m['id'] as num?)?.toInt() ?? 0,
          title: m['title']?.toString() ?? '',
          content: m['content']?.toString() ?? '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(
              ((m['created_at'] as num?)?.toInt() ?? 0) * 1000),
        );
      }).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<KnowledgeArticle>> fetchKnowledge(PanelSite site, AuthContext auth,
      {String? language, String? keyword}) async {
    // v2board 不支持知识库
    return [];
  }

  @override
  Future<KnowledgeArticle> fetchKnowledgeDetail(
      PanelSite site, AuthContext auth, int id) async {
    throw UnsupportedError('v2board 不支持知识库功能');
  }

  @override
  Future<List<TrafficRecord>> fetchTrafficLog(
      PanelSite site, AuthContext auth) async {
    try {
      final resp =
          await _dio(site, auth.authData).get('/user/stat/getTrafficLog');
      final list = _data(resp.data);
      if (list is! List) return [];
      return list.map((r) {
        final m = r as Map<String, dynamic>;
        return TrafficRecord(
          date: DateTime.tryParse(m['date']?.toString() ?? '') ??
              DateTime(2000),
          uploadBytes: (m['u'] as num?)?.toInt() ?? 0,
          downloadBytes: (m['d'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<PanelCapabilities> getCapabilities() async {
    return const PanelCapabilities(
      supportsRefreshToken: false,
      supportsAnnouncement: true,
      supportsOrderManagement: true,
      supportsTicketSystem: true,
      supportsInviteSystem: true,
      supportsGiftCard: false,
      supportsKnowledgeBase: false,
      supportedProtocols: {
        'vless',
        'vmess',
        'shadowsocks',
        'trojan',
        'hysteria2',
      },
    );
  }

  // ── 内部映射方法 ───────────────────────────────────────────────────────────

  /// 从登录/注册响应中提取 Token，统一处理 Bearer 前缀
  String _extractToken(Map<String, dynamic> data) {
    final raw = data['token']?.toString() ??
        data['auth_data']?.toString() ??
        '';
    if (raw.isEmpty) return '';
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  PanelUser _mapUser(Map<String, dynamic> data, String fallbackEmail) {
    final transferEnable = (data['transfer_enable'] as num?)?.toInt() ?? -1;
    final used = ((data['u'] as num?)?.toInt() ?? 0) +
        ((data['d'] as num?)?.toInt() ?? 0);
    final expiredAt = data['expired_at'];
    DateTime? expireAt;
    if (expiredAt is int) {
      expireAt = DateTime.fromMillisecondsSinceEpoch(expiredAt * 1000);
    } else if (expiredAt is String) {
      final ts = int.tryParse(expiredAt);
      expireAt = ts != null
          ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
          : DateTime.tryParse(expiredAt);
    }

    return PanelUser(
      email: data['email']?.toString() ?? fallbackEmail,
      trafficUsed: used,
      trafficTotal: transferEnable,
      expireAt: expireAt,
      planName: data['plan']?['name']?.toString() ?? '',
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      commissionBalance:
          (data['commission_balance'] as num?)?.toInt() ?? 0,
    );
  }

  PlanItem _mapPlan(Map<String, dynamic> data) {
    final prices = <String, int>{};
    for (final key in [
      'month_price',
      'quarter_price',
      'half_year_price',
      'year_price',
      'two_year_price',
      'three_year_price',
      'onetime_price',
    ]) {
      final v = data[key];
      if (v != null) prices[key] = (v as num).toInt();
    }
    return PlanItem(
      id: (data['id'] as num?)?.toInt() ?? 0,
      name: data['name']?.toString() ?? '',
      transferEnable: (data['transfer_enable'] as num?)?.toInt(),
      speedLimit: (data['speed_limit'] as num?)?.toInt(),
      deviceLimit: (data['device_limit'] as num?)?.toInt(),
      prices: prices,
      content: data['content']?.toString(),
      show: data['show'] == 1 || data['show'] == true,
      sell: data['sell'] == 1 || data['sell'] == true,
    );
  }

  PaymentMethod _mapPaymentMethod(Map<String, dynamic> data) {
    // 与 Xboard OpenAPI 一致：列表项可能不含 enable，未返回时视为启用。
    final enableRaw = data['enable'];
    final enable = enableRaw == null
        ? true
        : (enableRaw == 1 || enableRaw == true);
    return PaymentMethod(
      id: (data['id'] as num?)?.toInt() ?? 0,
      name: data['name']?.toString() ?? '',
      payment: data['payment']?.toString() ?? '',
      icon: data['icon']?.toString(),
      handlingFeeFixed: (data['handling_fee_fixed'] as num?)?.toInt(),
      handlingFeePercent:
          (data['handling_fee_percent'] as num?)?.toDouble(),
      enable: enable,
    );
  }

  Order _mapOrder(Map<String, dynamic> data) {
    return Order(
      tradeNo: data['trade_no']?.toString() ?? '',
      status: OrderStatus.fromCode((data['status'] as num?)?.toInt() ?? 0),
      totalAmount: (data['total_amount'] as num?)?.toInt() ?? 0,
      balanceAmount: (data['balance_amount'] as num?)?.toInt(),
      handlingAmount: (data['handling_amount'] as num?)?.toInt(),
      discountAmount: (data['discount_amount'] as num?)?.toInt(),
      period: data['period']?.toString() ?? '',
      couponCode: data['coupon_code']?.toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          ((data['created_at'] as num?)?.toInt() ?? 0) * 1000),
    );
  }

  Ticket _mapTicket(Map<String, dynamic> data, {bool withMessages = false}) {
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
        ((data['updated_at'] as num?)?.toInt() ?? 0) * 1000);

    final messages = withMessages
        ? (data['message'] as List?)
            ?.map((m) {
              final msg = m as Map<String, dynamic>;
              // v2board: is_manager=1 表示客服；用户侧 isMe=false
              final isManager =
                  (msg['is_manager'] as num?)?.toInt() == 1;
              return TicketMessage(
                id: (msg['id'] as num?)?.toInt() ?? 0,
                message: msg['message']?.toString() ?? '',
                isMe: !isManager,
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                    ((msg['created_at'] as num?)?.toInt() ?? 0) * 1000),
              );
            })
            .toList()
        : null;

    return Ticket(
      id: (data['id'] as num?)?.toInt() ?? 0,
      subject: data['subject']?.toString() ?? '',
      level: TicketLevel.fromCode((data['level'] as num?)?.toInt() ?? 1),
      status: TicketStatus.fromCode((data['status'] as num?)?.toInt() ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          ((data['created_at'] as num?)?.toInt() ?? 0) * 1000),
      updatedAt: updatedAt,
      messages: messages,
    );
  }

  // ── 通用工具 ───────────────────────────────────────────────────────────────

  dynamic _data(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData['data'];
    }
    return responseData;
  }

  AppError _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = () {
      try {
        final data = e.response?.data;
        if (data is Map) return data['message']?.toString();
        return null;
      } catch (_) {
        return null;
      }
    }();

    if (statusCode == 401) {
      return AuthException(message ?? '登录已过期，请重新登录');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('请求超时');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException('网络连接失败');
    }
    return PanelUnavailableException(
        message ?? '服务器错误 ($statusCode)',
        statusCode: statusCode);
  }
}

/// v2board 专用日志拦截器
class _V2boardLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d(
      'v2board → ${options.method} ${options.path}',
      tag: LogTag.network,
    );
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.w(
      'v2board ← ERROR ${err.response?.statusCode} ${err.requestOptions.path}',
      tag: LogTag.network,
    );
    handler.next(err);
  }
}
