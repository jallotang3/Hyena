import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 移动端设置页（Material Design）
class MobileSettingsPage extends StatelessWidget {
  final SettingsController controller;

  const MobileSettingsPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final s = S.of(context)!;

    final locales = [
      _LocaleOption(code: '', label: s.langFollowSystem),
      _LocaleOption(code: 'en', country: null, label: s.langEn),
      _LocaleOption(code: 'zh', country: 'CN', label: s.langZhCN),
    ];

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      appBar: AppBar(
        backgroundColor: tokens.colorBackground,
        title: Text(s.settings),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final currentCode = controller.currentLocale?.languageCode ?? '';

          return ListView(
            children: [
              // 连接设置
              _SectionHeader(label: s.settingsConnection, tokens: tokens),
              _SettingCard(
                tokens: tokens,
                child: SwitchListTile(
                  title: Text(
                    s.settingsAutoConnect,
                    style: TextStyle(color: tokens.colorOnBackground),
                  ),
                  subtitle: Text(
                    s.settingsAutoConnectDesc,
                    style: TextStyle(color: tokens.colorMuted, fontSize: 12),
                  ),
                  value: controller.autoConnect,
                  activeTrackColor: tokens.colorPrimary.withValues(alpha: 0.5),
                  onChanged: (v) => controller.setAutoConnect(v),
                ),
              ),

              // 语言设置
              _SectionHeader(label: s.language, tokens: tokens),
              _SettingCard(
                tokens: tokens,
                child: Column(
                  children: locales.map((loc) {
                    final selected = currentCode == loc.code;
                    return ListTile(
                      title: Text(
                        loc.label,
                        style: TextStyle(
                          color: selected
                              ? tokens.colorPrimary
                              : tokens.colorOnBackground,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected ? tokens.colorPrimary : tokens.colorMuted,
                      ),
                      onTap: () {
                        if (loc.code.isEmpty) {
                          controller.setLocale(null);
                        } else {
                          controller.setLocale(loc.country != null
                              ? Locale(loc.code, loc.country)
                              : Locale(loc.code));
                        }
                      },
                    );
                  }).toList(),
                ),
              ),

              // 工具
              _SectionHeader(label: s.settingsTools, tokens: tokens),
              _SettingCard(
                tokens: tokens,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.bar_chart, color: tokens.colorPrimary),
                      title: Text(
                        s.trafficUsage,
                        style: TextStyle(color: tokens.colorOnBackground),
                      ),
                      trailing: Icon(Icons.chevron_right, color: tokens.colorMuted),
                      onTap: () => context.push('/traffic-chart'),
                    ),
                    Divider(
                      height: 1,
                      color: tokens.colorMuted.withValues(alpha: 0.1),
                    ),
                    ListTile(
                      leading: Icon(Icons.bug_report_outlined,
                          color: tokens.colorPrimary),
                      title: Text(
                        s.diagnosticsTitle,
                        style: TextStyle(color: tokens.colorOnBackground),
                      ),
                      trailing: Icon(Icons.chevron_right, color: tokens.colorMuted),
                      onTap: () => context.push('/diagnostics'),
                    ),
                  ],
                ),
              ),

              // 关于
              _SectionHeader(label: s.about, tokens: tokens),
              _SettingCard(
                tokens: tokens,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info_outline, color: tokens.colorPrimary),
                      title: Text(
                        s.appVersion,
                        style: TextStyle(color: tokens.colorOnBackground),
                      ),
                      trailing: Text(
                        '1.0.0',
                        style: TextStyle(color: tokens.colorMuted),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: tokens.colorMuted.withValues(alpha: 0.1),
                    ),
                    ListTile(
                      leading: Icon(Icons.palette_outlined,
                          color: tokens.colorPrimary),
                      title: Text(
                        s.settingsSkin,
                        style: TextStyle(color: tokens.colorOnBackground),
                      ),
                      trailing: Text(
                        controller.currentSkinId,
                        style: TextStyle(color: tokens.colorMuted),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _LocaleOption {
  const _LocaleOption({required this.code, this.country, required this.label});
  final String code;
  final String? country;
  final String label;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.tokens});
  final String label;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: tokens.colorMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.tokens, required this.child});
  final ThemeTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: child,
    );
  }
}
