import 'package:flutter/material.dart';
import '../../infrastructure/storage/preferences.dart';

/// 管理运行时语言切换
class LocaleNotifier extends ChangeNotifier {
  LocaleNotifier() {
    final saved = AppPreferences.instance.locale;
    if (saved != null && saved.isNotEmpty) {
      final parts = saved.split('_');
      _locale = parts.length == 2
          ? Locale(parts[0], parts[1])
          : Locale(parts[0]);
    }
  }

  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final tag = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    await AppPreferences.instance.setLocale(tag);
    notifyListeners();
  }

  Future<void> useSystemLocale() async {
    _locale = null;
    await AppPreferences.instance.setLocale('');
    notifyListeners();
  }
}
