import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/settings_controller.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final locales = [
      _LocaleOption(code: '', label: s.langFollowSystem),
      _LocaleOption(code: 'en', country: null, label: s.langEn),
      _LocaleOption(code: 'zh', country: 'CN', label: s.langZhCN),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: Consumer<SettingsController>(
        builder: (_, ctrl, __) {
          final currentCode =
              ctrl.currentLocale?.languageCode ?? '';
          return ListView(
            children: [
              _SectionHeader(label: s.settingsConnection),
              SwitchListTile(
                title: Text(s.settingsAutoConnect),
                subtitle: Text(s.settingsAutoConnectDesc),
                value: ctrl.autoConnect,
                onChanged: (v) => ctrl.setAutoConnect(v),
              ),
              const Divider(),
              _SectionHeader(label: s.language),
              ...locales.map((loc) {
                final selected = currentCode == loc.code;
                return ListTile(
                  title: Text(loc.label),
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                  ),
                  selected: selected,
                  onTap: () {
                    if (loc.code.isEmpty) {
                      ctrl.setLocale(null);
                    } else {
                      ctrl.setLocale(loc.country != null
                          ? Locale(loc.code, loc.country)
                          : Locale(loc.code));
                    }
                  },
                );
              }),
              const Divider(),
              _SectionHeader(label: s.settingsTools),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: Text(s.trafficUsage),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/traffic-chart'),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(s.diagnosticsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/diagnostics'),
              ),
              const Divider(),
              _SectionHeader(label: s.about),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(s.appVersion),
                trailing: const Text('1.0.0'),
              ),
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
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1,
            ),
      ),
    );
  }
}
