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
  const _ProfileContent({required this.controller, required this.tokens});

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

  String _formatBalance(int cents) =>
      '¥${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final u = controller.user;

    return RefreshIndicator(
      onRefresh: () async => controller.fetchUser(),
      color: tokens.colorPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── 顶部用户信息卡片 ──
          _UserInfoCard(user: u, tokens: tokens, formatBytes: _formatBytes, formatDate: _formatDate, formatBalance: _formatBalance),
          const SizedBox(height: 12),

          if (u != null) ...[
            // ── 菜单列表卡片 ──
            Container(
              decoration: BoxDecoration(
                color: tokens.colorSurface,
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.receipt_long_outlined,
                    label: s.orders,
                    tokens: tokens,
                    onTap: () => context.push('/orders'),
                  ),
                  _Divider(tokens: tokens),
                  _MenuItem(
                    icon: Icons.support_agent_outlined,
                    label: s.tickets,
                    tokens: tokens,
                    onTap: () => context.push('/tickets'),
                  ),
                  _Divider(tokens: tokens),
                  _MenuItem(
                    icon: Icons.card_giftcard_outlined,
                    label: s.invite,
                    tokens: tokens,
                    onTap: () => context.push('/invite'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 登出按钮 ──
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
                    if (context.mounted) context.go('/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.colorError,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({
    required this.user,
    required this.tokens,
    required this.formatBytes,
    required this.formatDate,
    required this.formatBalance,
  });

  final PanelUser? user;
  final ThemeTokens tokens;
  final String Function(int) formatBytes;
  final String Function(DateTime) formatDate;
  final String Function(int) formatBalance;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final u = user;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像 + 邮箱 + 套餐标签
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.colorPrimary.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Text(
                    u?.email.isNotEmpty == true ? u!.email[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: tokens.colorPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u?.email ?? '–',
                      style: TextStyle(
                        color: tokens.colorOnBackground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (u != null && u.planName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tokens.colorPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          u.planName,
                          style: TextStyle(
                            color: tokens.colorPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Text(
                        '–',
                        style: TextStyle(color: tokens.colorMuted, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (u != null) ...[
            const SizedBox(height: 14),
            Divider(color: tokens.colorMuted.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 12),

            // 余额 + 到期日 两列
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: s.balance,
                    value: formatBalance(u.balance),
                    tokens: tokens,
                  ),
                ),
                Container(width: 1, height: 32, color: tokens.colorMuted.withValues(alpha: 0.15)),
                Expanded(
                  child: _StatItem(
                    label: s.expireAt,
                    value: u.expireAt != null ? formatDate(u.expireAt!) : '–',
                    tokens: tokens,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: tokens.colorMuted.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 12),

            // 流量使用
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.trafficUsage,
                  style: TextStyle(color: tokens.colorMuted, fontSize: 12),
                ),
                Text(
                  u.trafficTotal > 0
                      ? '${formatBytes(u.trafficUsed)} / ${formatBytes(u.trafficTotal)}'
                      : '${formatBytes(u.trafficUsed)} / ∞',
                  style: TextStyle(
                    color: tokens.colorOnBackground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: u.trafficTotal > 0 ? u.trafficUsedPercent.clamp(0.0, 1.0) : 0,
                minHeight: 6,
                backgroundColor: tokens.colorMuted.withValues(alpha: 0.15),
                color: tokens.colorPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.tokens});

  final String label;
  final String value;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: tokens.colorMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: tokens.colorOnBackground,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.tokens,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final ThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: tokens.colorPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: tokens.colorOnBackground, fontSize: 14),
              ),
            ),
            Icon(Icons.chevron_right, color: tokens.colorMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.tokens});
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Divider(color: tokens.colorMuted.withValues(alpha: 0.15), height: 1),
    );
  }
}
