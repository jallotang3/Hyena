import 'package:flutter/material.dart';
import '../theme_token_provider.dart';

/// Default Skin — "Terminal Minimal" 深色主题
/// 主色调：Cyan (#22D3EE)，背景：深海军蓝 (#0A0F1C)
const kDefaultThemeTokens = ThemeTokens(
  colorPrimary: Color(0xFF22D3EE),
  colorBackground: Color(0xFF0A0F1C),
  colorSurface: Color(0xFF111827),
  colorSurfaceVariant: Color(0xFF1E293B),
  colorOnBackground: Color(0xFFF8FAFC),
  colorOnSurface: Color(0xFFE2E8F0),
  colorOnPrimary: Color(0xFF0A0F1C),
  colorMuted: Color(0xFF475569),
  colorError: Color(0xFFF87171),
  colorSuccess: Color(0xFF34D399),
  radiusSmall: 8.0,
  radiusMedium: 12.0,
  radiusLarge: 20.0,
);
