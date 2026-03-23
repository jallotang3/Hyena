import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/models/traffic_stats.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 移动端首页（Material Design）
///
/// 特点：
/// - 垂直布局
/// - 底部导航栏
/// - 适合小屏幕
class MobileHomePage extends StatefulWidget {
  final HomeController controller;

  const MobileHomePage({required this.controller, super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  int _bottomIndex = 0;

  String _formatBytes(double bytes) {
    if (bytes < 1024) {
      return '${bytes.toStringAsFixed(0)} B/s';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatTotal(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final ctrl = widget.controller;

    final s = S.of(context)!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? s.homeGoodMorning
        : hour < 18
            ? s.homeGoodAfternoon
            : s.homeGoodEvening;

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting,
                          style: TextStyle(
                              color: tokens.colorMuted,
                              fontSize: 11,
                              letterSpacing: 1.5)),
                      Text(
                        ctrl.userEmail?.split('@').first.toUpperCase() ??
                            s.homeDefaultUser,
                        style: TextStyle(
                            color: tokens.colorOnBackground,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: tokens.colorMuted, size: 22),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Connection button
                    StreamBuilder<EngineState>(
                      stream: ctrl.stateStream,
                      initialData: ctrl.connectionState,
                      builder: (context, snap) {
                        final state = snap.data ?? EngineState.idle;
                        return _ConnectButton(
                            state: state, ctrl: ctrl, tokens: tokens);
                      },
                    ),
                    const SizedBox(height: 28),

                    // Traffic stats
                    StreamBuilder<TrafficStats>(
                      stream: ctrl.trafficStream,
                      initialData: TrafficStats.zero,
                      builder: (context, snap) {
                        final stats = snap.data ?? TrafficStats.zero;
                        return Row(
                          children: [
                            _StatCard(
                              label: s.homeUpload,
                              value: _formatBytes(stats.uploadSpeed),
                              total: _formatTotal(stats.uploadBytes),
                              icon: Icons.arrow_upward_rounded,
                              color: tokens.colorPrimary,
                              tokens: tokens,
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              label: s.homeDownload,
                              value: _formatBytes(stats.downloadSpeed),
                              total: _formatTotal(stats.downloadBytes),
                              icon: Icons.arrow_downward_rounded,
                              color: tokens.colorSuccess,
                              tokens: tokens,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Connection duration
                    if (ctrl.connectedSince != null)
                      _ConnectionDurationChip(ctrl: ctrl, tokens: tokens),
                    if (ctrl.connectedSince != null) const SizedBox(height: 12),

                    // Current node card
                    _NodeCard(ctrl: ctrl, tokens: tokens),
                    const SizedBox(height: 16),

                    // Routing mode
                    _RoutingModeCard(ctrl: ctrl, tokens: tokens),
                  ],
                ),
              ),
            ),

            // Bottom nav
            _BottomNav(
              index: _bottomIndex,
              tokens: tokens,
              onTap: (i) {
                setState(() => _bottomIndex = i);
                switch (i) {
                  case 0:
                    break;
                  case 1:
                    context.push('/nodes');
                  case 2:
                    context.push('/settings');
                  case 3:
                    context.push('/profile');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton(
      {required this.state, required this.ctrl, required this.tokens});
  final EngineState state;
  final HomeController ctrl;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isConnected = state == EngineState.connected;
    final isBusy =
        state == EngineState.connecting || state == EngineState.disconnecting;

    final s = S.of(context)!;
    final statusLabel = switch (state) {
      EngineState.connected => s.homeConnected,
      EngineState.connecting => s.homeConnecting,
      EngineState.disconnecting => s.homeDisconnecting,
      EngineState.error => s.homeErrorState,
      _ => s.homeDisconnected,
    };

    return GestureDetector(
      onTap: isBusy
          ? null
          : () => isConnected ? ctrl.disconnect() : ctrl.connect(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: tokens.colorSurface,
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: tokens.colorMuted.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected
                    ? tokens.colorSuccess.withValues(alpha: 0.1)
                    : tokens.colorMuted.withValues(alpha: 0.1),
              ),
              child: isBusy
                  ? Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: tokens.colorPrimary,
                        ),
                      ),
                    )
                  : Icon(
                      isConnected ? Icons.power_rounded : Icons.power_off_rounded,
                      size: 40,
                      color: isConnected
                          ? tokens.colorSuccess
                          : tokens.colorMuted,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              statusLabel,
              style: TextStyle(
                color: tokens.colorOnBackground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.total,
    required this.icon,
    required this.color,
    required this.tokens,
  });

  final String label;
  final String value;
  final String total;
  final IconData icon;
  final Color color;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: tokens.colorMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: tokens.colorOnBackground,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              total,
              style: TextStyle(
                color: tokens.colorMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionDurationChip extends StatelessWidget {
  const _ConnectionDurationChip({required this.ctrl, required this.tokens});
  final HomeController ctrl;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final duration = DateTime.now().difference(ctrl.connectedSince!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.colorSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(tokens.radiusSmall),
      ),
      child: Text(
        '${hours}h ${minutes}m ${seconds}s',
        style: TextStyle(
          color: tokens.colorSuccess,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({required this.ctrl, required this.tokens});
  final HomeController ctrl;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final node = ctrl.currentNode;

    return GestureDetector(
      onTap: () => context.push('/nodes'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.colorSurface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(Icons.dns_outlined, color: tokens.colorPrimary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.homeCurrentNode,
                    style: TextStyle(
                      color: tokens.colorMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    node?.name ?? s.noNodes,
                    style: TextStyle(
                      color: tokens.colorOnBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: tokens.colorMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _RoutingModeCard extends StatelessWidget {
  const _RoutingModeCard({required this.ctrl, required this.tokens});
  final HomeController ctrl;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.homeRoutingMode,
            style: TextStyle(
              color: tokens.colorMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoutingModeChip(
                label: s.homeRoutingGlobal,
                isSelected: ctrl.currentMode == RoutingMode.global,
                onTap: () => ctrl.switchRoutingMode(RoutingMode.global),
                tokens: tokens,
              ),
              const SizedBox(width: 8),
              _RoutingModeChip(
                label: s.homeRoutingRule,
                isSelected: ctrl.currentMode == RoutingMode.rule,
                onTap: () => ctrl.switchRoutingMode(RoutingMode.rule),
                tokens: tokens,
              ),
              const SizedBox(width: 8),
              _RoutingModeChip(
                label: s.homeRoutingDirect,
                isSelected: ctrl.currentMode == RoutingMode.direct,
                onTap: () => ctrl.switchRoutingMode(RoutingMode.direct),
                tokens: tokens,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutingModeChip extends StatelessWidget {
  const _RoutingModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.tokens,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.colorPrimary
              : tokens.colorBackground,
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? tokens.colorOnPrimary
                : tokens.colorOnBackground,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.tokens,
    required this.onTap,
  });

  final int index;
  final ThemeTokens tokens;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        boxShadow: [
          BoxShadow(
            color: tokens.colorMuted.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: s.navHome,
              isActive: index == 0,
              onTap: () => onTap(0),
              tokens: tokens,
            ),
            _BottomNavItem(
              icon: Icons.dns_outlined,
              activeIcon: Icons.dns_rounded,
              label: s.navNodes,
              isActive: index == 1,
              onTap: () => onTap(1),
              tokens: tokens,
            ),
            _BottomNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: s.navSettings,
              isActive: index == 2,
              onTap: () => onTap(2),
              tokens: tokens,
            ),
            _BottomNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person_rounded,
              label: s.navMy,
              isActive: index == 3,
              onTap: () => onTap(3),
              tokens: tokens,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.tokens,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? tokens.colorPrimary : tokens.colorMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? tokens.colorPrimary : tokens.colorMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
