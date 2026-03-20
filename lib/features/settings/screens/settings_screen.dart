import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../locale_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
