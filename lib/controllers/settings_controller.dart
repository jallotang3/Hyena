import 'dart:ui';
import 'package:flutter/foundation.dart';

import '../infrastructure/storage/preferences.dart';
import '../features/settings/locale_notifier.dart';
import '../skins/skin_manager.dart';

/// SettingsController — 设置页的固定 API 边界
class SettingsController extends ChangeNotifier {
  SettingsController({
    required LocaleNotifier localeNotifier,
  }) : _localeNotifier = localeNotifier {
    _localeNotifier.addListener(_onLocaleChanged);
  }

  final LocaleNotifier _localeNotifier;

  void _onLocaleChanged() => notifyListeners();

  // ── 状态属性 ──
  bool get autoConnect => AppPreferences.instance.autoConnect;
  Locale? get currentLocale => _localeNotifier.locale;
  String get currentSkinId => SkinManager.instance.activeSkinId;

  // ── 操作方法 ──
  Future<void> setAutoConnect(bool value) async {
    await AppPreferences.instance.setAutoConnect(value);
    notifyListeners();
  }

  void setLocale(Locale? locale) {
    if (locale == null) {
      _localeNotifier.useSystemLocale();
    } else {
      _localeNotifier.setLocale(locale);
    }
  }

  Future<void> setSkin(String skinId) async {
    await SkinManager.instance.load(skinId);
    notifyListeners();
  }

  @override
  void dispose() {
    _localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }
}
