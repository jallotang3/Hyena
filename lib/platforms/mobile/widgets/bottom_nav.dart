import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 当前激活的底部导航 tab
enum BottomNavTab { home, nodes, store, profile }

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({
    required this.activeTab,
    required this.tokens,
    super.key,
  });

  final BottomNavTab activeTab;
  final ThemeTokens tokens;

  void _onTap(BuildContext context, int i) {
    if (i == activeTab.index) return;
    switch (i) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/nodes');
      case 2:
        context.go('/store');
      case 3:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final index = activeTab.index;

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
            _Item(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: s.navHome,
              isActive: index == 0,
              onTap: () => _onTap(context, 0),
              tokens: tokens,
            ),
            _Item(
              icon: Icons.dns_outlined,
              activeIcon: Icons.dns_rounded,
              label: s.navNodes,
              isActive: index == 1,
              onTap: () => _onTap(context, 1),
              tokens: tokens,
            ),
            _Item(
              icon: Icons.shopping_bag_outlined,
              activeIcon: Icons.shopping_bag_rounded,
              label: s.navStore,
              isActive: index == 2,
              onTap: () => _onTap(context, 2),
              tokens: tokens,
            ),
            _Item(
              icon: Icons.person_outline,
              activeIcon: Icons.person_rounded,
              label: s.navMy,
              isActive: index == 3,
              onTap: () => _onTap(context, 3),
              tokens: tokens,
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
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
      child: Padding(
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
