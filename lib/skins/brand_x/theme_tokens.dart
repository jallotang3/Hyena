import 'package:flutter/material.dart';
import '../theme_token_provider.dart';

/// Brand X Skin — "Warm Journey" 温暖出行主题
/// 主色调：暖橙 (#F97316)，背景：奶油白 (#FFFBF5)
/// 适合面向大众出行场景的品牌定制
const kBrandXThemeTokens = ThemeTokens(
  // ── 颜色 ─────────────────────────────────────────────────────────────────
  colorPrimary: Color(0xFFF97316),         // 暖橙
  colorBackground: Color(0xFFFFFBF5),      // 奶油白
  colorSurface: Color(0xFFFFFFFF),         // 纯白卡片
  colorSurfaceVariant: Color(0xFFFFF3E0),  // 浅橙背景
  colorOnBackground: Color(0xFF1C0F00),    // 深棕文字
  colorOnSurface: Color(0xFF3D2000),       // 棕色正文
  colorOnPrimary: Color(0xFFFFFFFF),       // 橙色上的白字
  colorMuted: Color(0xFFB0895A),           // 柔和棕（辅助文字）
  colorError: Color(0xFFDC2626),           // 红色错误
  colorSuccess: Color(0xFF16A34A),         // 绿色成功

  // ── 圆角 ─────────────────────────────────────────────────────────────────
  radiusSmall: 10.0,    // 比 default 稍大，更圆润友好
  radiusMedium: 16.0,
  radiusLarge: 28.0,    // 主按钮胶囊形
);
