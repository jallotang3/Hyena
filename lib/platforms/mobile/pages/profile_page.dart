import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/profile_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 移动端个人中心页（Material Design）
class MobileProfilePage extends StatefulWidget {
  final ProfileController controller;

  const MobileProfilePage({required this.controller, super.key});

  @override
  State<MobileProfilePage> createState() => _MobileProfilePageState();
}

class _MobileProfilePageState extends State<MobileProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.fetchUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      appBar: AppBar(
        backgroundColor: tokens.colorBackground,
        title: Text(s.profile),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: tokens.colorOnBackground),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading && widget.controller.user == null) {
            return Center(
              child: CircularProgressIndicator(color: tokens.colorPrimary),
            );
          }
          return _ProfileContent(
            controller: widget.controller,
            tokens: tokens,
          );
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.controller,
    required this.tokens,
  });

  final ProfileController controller;
  final ThemeTokens tokens;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${units[i]}';
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final u = controller.user;

    return RefreshIndicator(
      onRefresh: () async => controller.fetchUser(),
      color: tokens.colorPrimary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 用户头像和信息
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.colorPrimary.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(
                      u?.email.isNotEmpty == true
                          ? u!.email[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: tokens.colorPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  u?.email ?? '–',
                  style: TextStyle(
                    color: tokens.colorOnBackground,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (u != null && u.planName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tokens.colorPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(tokens.radiusSmall),
                    ),
                    child: Text(
                      u.planName,
                      style: TextStyle(
                        color: tokens.colorPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 流量使用卡片
          if (u != null) ...[
            _InfoCard(
              icon: Icons.data_usage,
              title: s.trafficUsage,
              tokens: tokens,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatBytes(u.trafficUsed),
                        style: TextStyle(
                          color: tokens.colorPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        u.trafficTotal > 0
                            ? '/ ${_formatBytes(u.trafficTotal)}'
                            : '/ ∞',
                        style: TextStyle(
                          color: tokens.colorMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(tokens.radiusSmall),
                    child: LinearProgressIndicator(
                      value: u.trafficTotal > 0
                          ? u.trafficUsedPercent.clamp(0.0, 1.0)
                          : 0,
                      minHeight: 8,
                      backgroundColor: tokens.colorMuted.withValues(alpha: 0.2),
                      color: tokens.colorPrimary,
                    ),
                  ),
                  if (u.expireAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${s.expireAt}: ${_formatDate(u.expireAt!)}',
                      style: TextStyle(
                        color: tokens.colorMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 订单和工单
            _InfoCard(
              icon: Icons.receipt_long_outlined,
              title: s.orders,
              tokens: tokens,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  s.orderCenterTitle,
                  style: TextStyle(color: tokens.colorOnBackground),
                ),
                trailing: Icon(Icons.chevron_right, color: tokens.colorMuted),
                onTap: () => context.push('/orders'),
              ),
            ),
            const SizedBox(height: 16),

            _InfoCard(
              icon: Icons.support_agent_outlined,
              title: s.tickets,
              tokens: tokens,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  s.ticketListTitle,
                  style: TextStyle(color: tokens.colorOnBackground),
                ),
                trailing: Icon(Icons.chevron_right, color: tokens.colorMuted),
                onTap: () => context.push('/tickets'),
              ),
            ),
            const SizedBox(height: 16),

            // 邀请
            _InfoCard(
              icon: Icons.card_giftcard_outlined,
              title: s.invite,
              tokens: tokens,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  s.inviteTitle,
                  style: TextStyle(color: tokens.colorOnBackground),
                ),
                trailing: Icon(Icons.chevron_right, color: tokens.colorMuted),
                onTap: () => context.push('/invite'),
              ),
            ),
            const SizedBox(height: 32),

            // 登出按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(s.logout),
                      content: Text(s.logoutConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(s.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(s.confirm),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await controller.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.colorError,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  ),
                ),
                child: Text(s.logout),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.tokens,
    required this.child,
  });

  final IconData icon;
  final String title;
  final ThemeTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tokens.colorPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: tokens.colorMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
