import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../infrastructure/storage/preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../locale_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _autoConnect;

  @override
  void initState() {
    super.initState();
    _autoConnect = AppPreferences.instance.autoConnect;
  }

  static const _locales = [
    _LocaleOption(code: '', label: '跟随系统'),
    _LocaleOption(code: 'en', country: null, label: 'English'),
    _LocaleOption(code: 'zh', country: 'CN', label: '简体中文'),
  ];

  String _currentCode(LocaleNotifier notifier) {
    if (notifier.locale == null) return '';
    return notifier.locale!.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final localeNotifier = context.watch<LocaleNotifier>();
    final currentCode = _currentCode(localeNotifier);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        children: [
          _SectionHeader(label: s.settingsConnection),
          SwitchListTile(
            title: Text(s.settingsAutoConnect),
            subtitle: Text(s.settingsAutoConnectDesc),
            value: _autoConnect,
            onChanged: (v) {
              setState(() => _autoConnect = v);
              AppPreferences.instance.setAutoConnect(v);
            },
          ),
          const Divider(),
          _SectionHeader(label: s.language),
          ..._locales.map((loc) {
            final selected = currentCode == loc.code;
            return ListTile(
              title: Text(loc.label),
              leading: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              selected: selected,
              onTap: () => _setLocale(context, localeNotifier, loc),
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
      ),
    );
  }

  Future<void> _setLocale(
      BuildContext context, LocaleNotifier notifier, _LocaleOption opt) async {
    if (opt.code.isEmpty) {
      await notifier.useSystemLocale();
    } else {
      await notifier.setLocale(
          opt.country != null ? Locale(opt.code, opt.country) : Locale(opt.code));
    }
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
