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
import 'node_normalizer.dart';

/// Xboard 面板适配器（V1 核心实现）
///
/// API 基础约定：
/// - 基础路径：{baseUrl}/api/v1
/// - 认证方式：Authorization: {authData}（auth_data 本身已包含 Bearer 前缀）
/// - 响应格式：{ "data": ..., "message": "..." }
class XboardAdapter implements PanelAdapter {
  XboardAdapter();

  @override
  String get panelType => 'xboard';

  /// 按 (baseUrl, authData) 缓存 Dio，避免每次请求新建实例
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
      dio.interceptors.add(_XboardLoggingInterceptor());
      return dio;
    });
  }

  // ── 认证 ─────────────────────────────────────────────────────────────────

  @override
  Future<bool> sendEmailVerifyCode(PanelSite site, String email) async {
    try {
      final resp = await _dio(site).post(
        '/passport/comm/sendEmailVerify',
        data: {'email': email},
      );
      return _isSuccess(resp.data);
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
        if (cred.inviteCode != null) 'invite_code': cred.inviteCode,
      });
      return _parseAuthResult(resp.data);
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
      return _parseAuthResult(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> logout(PanelSite site, AuthContext auth) async {
    // xboard 无专用登出接口，清除本地 Token 即可
  }

  @override
  Future<bool> resetPassword(
      PanelSite site, String email, String code, String newPwd) async {
    try {
      final resp = await _dio(site).post('/passport/auth/forget', data: {
        'email': email,
        'email_code': code,
        'password': newPwd,
      });
      return _isSuccess(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 用户信息 ───────────────────────────────────────────────────────────────

  @override
  Future<PanelUser> fetchUserInfo(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/info');
      final data = _data(resp.data) as Map<String, dynamic>;
      return _mapUser(data, auth.email);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<SubscribeInfo> fetchSubscribeInfo(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/getSubscribe');
      final data = _data(resp.data) as Map<String, dynamic>;
      return SubscribeInfo(
        subscribeUrl: data['subscribe_url']?.toString() ?? '',
        deviceLimit: data['device_limit'] as int?,
        speedLimit: data['speed_limit'] as int?,
        resetDay: data['reset_day'] as int?,
        token: data['token']?.toString(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<ProxyNode>> fetchNodes(PanelSite site, AuthContext auth) async {
    try {
      return await _fetchNodesFromApi(site, auth);
    } catch (_) {
      try {
        final subInfo = await fetchSubscribeInfo(site, auth);
        return await _fetchNodesFromSubscribeUrl(subInfo.subscribeUrl);
      } on DioException catch (e) {
        throw _mapDioError(e);
      }
    }
  }

  Future<List<ProxyNode>> _fetchNodesFromApi(PanelSite site, AuthContext auth) async {
    final resp = await _dio(site, auth.authData).get('/user/server/fetch');
    final list = _data(resp.data);
    if (list is! List) return [];
    return list
        .map((n) => NodeNormalizer.fromXboardServer(n as Map<String, dynamic>))
        .whereType<ProxyNode>()
        .toList();
  }

  Future<List<ProxyNode>> _fetchNodesFromSubscribeUrl(String url) async {
    final resp = await Dio().get(url);
    final raw = resp.data?.toString() ?? '';
    try {
      final decoded = utf8.decode(base64.decode(raw));
      return NodeNormalizer.fromSubscriptionContent(decoded);
    } catch (e) {
      AppLogger.w('订阅 URL 解析失败，尝试原始内容: $e', tag: LogTag.adapter);
      return NodeNormalizer.fromSubscriptionContent(raw);
    }
  }

  @override
  Future<UserStat> fetchUserStat(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/getStat');
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return UserStat(
        pendingOrderCount: (data['pending_order_count'] as num?)?.toInt() ?? 0,
        openTicketCount: (data['ticket_count'] as num?)?.toInt() ?? 0,
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
      final resp = await _dio(site, auth.authData).post('/user/changePassword', data: {
        'old_password': oldPwd,
        'new_password': newPwd,
      });
      return _isSuccess(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<String> resetSecurity(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/resetSecurity');
      return _data(resp.data)?.toString() ?? '';
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
  Future<PlanItem> fetchPlanDetail(PanelSite site, AuthContext auth, int planId) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/plan/fetch', queryParameters: {'id': planId});
      return _mapPlan(_data(resp.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 订单与支付 ─────────────────────────────────────────────────────────────

  @override
  Future<String> createOrder(PanelSite site, AuthContext auth, OrderRequest req) async {
    try {
      final resp = await _dio(site, auth.authData).post('/user/order/save', data: {
        'plan_id': req.planId,
        'period': req.period,
        if (req.couponCode != null) 'coupon_code': req.couponCode,
      });
      return _data(resp.data)?.toString() ?? '';
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<PaymentMethod>> fetchPaymentMethods(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/order/getPaymentMethod');
      final list = _data(resp.data);
      if (list is! List) return [];
      return list.map((m) => _mapPaymentMethod(m as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<PaymentResult> checkout(
      PanelSite site, AuthContext auth, String tradeNo, int methodId) async {
    try {
      final resp = await _dio(site, auth.authData).post('/user/order/checkout', data: {
        'trade_no': tradeNo,
        'method': methodId,
      });
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return PaymentResult(
        type: data['type']?.toString() ?? 'unknown',
        tradeNo: tradeNo,
        data: data,
        redirectUrl: data['redirect_url']?.toString(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<int> checkOrderStatus(PanelSite site, AuthContext auth, String tradeNo) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/order/check', queryParameters: {'trade_no': tradeNo});
      return ((_data(resp.data)) as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> cancelOrder(PanelSite site, AuthContext auth, String tradeNo) async {
    try {
      final resp = await _dio(site, auth.authData)
          .post('/user/order/cancel', data: {'trade_no': tradeNo});
      return _isSuccess(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<Order>> fetchOrders(PanelSite site, AuthContext auth, {int? status}) async {
    try {
      final resp = await _dio(site, auth.authData).get(
        '/user/order/fetch',
        queryParameters: {if (status != null) 'status': status},
      );
      final list = _data(resp.data);
      if (list is! List) return [];
      return list.map((o) => _mapOrder(o as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<Order> fetchOrderDetail(PanelSite site, AuthContext auth, String tradeNo) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/order/detail', queryParameters: {'trade_no': tradeNo});
      return _mapOrder(_data(resp.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 优惠码 / 礼品卡 ────────────────────────────────────────────────────────

  @override
  Future<CouponInfo> checkCoupon(
      PanelSite site, AuthContext auth, CouponCheckRequest req) async {
    try {
      final resp = await _dio(site, auth.authData).post('/user/coupon/check', data: {
        'code': req.code,
        'plan_id': req.planId,
      });
      final data = _data(resp.data) as Map<String, dynamic>;
      return CouponInfo(
        code: req.code,
        type: (data['type'] as num?)?.toInt() ?? 1,
        value: (data['value'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<GiftCardPreview> checkGiftCard(PanelSite site, AuthContext auth, String code) async {
    try {
      final resp = await _dio(site, auth.authData)
          .post('/user/gift-card/check', data: {'code': code});
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return GiftCardPreview(
        code: code,
        canRedeem: data['can_redeem'] as bool? ?? false,
        reason: data['reason']?.toString(),
        rewardPreview: (data['reward_preview'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<GiftCardRedeemResult> redeemGiftCard(
      PanelSite site, AuthContext auth, String code) async {
    try {
      final resp = await _dio(site, auth.authData)
          .post('/user/gift-card/redeem', data: {'code': code});
      final data = _data(resp.data) as Map<String, dynamic>? ?? {};
      return GiftCardRedeemResult(
        success: true,
        rewards: (data['rewards'] as List?)?.cast<Map<String, dynamic>>(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<GiftCardUsage>> fetchGiftCardHistory(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/gift-card/history');
      final list = _data(resp.data);
      if (list is! List) return [];
      return list.map((h) {
        final m = h as Map<String, dynamic>;
        return GiftCardUsage(
          code: m['code']?.toString() ?? '',
          redeemedAt: DateTime.fromMillisecondsSinceEpoch(
              ((m['created_at'] as num?)?.toInt() ?? 0) * 1000),
        );
      }).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
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
  Future<Ticket> fetchTicketDetail(PanelSite site, AuthContext auth, int ticketId) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/ticket/fetch', queryParameters: {'id': ticketId});
      return _mapTicket(_data(resp.data) as Map<String, dynamic>, withMessages: true);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> createTicket(PanelSite site, AuthContext auth, TicketRequest req) async {
    try {
      final resp = await _dio(site, auth.authData).post('/user/ticket/save', data: {
        'subject': req.subject,
        'level': req.level.code,
        'message': req.message,
      });
      return _isSuccess(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> replyTicket(
      PanelSite site, AuthContext auth, int ticketId, String message) async {
    try {
      final resp = await _dio(site, auth.authData).post('/user/ticket/reply', data: {
        'id': ticketId,
        'message': message,
      });
      return _isSuccess(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> closeTicket(PanelSite site, AuthContext auth, int ticketId) async {
    try {
      final resp = await _dio(site, auth.authData)
          .post('/user/ticket/close', data: {'id': ticketId});
      return _isSuccess(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 邀请 & 佣金 ────────────────────────────────────────────────────────────

  @override
  Future<InviteSummary> fetchInviteSummary(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/invite/fetch');
      final data = _data(resp.data) as Map<String, dynamic>;
      final codes = (data['codes'] as List?)
              ?.map((c) => _mapInviteCode(c as Map<String, dynamic>))
              .toList() ??
          [];
      final stat = data['stat'] as Map<String, dynamic>? ?? {};
      return InviteSummary(
        codes: codes,
        registeredCount: (stat['register_count'] as num?)?.toInt() ?? 0,
        commissionTotal: (stat['commission_total'] as num?)?.toInt() ?? 0,
        commissionPending: (stat['commission_pending'] as num?)?.toInt() ?? 0,
        commissionBalance: (stat['commission_balance'] as num?)?.toInt() ?? 0,
        commissionRate: (stat['commission_rate'] as num?)?.toDouble() ?? 0.0,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> generateInviteCode(PanelSite site, AuthContext auth) async {
    try {
      final resp = await _dio(site, auth.authData).get('/user/invite/save');
      return _isSuccess(resp.data);
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
      final list = (_data(resp.data) as Map<String, dynamic>?)?['data'] as List? ?? [];
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
      final resp = await _dio(site, auth.authData)
          .post('/user/transfer', data: {'transfer_amount': amount});
      return _isSuccess(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 公告 / 知识库 / 统计 ─────────────────────────────────────────────────

  @override
  Future<List<Notice>> fetchNotices(PanelSite site, AuthContext auth,
      {int page = 1}) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/notice/fetch', queryParameters: {'page': page});
      final list = _data(resp.data) as List? ?? [];
      return list.map((n) {
        final m = n as Map<String, dynamic>;
        return Notice(
          id: (m['id'] as num?)?.toInt() ?? 0,
          title: m['title']?.toString() ?? '',
          content: m['content']?.toString() ?? '',
          imgUrl: m['img_url']?.toString(),
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
    try {
      final resp = await _dio(site, auth.authData).get('/user/knowledge/fetch',
          queryParameters: {
            if (language != null) 'language': language,
            if (keyword != null) 'keyword': keyword,
          });
      final list = _data(resp.data) as List? ?? [];
      return list.map((a) => _mapArticle(a as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<KnowledgeArticle> fetchKnowledgeDetail(
      PanelSite site, AuthContext auth, int id) async {
    try {
      final resp = await _dio(site, auth.authData)
          .get('/user/knowledge/fetch', queryParameters: {'id': id});
      return _mapArticle(_data(resp.data) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<TrafficRecord>> fetchTrafficLog(PanelSite site, AuthContext auth) async {
    try {
      final resp =
          await _dio(site, auth.authData).get('/user/stat/getTrafficLog');
      final list = _data(resp.data) as List? ?? [];
      return list.map((r) {
        final m = r as Map<String, dynamic>;
        return TrafficRecord(
          date: DateTime.fromMillisecondsSinceEpoch(
              ((m['record_at'] as num?)?.toInt() ?? 0) * 1000),
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
      supportsGiftCard: true,
      supportsKnowledgeBase: true,
      supportedProtocols: {'vless', 'vmess', 'shadowsocks', 'trojan', 'hysteria2'},
    );
  }

  // ── 私有映射方法 ──────────────────────────────────────────────────────────

  AuthResult _parseAuthResult(dynamic responseData) {
    final data = (responseData as Map<String, dynamic>?)?['data']
        as Map<String, dynamic>?;
    if (data == null) throw const AuthException('认证响应格式错误');

    final authData = data['auth_data']?.toString() ?? '';
    if (authData.isEmpty) throw const AuthException('认证 Token 为空');

    final userRaw = data['user'] as Map<String, dynamic>? ?? data;
    return AuthResult(
      authData: authData,
      user: _mapUser(userRaw, ''),
    );
  }

  PanelUser _mapUser(Map<String, dynamic> data, String fallbackEmail) {
    final transferEnable = (data['transfer_enable'] as num?)?.toInt() ?? -1;
    final used = ((data['u'] as num?)?.toInt() ?? 0) +
        ((data['d'] as num?)?.toInt() ?? 0);
    final expiredAt = data['expired_at'];
    DateTime? expireAt;
    if (expiredAt is int) {
      expireAt = DateTime.fromMillisecondsSinceEpoch(expiredAt * 1000);
    }

    return PanelUser(
      email: data['email']?.toString() ?? fallbackEmail,
      trafficUsed: used,
      trafficTotal: transferEnable,
      expireAt: expireAt,
      planName: data['plan_name']?.toString() ?? '',
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      commissionBalance: (data['commission_balance'] as num?)?.toInt() ?? 0,
      planId: (data['plan_id'] as num?)?.toInt(),
      uuid: data['uuid']?.toString(),
    );
  }

  PlanItem _mapPlan(Map<String, dynamic> data) {
    final prices = <String, int?>{};
    for (final key in PlanItem.periods) {
      final v = data[key];
      prices[key] = v is int
          ? v
          : v is double
              ? v.toInt()
              : null;
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
    return PaymentMethod(
      id: (data['id'] as num?)?.toInt() ?? 0,
      name: data['name']?.toString() ?? '',
      payment: data['payment']?.toString() ?? '',
      handlingFeeFixed: (data['handling_fee_fixed'] as num?)?.toInt(),
      handlingFeePercent: (data['handling_fee_percent'] as num?)?.toDouble(),
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
    final messages = withMessages
        ? (data['message'] as List?)
            ?.map((m) => _mapTicketMessage(m as Map<String, dynamic>))
            .toList()
        : null;

    return Ticket(
      id: (data['id'] as num?)?.toInt() ?? 0,
      subject: data['subject']?.toString() ?? '',
      level: TicketLevel.fromCode((data['level'] as num?)?.toInt() ?? 1),
      status: TicketStatus.fromCode((data['status'] as num?)?.toInt() ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          ((data['created_at'] as num?)?.toInt() ?? 0) * 1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          ((data['updated_at'] as num?)?.toInt() ?? 0) * 1000),
      messages: messages,
    );
  }

  TicketMessage _mapTicketMessage(Map<String, dynamic> data) {
    return TicketMessage(
      id: (data['id'] as num?)?.toInt() ?? 0,
      message: data['message']?.toString() ?? '',
      isMe: data['is_me'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          ((data['created_at'] as num?)?.toInt() ?? 0) * 1000),
    );
  }

  InviteCode _mapInviteCode(Map<String, dynamic> data) {
    return InviteCode(
      id: (data['id'] as num?)?.toInt() ?? 0,
      code: data['code']?.toString() ?? '',
      status: (data['status'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          ((data['created_at'] as num?)?.toInt() ?? 0) * 1000),
    );
  }

  KnowledgeArticle _mapArticle(Map<String, dynamic> data) {
    return KnowledgeArticle(
      id: (data['id'] as num?)?.toInt() ?? 0,
      title: data['title']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      body: data['body']?.toString(),
      language: data['language']?.toString(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          ((data['updated_at'] as num?)?.toInt() ?? 0) * 1000),
    );
  }

  // ── 工具方法 ──────────────────────────────────────────────────────────────

  dynamic _data(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData['data'];
    }
    return responseData;
  }

  bool _isSuccess(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is bool) return data;
      return responseData.containsKey('data');
    }
    return false;
  }

  AppError _mapDioError(DioException e) {
    final error = e.error;
    if (error is AppError) return error;

    final status = e.response?.statusCode;
    final msg = _extractMessage(e.response?.data) ?? e.message ?? '请求失败';
    return switch (status) {
      401 => const AuthExpiredException(),
      422 => ApiValidationException(msg),
      _ when (status ?? 0) >= 500 => PanelUnavailableException(msg, statusCode: status),
      _ => PanelUnavailableException(msg, statusCode: status),
    };
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? data['msg']?.toString();
    }
    return null;
  }
}

class _XboardLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d('→ ${options.method} ${options.path}', tag: LogTag.adapter);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d('← ${response.statusCode} ${response.requestOptions.path}',
        tag: LogTag.adapter);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e('✗ ${err.requestOptions.path}: ${err.message}',
        tag: LogTag.adapter);
    handler.next(err);
  }
}
