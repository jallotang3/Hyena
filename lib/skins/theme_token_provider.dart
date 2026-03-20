import 'package:flutter/material.dart';

/// 皮肤设计令牌 — 颜色/字体/间距/圆角的最小 UI 变量单元
@immutable
class ThemeTokens {
  const ThemeTokens({
    required this.colorPrimary,
    required this.colorBackground,
    required this.colorSurface,
    required this.colorSurfaceVariant,
    required this.colorOnBackground,
    required this.colorOnSurface,
    required this.colorOnPrimary,
    required this.colorMuted,
    required this.colorError,
    required this.colorSuccess,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    this.fontFamily,
  });

  final Color colorPrimary;
  final Color colorBackground;
  final Color colorSurface;
  final Color colorSurfaceVariant;
  final Color colorOnBackground;
  final Color colorOnSurface;
  final Color colorOnPrimary;
  final Color colorMuted;
  final Color colorError;
  final Color colorSuccess;
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;
  final String? fontFamily;
}

/// ThemeTokenProvider — 将 ThemeTokens 注入 Flutter MaterialTheme
class ThemeTokenProvider extends InheritedWidget {
  const ThemeTokenProvider({
    super.key,
    required this.tokens,
    required super.child,
  });

  final ThemeTokens tokens;

  static ThemeTokenProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeTokenProvider>()!;
  }

  static ThemeTokens tokensOf(BuildContext context) => of(context).tokens;

  ThemeData toMaterialTheme() {
    final cs = ColorScheme.dark(
      primary: tokens.colorPrimary,
      surface: tokens.colorSurface,
      surfaceContainerHighest: tokens.colorSurfaceVariant,
      onPrimary: tokens.colorOnPrimary,
      onSurface: tokens.colorOnSurface,
      error: tokens.colorError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: tokens.colorBackground,
      fontFamily: tokens.fontFamily,
      cardColor: tokens.colorSurface,
      cardTheme: CardThemeData(
        color: tokens.colorSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        margin: EdgeInsets.zero,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.colorPrimary,
          foregroundColor: tokens.colorOnPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.colorSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.colorBackground,
        elevation: 0,
        foregroundColor: tokens.colorOnBackground,
      ),
    );
  }

  @override
  bool updateShouldNotify(ThemeTokenProvider oldWidget) =>
      tokens != oldWidget.tokens;
}
