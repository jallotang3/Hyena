import 'package:flutter/material.dart';

/// 皮肤设计令牌 — 颜色/排版/间距/圆角/按钮样式的最小 UI 变量单元
/// 品牌皮肤仅需 override 这些令牌即可实现整体风格切换
@immutable
class ThemeTokens {
  const ThemeTokens({
    // ── 颜色 ──
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
    // ── 圆角 ──
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    // ── 排版 ──
    this.fontFamily,
    this.fontSizeCaption = 11.0,
    this.fontSizeBody = 14.0,
    this.fontSizeTitle = 18.0,
    this.fontSizeHeadline = 24.0,
    this.fontWeightNormal = FontWeight.w400,
    this.fontWeightBold = FontWeight.w700,
    // ── 间距 ──
    this.spacingXs = 4.0,
    this.spacingSm = 8.0,
    this.spacingMd = 16.0,
    this.spacingLg = 24.0,
    this.spacingXl = 32.0,
    // ── 按钮 ──
    this.buttonHeight = 48.0,
    this.buttonBorderRadius,
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.connectButtonSize = 180.0,
    this.connectButtonBorderWidth = 2.5,
  });

  // ── 颜色 ──
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

  // ── 圆角 ──
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;

  // ── 排版 ──
  final String? fontFamily;
  final double fontSizeCaption;
  final double fontSizeBody;
  final double fontSizeTitle;
  final double fontSizeHeadline;
  final FontWeight fontWeightNormal;
  final FontWeight fontWeightBold;

  // ── 间距 ──
  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double spacingXl;

  // ── 按钮 ──
  final double buttonHeight;
  final double? buttonBorderRadius;
  final EdgeInsets buttonPadding;
  final double connectButtonSize;
  final double connectButtonBorderWidth;

  double get resolvedButtonRadius => buttonBorderRadius ?? radiusMedium;

  ThemeTokens copyWith({
    Color? colorPrimary,
    Color? colorBackground,
    Color? colorSurface,
    Color? colorSurfaceVariant,
    Color? colorOnBackground,
    Color? colorOnSurface,
    Color? colorOnPrimary,
    Color? colorMuted,
    Color? colorError,
    Color? colorSuccess,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    String? fontFamily,
    double? fontSizeCaption,
    double? fontSizeBody,
    double? fontSizeTitle,
    double? fontSizeHeadline,
    FontWeight? fontWeightNormal,
    FontWeight? fontWeightBold,
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? buttonHeight,
    double? buttonBorderRadius,
    EdgeInsets? buttonPadding,
    double? connectButtonSize,
    double? connectButtonBorderWidth,
  }) {
    return ThemeTokens(
      colorPrimary: colorPrimary ?? this.colorPrimary,
      colorBackground: colorBackground ?? this.colorBackground,
      colorSurface: colorSurface ?? this.colorSurface,
      colorSurfaceVariant: colorSurfaceVariant ?? this.colorSurfaceVariant,
      colorOnBackground: colorOnBackground ?? this.colorOnBackground,
      colorOnSurface: colorOnSurface ?? this.colorOnSurface,
      colorOnPrimary: colorOnPrimary ?? this.colorOnPrimary,
      colorMuted: colorMuted ?? this.colorMuted,
      colorError: colorError ?? this.colorError,
      colorSuccess: colorSuccess ?? this.colorSuccess,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSizeCaption: fontSizeCaption ?? this.fontSizeCaption,
      fontSizeBody: fontSizeBody ?? this.fontSizeBody,
      fontSizeTitle: fontSizeTitle ?? this.fontSizeTitle,
      fontSizeHeadline: fontSizeHeadline ?? this.fontSizeHeadline,
      fontWeightNormal: fontWeightNormal ?? this.fontWeightNormal,
      fontWeightBold: fontWeightBold ?? this.fontWeightBold,
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      connectButtonSize: connectButtonSize ?? this.connectButtonSize,
      connectButtonBorderWidth: connectButtonBorderWidth ?? this.connectButtonBorderWidth,
    );
  }
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
          minimumSize: Size.fromHeight(tokens.buttonHeight),
          padding: tokens.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.resolvedButtonRadius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(tokens.buttonHeight),
          padding: tokens.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.resolvedButtonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(tokens.buttonHeight),
          padding: tokens.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.resolvedButtonRadius),
          ),
          side: BorderSide(color: tokens.colorPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: tokens.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.resolvedButtonRadius),
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spacingMd,
          vertical: tokens.spacingSm + tokens.spacingXs,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.colorBackground,
        elevation: 0,
        foregroundColor: tokens.colorOnBackground,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: tokens.spacingMd),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.colorSurfaceVariant,
        thickness: 0.5,
      ),
    );
  }

  @override
  bool updateShouldNotify(ThemeTokenProvider oldWidget) =>
      tokens != oldWidget.tokens;
}
