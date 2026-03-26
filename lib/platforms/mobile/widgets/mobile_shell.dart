import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 移动端主 Shell — 持久化底部导航栏
/// 使用 StatefulShellRoute，切换 tab 时页面状态保留
class MobileShell extends StatelessWidget {
  const MobileShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final s = S.of(context)!;

    final items = [
      (icon: Icons.home_outlined,      activeIcon: Icons.home_rounded,         label: s.navHome),
      (icon: Icons.dns_outlined,        activeIcon: Icons.dns_rounded,           label: s.navNodes),
      (icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded, label: s.navStore),
      (icon: Icons.person_outline,      activeIcon: Icons.person_rounded,        label: s.navMy),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
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
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == navigationShell.currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => _onTap(i),
                  // 水波纹颜色
                  splashColor: tokens.colorPrimary.withValues(alpha: 0.12),
                  highlightColor: tokens.colorPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive ? tokens.colorPrimary : tokens.colorMuted,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isActive ? tokens.colorPrimary : tokens.colorMuted,
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
